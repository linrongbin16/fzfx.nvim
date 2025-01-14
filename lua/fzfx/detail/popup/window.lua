local log = require("fzfx.lib.log")
local version = require("fzfx.commons.version")

local popup_helpers = require("fzfx.detail.popup.popup_helpers")
local window_helpers = require("fzfx.detail.popup.window_helpers")

local M = {}

--- @param win_opts fzfx.WindowOpts
--- @param relative_winnr integer
--- @param relative_win_first_line integer
--- @return fzfx.NvimFloatWinOpts
M._make_cursor_opts = function(win_opts, relative_winnr, relative_win_first_line)
  win_opts = vim.deepcopy(win_opts)

  assert(win_opts.relative == "cursor")
  -- win_opts.relative = win_opts.relative or "win"

  local layout = popup_helpers.make_cursor_layout(relative_winnr, relative_win_first_line, win_opts)
  log.debug("|_make_cursor_opts| layout:" .. vim.inspect(layout))

  local result = {
    anchor = "NW",
    relative = "win", -- Even for cursor related popup, we still create popup based on 'win'.
    width = layout.width,
    height = layout.height,
    row = layout.start_row,
    col = layout.start_col,
    style = window_helpers.FLOAT_WIN_STYLE,
    border = window_helpers.FLOAT_WIN_BORDER,
    zindex = window_helpers.FLOAT_WIN_ZINDEX,
  }

  -- if win_opts.relative == "win" then
  result.win = relative_winnr
  -- end

  log.debug("|_make_cursor_opts| result:" .. vim.inspect(result))
  return result
end

--- @param win_opts fzfx.WindowOpts
--- @param relative_winnr integer
--- @param relative_win_first_line integer
--- @return fzfx.NvimFloatWinOpts
M._make_center_opts = function(win_opts, relative_winnr, relative_win_first_line)
  win_opts = vim.deepcopy(win_opts)

  win_opts.relative = win_opts.relative or "editor"
  assert(win_opts.relative == "editor" or win_opts.relative == "win")

  local layout = popup_helpers.make_center_layout(relative_winnr, relative_win_first_line, win_opts)
  -- log.debug("|_make_center_opts| layout:%s" .. vim.inspect(layout))

  local result = {
    anchor = "NW",
    relative = win_opts.relative,
    width = layout.width,
    height = layout.height,
    row = layout.start_row,
    col = layout.start_col,
    style = window_helpers.FLOAT_WIN_STYLE,
    border = window_helpers.FLOAT_WIN_BORDER,
    zindex = window_helpers.FLOAT_WIN_ZINDEX,
  }

  if win_opts.relative == "win" then
    result.win = relative_winnr
  end

  return result
end

--- @alias fzfx.NvimFloatWinOpts {anchor:"NW"?,relative:"editor"|"win"|"cursor"|nil,width:integer?,height:integer?,row:integer?,col:integer?,style:"minimal"?,border:"none"|"single"|"double"|"rounded"|"solid"|"shadow"|nil,zindex:integer?,focusable:boolean?}
--- @param win_opts fzfx.WindowOpts
--- @param relative_winnr integer
--- @param relative_win_first_line integer
--- @return fzfx.NvimFloatWinOpts
M.make_opts = function(win_opts, relative_winnr, relative_win_first_line)
  win_opts = vim.deepcopy(win_opts)

  win_opts.relative = win_opts.relative or "editor"

  log.ensure(
    win_opts.relative == "cursor" or win_opts.relative == "editor" or win_opts.relative == "win",
    string.format("popup window relative (%s) must be editor/win/cursor", vim.inspect(win_opts))
  )
  return win_opts.relative == "cursor"
      and M._make_cursor_opts(win_opts, relative_winnr, relative_win_first_line)
    or M._make_center_opts(win_opts, relative_winnr, relative_win_first_line)
end

