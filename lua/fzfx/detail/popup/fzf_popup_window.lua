local numbers = require("fzfx.commons.numbers")
local apis = require("fzfx.commons.apis")
local fileios = require("fzfx.commons.fileios")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")
local popup_helpers = require("fzfx.detail.popup.helpers")

local M = {}

--- @param opts fzfx.WindowOpts
--- @return fzfx.NvimFloatWinOpts
M._make_cursor_opts = function(opts)
  local relative = "cursor"
  local total_width = vim.api.nvim_win_get_width(0)
  local total_height = vim.api.nvim_win_get_height(0)
  local width = popup_helpers.get_window_size(opts.width, total_width)
  local height = popup_helpers.get_window_size(opts.height, total_height)

  log.ensure(
    opts.row >= 0,
    "window row (%s) opts must >= 0!",
    vim.inspect(opts)
  )
  log.ensure(
    opts.row >= 0,
    "window col (%s) opts must >= 0!",
    vim.inspect(opts)
  )
  local row = opts.row
  local col = opts.col

  return {
    anchor = "NW",
    relative = relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border,
    zindex = opts.zindex,
  }
end

--- @param opts fzfx.WindowOpts
--- @return fzfx.NvimFloatWinOpts
M._make_center_opts = function(opts)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]
  local total_width = relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(0)
  local total_height = relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(0)
  local width = popup_helpers.get_window_size(opts.width, total_width)
  local height = popup_helpers.get_window_size(opts.height, total_height)

  log.ensure(
    (opts.row >= -0.5 and opts.row <= 0.5) or opts.row <= -1 or opts.row >= 1,
    "window row (%s) opts must in range [-0.5, 0.5] or (-inf, -1] or [1, +inf]",
    vim.inspect(opts)
  )
  log.ensure(
    (opts.col >= -0.5 and opts.col <= 0.5) or opts.col <= -1 or opts.col >= 1,
    "window col (%s) opts must in range [-0.5, 0.5] or (-inf, -1] or [1, +inf]",
    vim.inspect(opts)
  )
  local row = popup_helpers.shift_window_pos(total_height, height, opts.row)
  local col = popup_helpers.shift_window_pos(total_width, width, opts.col)

  return {
    anchor = "NW",
    relative = relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border,
    zindex = opts.zindex,
  }
end

--- @param win_opts fzfx.WindowOpts
--- @return fzfx.NvimFloatWinOpts
M.make_opts = function(win_opts)
  local opts = vim.deepcopy(win_opts)
  local relative = opts.relative or "editor"
  log.ensure(
    relative == "cursor" or relative == "editor" or relative == "win",
    "window relative (%s) must be editor/win/cursor",
    vim.inspect(relative)
  )
  if relative == "cursor" then
    return M._make_cursor_opts(opts)
  else
    return M._make_center_opts(opts)
  end
end

--- @type table<integer, fzfx.FzfPopupWindow>
local FzfPopupWindowInstances = {}

-- FzfPopupWindow {

--- @class fzfx.FzfPopupWindow
--- @field window_opts_context fzfx.WindowOptsContext?
--- @field bufnr integer?
--- @field winnr integer?
--- @field _saved_win_opts fzfx.WindowOpts
--- @field _resizing boolean
local FzfPopupWindow = {}

--- @package
--- @param win_opts fzfx.WindowOpts
--- @param builtin_preview_win_opts fzfx.WindowOpts?
--- @return fzfx.FzfPopupWindow
function FzfPopupWindow:new(win_opts, builtin_preview_win_opts)
  -- check executable: nvim, fzf
  fzf_helpers.nvim_exec()
  fzf_helpers.fzf_exec()

  -- save current window context
  local window_opts_context = fzf_helpers.WindowOptsContext:save()

  --- @type integer
  local bufnr = vim.api.nvim_create_buf(false, true)
  -- setlocal bufhidden=wipe nobuflisted
  -- setft=fzf
  apis.set_buf_option(bufnr, "bufhidden", "wipe")
  apis.set_buf_option(bufnr, "buflisted", false)
  apis.set_buf_option(bufnr, "filetype", "fzf")

  local nvim_float_win_opts = M.make_opts(win_opts)

  local winnr = vim.api.nvim_open_win(bufnr, true, nvim_float_win_opts)
  --- setlocal nospell nonumber
  --- set winhighlight='Pmenu:,Normal:Normal'
  --- set colorcolumn=''
  apis.set_win_option(winnr, "spell", false)
  apis.set_win_option(winnr, "number", false)
  apis.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
  apis.set_win_option(winnr, "colorcolumn", "")

  local o = {
    window_opts_context = window_opts_context,
    bufnr = bufnr,
    winnr = winnr,
    _saved_win_opts = win_opts,
    _resizing = false,
  }
  setmetatable(o, self)
  self.__index = self

  FzfPopupWindowInstances[winnr] = o
  return o
end

function FzfPopupWindow:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

  if vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_close(self.winnr, true)
    -- else
    --     log.debug(
    --         "cannot close invalid popup window! %s",
    --         vim.inspect(self.winnr)
    --     )
  end

  ---@diagnostic disable-next-line: undefined-field
  self.window_opts_context:restore()

  local instance = FzfPopupWindowInstances[self.winnr]
  if instance then
    FzfPopupWindowInstances[self.winnr] = nil
  end
end

function FzfPopupWindow:resize()
  if self._resizing then
    return
  end
  self._resizing = true
  local nvim_float_win_opts = M.make_opts(self._saved_win_opts)
  vim.api.nvim_win_set_config(self.winnr, nvim_float_win_opts)
  vim.schedule(function()
    self._resizing = false
  end)
end

M.FzfPopupWindow = FzfPopupWindow

-- FzfPopupWindow }

--- @return table<integer, fzfx.FzfPopupWindow>
M._get_instances = function()
  return FzfPopupWindowInstances
end

M._clear_instances = function()
  FzfPopupWindowInstances = {}
end

--- @return integer
M._count_instances = function()
  local n = 0
  for _, p in pairs(FzfPopupWindowInstances) do
    n = n + 1
  end
  return n
end

M.resize_instances = function()
  -- log.debug(
  --     "|fzfx.popup - resize_all_popup_window_instances| instances:%s",
  --     vim.inspect(PopupWindowInstances)
  -- )
  for winnr, popup_win in pairs(FzfPopupWindowInstances) do
    if winnr and popup_win then
      popup_win:resize()
    end
  end
end

return M
