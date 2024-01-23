local numbers = require("fzfx.commons.numbers")
local apis = require("fzfx.commons.apis")
local fileios = require("fzfx.commons.fileios")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")
local popup_helpers = require("fzfx.detail.popup.helpers")

local M = {}

-- cursor window {

--- @param opts fzfx.WindowOpts
M._make_provider_cursor_opts = function(opts) end

--- @param opts fzfx.WindowOpts
M._make_previewer_cursor_opts = function(opts) end

-- cursor window }

-- center window {

--- @param opts fzfx.WindowOpts
--- @return fzfx.NvimFloatWinOpts
M._make_provider_center_opts = function(opts)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]
  opts.width = opts.width / 2

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
  local col = popup_helpers.shift_window_pos(
    total_width,
    width,
    opts.col,
    -math.floor(width / 2) - 1
  )

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
M._make_previewer_center_opts = function(opts)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]
  opts.width = opts.width / 2

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
  local col = popup_helpers.shift_window_pos(
    total_width,
    width,
    opts.col,
    math.floor(width / 2) + 1
  )

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

-- center window }

-- provider window {

--- @param win_opts fzfx.WindowOpts
--- @return fzfx.NvimFloatWinOpts
M.make_provider_opts = function(win_opts)
  local opts = vim.deepcopy(win_opts)
  local relative = opts.relative or "editor"
  log.ensure(
    relative == "cursor" or relative == "editor" or relative == "win",
    "window relative (%s) must be editor/win/cursor",
    vim.inspect(opts)
  )
  if relative == "cursor" then
    return M._make_provider_cursor_opts(opts)
  else
    return M._make_provider_center_opts(opts)
  end
end

-- provider window }

-- previewer window {

--- @param win_opts fzfx.WindowOpts
--- @return fzfx.NvimFloatWinOpts
M.make_previewer_opts = function(win_opts)
  local opts = vim.deepcopy(win_opts)
  local relative = opts.relative or "editor"
  log.ensure(
    relative == "cursor" or relative == "editor" or relative == "win",
    "window relative (%s) must be editor/win/cursor",
    vim.inspect(opts)
  )
  if relative == "cursor" then
    return M._make_previewer_cursor_opts(opts)
  else
    return M._make_previewer_center_opts(opts)
  end
end

-- previewer window }

-- BufferPopupWindow {

--- @class fzfx.BufferPopupWindow
--- @field window_opts_context fzfx.WindowOptsContext?
--- @field provider_bufnr integer?
--- @field provider_winnr integer?
--- @field previewer_bufnr integer?
--- @field previewer_winnr integer?
--- @field _saved_win_opts fzfx.WindowOpts
--- @field _resizing boolean
local BufferPopupWindow = {}

--- @package
--- @param win_opts fzfx.WindowOpts
--- @return fzfx.BufferPopupWindow
function BufferPopupWindow:new(win_opts)
  -- save current window context
  local window_opts_context = popup_helpers.WindowOptsContext:save()

  --- @type integer
  local provider_bufnr = vim.api.nvim_create_buf(false, true)
  apis.set_buf_option(provider_bufnr, "bufhidden", "wipe")
  apis.set_buf_option(provider_bufnr, "buflisted", false)
  apis.set_buf_option(provider_bufnr, "filetype", "fzf")

  --- @type integer
  local previewer_bufnr = vim.api.nvim_create_buf(false, true)
  apis.set_buf_option(previewer_bufnr, "bufhidden", "wipe")
  apis.set_buf_option(previewer_bufnr, "buflisted", false)
  apis.set_buf_option(previewer_bufnr, "filetype", "fzf")

  local provider_nvim_float_win_opts = M.make_provider_opts(win_opts)
  provider_nvim_float_win_opts.border = "rounded"
  local previewer_nvim_float_win_opts = M.make_previewer_opts(win_opts)
  previewer_nvim_float_win_opts.border = "rounded"
  previewer_nvim_float_win_opts.focusable = false

  local previewer_winnr =
    vim.api.nvim_open_win(previewer_bufnr, true, previewer_nvim_float_win_opts)
  apis.set_win_option(previewer_winnr, "number", true)
  apis.set_win_option(previewer_winnr, "spell", false)
  apis.set_win_option(previewer_winnr, "winhighlight", "Pmenu:,Normal:Normal")

  local provider_winnr =
    vim.api.nvim_open_win(provider_bufnr, true, provider_nvim_float_win_opts)
  apis.set_win_option(provider_winnr, "spell", false)
  apis.set_win_option(provider_winnr, "number", false)
  apis.set_win_option(provider_winnr, "winhighlight", "Pmenu:,Normal:Normal")
  apis.set_win_option(provider_winnr, "colorcolumn", "")
  vim.api.nvim_set_current_win(provider_winnr)

  local o = {
    window_opts_context = window_opts_context,
    provider_bufnr = provider_bufnr,
    provider_winnr = provider_winnr,
    previewer_bufnr = previewer_bufnr,
    previewer_winnr = previewer_winnr,
    _saved_win_opts = win_opts,
    _resizing = false,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function BufferPopupWindow:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

  if vim.api.nvim_win_is_valid(self.provider_winnr) then
    vim.api.nvim_win_close(self.provider_winnr, true)
  end
  if vim.api.nvim_win_is_valid(self.previewer_winnr) then
    vim.api.nvim_win_close(self.previewer_winnr, true)
  end

  self.window_opts_context:restore()
end

function BufferPopupWindow:resize()
  if self._resizing then
    return
  end
  self._resizing = true
  local provider_nvim_float_win_opts =
    M.make_provider_opts(self._saved_win_opts)
  local previewer_nvim_float_win_opts =
    M.make_previewer_opts(self._saved_win_opts)
  vim.api.nvim_win_set_config(self.provider_winnr, provider_nvim_float_win_opts)
  vim.api.nvim_win_set_config(
    self.previewer_winnr,
    previewer_nvim_float_win_opts
  )
  vim.schedule(function()
    self._resizing = false
  end)
end

--- @return integer
function BufferPopupWindow:handle()
  return self.provider_winnr
end

M.BufferPopupWindow = BufferPopupWindow

-- BufferPopupWindow }

return M