-- PopupWindow {

--- @class fzfx.PopupWindow
--- @field saved_win_ctx fzfx.WindowContext?
--- @field bufnr integer?
--- @field winnr integer?
--- @field _saved_current_winnr integer
--- @field _saved_current_win_first_line integer
--- @field _saved_win_opts fzfx.WindowOpts
--- @field _resizing boolean
local PopupWindow = {}

--- @param win_opts fzfx.WindowOpts
--- @return fzfx.PopupWindow
function PopupWindow:new(win_opts)
  local current_winnr = vim.api.nvim_get_current_win()
  local current_win_first_line = vim.fn.line("w0")

  -- save current window context
  local saved_win_ctx = window_helpers.WindowContext:save()

  --- @type integer
  local bufnr = vim.api.nvim_create_buf(false, true)
  -- setlocal bufhidden=wipe nobuflisted
  -- setft=fzf
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
  vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })
  vim.api.nvim_set_option_value("filetype", "fzf", { buf = bufnr })

  local nvim_float_win_opts = M.make_opts(win_opts, current_winnr, current_win_first_line)

  local winnr = vim.api.nvim_open_win(bufnr, true, nvim_float_win_opts)
  --- setlocal nospell nonumber
  --- set winhighlight='Pmenu:,Normal:Normal'
  --- set colorcolumn=''
  vim.api.nvim_set_option_value("spell", false, { win = winnr })
  vim.api.nvim_set_option_value("number", false, { win = winnr })
  vim.api.nvim_set_option_value("winhighlight", "Pmenu:,Normal:Normal", { win = winnr })
  vim.api.nvim_set_option_value("colorcolumn", "", { win = winnr })
  vim.api.nvim_set_option_value("wrap", false, { win = winnr })

  local o = {
    saved_win_ctx = saved_win_ctx,
    bufnr = bufnr,
    winnr = winnr,
    _saved_current_winnr = current_winnr,
    _saved_current_win_first_line = current_win_first_line,
    _saved_win_opts = win_opts,
    _resizing = false,
  }
  setmetatable(o, self)
  self.__index = self

  assert(M._PopupWindowsManagerInstance ~= nil)
  M._PopupWindowsManagerInstance:add(o)

  return o
end

function PopupWindow:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

  M._PopupWindowsManagerInstance:remove(self)

  if vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_close(self.winnr, true)
    self.winnr = nil
  end

  self.bufnr = nil
  self.saved_win_ctx:restore()
end

function PopupWindow:is_valid()
  if vim.in_fast_event() then
    return type(self.winnr) == "number" and type(self.bufnr) == "number"
  else
    return type(self.winnr) == "number"
      and vim.api.nvim_win_is_valid(self.winnr)
      and type(self.bufnr) == "number"
      and vim.api.nvim_buf_is_valid(self.bufnr)
  end
end

function PopupWindow:resize()
  if self._resizing then
    return
  end
  if not self:is_valid() then
    return
  end

  self._resizing = true
  local nvim_float_win_opts =
    M.make_opts(self._saved_win_opts, self._saved_current_winnr, self._saved_current_win_first_line)
  vim.api.nvim_win_set_config(self.winnr, nvim_float_win_opts)
  vim.schedule(function()
    self._resizing = false
  end)
end

--- @return integer
function PopupWindow:handle()
  return self.winnr
end

M.PopupWindow = PopupWindow

-- PopupWindow }

-- PopupWindowManager {

--- @class fzfx.PopupWindowsManager
--- @field instances table<integer, fzfx.PopupWindow>
local PopupWindowsManager = {}

function PopupWindowsManager:new()
  local o = {
    instances = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param obj fzfx.PopupWindow
function PopupWindowsManager:add(obj)
  self.instances[obj:handle()] = obj
end

--- @param obj fzfx.PopupWindow
function PopupWindowsManager:remove(obj)
  self.instances[obj:handle()] = nil
end

function PopupWindowsManager:resize()
  for _, obj in pairs(self.instances) do
    if obj then
      vim.schedule(function()
        obj:resize()
      end)
    end
  end
end

-- PopupWindowManager }

M._PopupWindowsManagerInstance = PopupWindowsManager:new()

M.setup = function()
  vim.api.nvim_create_autocmd({ "VimResized" }, {
    callback = function()
      M._PopupWindowsManagerInstance:resize()
    end,
  })
  if version.ge("0.9") then
    vim.api.nvim_create_autocmd({ "WinResized" }, {
      callback = function()
        M._PopupWindowsManagerInstance:resize()
      end,
    })
  end
end

return M
