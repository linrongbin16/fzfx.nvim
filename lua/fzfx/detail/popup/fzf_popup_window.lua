local api = require("fzfx.commons.api")

local log = require("fzfx.lib.log")
local popup_helpers = require("fzfx.detail.popup.popup_helpers")

local M = {}

local FLOAT_WIN_DEFAULT_BORDER = "none"
local FLOAT_WIN_DEFAULT_ZINDEX = 60

--- @param win_opts fzfx.WindowOpts
--- @param relative_winnr integer?
--- @return fzfx.NvimFloatWinOpts
M._make_cursor_opts = function(win_opts, relative_winnr)
  local opts = vim.deepcopy(win_opts)
  local relative = "win"
  local layout = popup_helpers.make_cursor_layout(opts)
  log.debug("|_make_cursor_opts| layout:" .. vim.inspect(layout))

  local result = {
    anchor = "NW",
    relative = relative,
    width = layout.width,
    height = layout.height,
    row = layout.start_row,
    col = layout.start_col,
    style = "minimal",
    border = FLOAT_WIN_DEFAULT_BORDER,
    zindex = FLOAT_WIN_DEFAULT_ZINDEX,
  }

  if type(relative_winnr) == "number" then
    result.win = relative_winnr
  end

  return result
end

--- @param win_opts fzfx.WindowOpts
--- @param relative_winnr integer?
--- @return fzfx.NvimFloatWinOpts
M._make_center_opts = function(win_opts, relative_winnr)
  local opts = vim.deepcopy(win_opts)
  local relative = opts.relative or "editor"
  local layout = popup_helpers.make_center_layout(opts)
  log.debug("|_make_center_opts| layout:%s" .. vim.inspect(layout))

  local result = {
    anchor = "NW",
    relative = relative,
    width = layout.width,
    height = layout.height,
    row = layout.start_row,
    col = layout.start_col,
    style = "minimal",
    border = FLOAT_WIN_DEFAULT_BORDER,
    zindex = FLOAT_WIN_DEFAULT_ZINDEX,
  }

  if relative == "win" and type(relative_winnr) == "number" then
    result.win = relative_winnr
  end

  return result
end

--- @param win_opts fzfx.WindowOpts
--- @param relative_winnr integer?
--- @return fzfx.NvimFloatWinOpts
M.make_opts = function(win_opts, relative_winnr)
  local opts = vim.deepcopy(win_opts)
  opts.relative = opts.relative or "editor"
  log.ensure(
    opts.relative == "cursor" or opts.relative == "editor" or opts.relative == "win",
    string.format("window relative (%s) must be editor/win/cursor", vim.inspect(opts))
  )
  return opts.relative == "cursor" and M._make_cursor_opts(opts, relative_winnr)
    or M._make_center_opts(opts, relative_winnr)
end

-- FzfPopupWindow {

--- @class fzfx.FzfPopupWindow
--- @field window_opts_context fzfx.WindowOptsContext?
--- @field bufnr integer?
--- @field winnr integer?
--- @field _saved_current_winnr integer
--- @field _saved_win_opts fzfx.WindowOpts
--- @field _resizing boolean
local FzfPopupWindow = {}

--- @package
--- @param win_opts fzfx.WindowOpts
--- @return fzfx.FzfPopupWindow
function FzfPopupWindow:new(win_opts)
  local current_winnr = vim.api.nvim_get_current_win()

  -- save current window context
  local window_opts_context = popup_helpers.WindowOptsContext:save()

  --- @type integer
  local bufnr = vim.api.nvim_create_buf(false, true)
  -- setlocal bufhidden=wipe nobuflisted
  -- setft=fzf
  api.set_buf_option(bufnr, "bufhidden", "wipe")
  api.set_buf_option(bufnr, "buflisted", false)
  api.set_buf_option(bufnr, "filetype", "fzf")

  local nvim_float_win_opts = M.make_opts(win_opts, current_winnr)

  local winnr = vim.api.nvim_open_win(bufnr, true, nvim_float_win_opts)
  --- setlocal nospell nonumber
  --- set winhighlight='Pmenu:,Normal:Normal'
  --- set colorcolumn=''
  api.set_win_option(winnr, "spell", false)
  api.set_win_option(winnr, "number", false)
  api.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
  api.set_win_option(winnr, "colorcolumn", "")
  api.set_win_option(winnr, "wrap", false)

  local o = {
    window_opts_context = window_opts_context,
    bufnr = bufnr,
    winnr = winnr,
    _saved_current_winnr = current_winnr,
    _saved_win_opts = win_opts,
    _resizing = false,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function FzfPopupWindow:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

  if vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_close(self.winnr, true)
    self.winnr = nil
  end

  self.bufnr = nil
  self.window_opts_context:restore()
end

function FzfPopupWindow:is_valid()
  if vim.in_fast_event() then
    return type(self.winnr) == "number" and type(self.bufnr) == "number"
  else
    return type(self.winnr) == "number"
      and vim.api.nvim_win_is_valid(self.winnr)
      and type(self.bufnr) == "number"
      and vim.api.nvim_buf_is_valid(self.bufnr)
  end
end

function FzfPopupWindow:resize()
  if self._resizing then
    return
  end
  if not self:is_valid() then
    return
  end

  self._resizing = true
  local nvim_float_win_opts = M.make_opts(self._saved_win_opts, self._saved_current_winnr)
  vim.api.nvim_win_set_config(self.winnr, nvim_float_win_opts)
  vim.schedule(function()
    self._resizing = false
  end)
end

--- @return integer
function FzfPopupWindow:handle()
  return self.winnr
end

M.FzfPopupWindow = FzfPopupWindow

-- FzfPopupWindow }

return M
