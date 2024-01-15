local numbers = require("fzfx.commons.numbers")
local apis = require("fzfx.commons.apis")
local fileios = require("fzfx.commons.fileios")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")
local popup_helpers = require("fzfx.detail.popup.helpers")

local M = {}

-- provider cursor window {

--- @param opts fzfx.WindowOpts
--- @return fzfx.PopupWindowConfig
M._make_provider_cursor_opts = function(opts) end

-- provider cursor window }

-- previewer cursor window {

--- @param opts fzfx.WindowOpts
--- @return fzfx.PopupWindowConfig
M._make_previewer_cursor_opts = function(opts) end

-- previewer cursor window }

-- provider center window {

--- @param opts fzfx.WindowOpts
--- @return fzfx.PopupWindowConfig
M._make_provider_center_opts = function(opts)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]
  opts.width = opts.width / 2

  local total_width = relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(0)
  local total_height = relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(0)
  local width = popup_helpers._get_window_size(opts.width, total_width)
  local height = popup_helpers._get_window_size(opts.height, total_height)

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
  local row = popup_helpers._shift_window_pos(total_height, height, opts.row)
  local col = popup_helpers._shift_window_pos(
    total_width,
    width,
    opts.col,
    -math.floor(width / 2)
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

-- provider center window }

-- previewer center window {

--- @param opts fzfx.WindowOpts
--- @return fzfx.PopupWindowConfig
M._make_previewer_center_opts = function(opts)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]
  opts.width = opts.width / 2

  local total_width = relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(0)
  local total_height = relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(0)
  local width = popup_helpers._get_window_size(opts.width, total_width)
  local height = popup_helpers._get_window_size(opts.height, total_height)

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
  local row = popup_helpers._shift_window_pos(total_height, height, opts.row)
  local col = popup_helpers._shift_window_pos(
    total_width,
    width,
    opts.col,
    math.floor(width / 2)
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

-- previewer center window }

-- provider window {

--- @param win_opts fzfx.WindowOpts
--- @return fzfx.PopupWindowConfig
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
--- @return fzfx.PopupWindowConfig
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

--- @type table<integer, fzfx.BufferPopupWindow>
local BufferPopupWindowInstances = {}

--- @class fzfx.BufferPopupWindow
--- @field window_opts_context fzfx.WindowOptsContext?
--- @field provider_bufnr integer?
--- @field provider_winnr integer?
--- @field _saved_provider_win_opts fzfx.WindowOpts
--- @field previewer_bufnr integer?
--- @field previewer_winnr integer?
--- @field _saved_previewer_win_opts fzfx.WindowOpts
--- @field _resizing boolean
local BufferPopupWindow = {}

--- @package
--- @param provider_win_opts fzfx.WindowOpts
--- @param previewer_win_opts fzfx.WindowOpts
--- @return fzfx.BufferPopupWindow
function BufferPopupWindow:new(provider_win_opts, previewer_win_opts)
  -- check executable: nvim, fzf
  fzf_helpers.nvim_exec()
  fzf_helpers.fzf_exec()

  -- save current window context
  local window_opts_context = popup_helpers.WindowOptsContext:save()

  --- @type integer
  local provider_bufnr = vim.api.nvim_create_buf(false, true)
  -- setlocal bufhidden=wipe nobuflisted
  -- setft=fzf
  apis.set_buf_option(provider_bufnr, "bufhidden", "wipe")
  apis.set_buf_option(provider_bufnr, "buflisted", false)
  apis.set_buf_option(provider_bufnr, "filetype", "fzf")

  --- @type integer
  local previewer_bufnr = vim.api.nvim_create_buf(false, true)
  -- setlocal bufhidden=wipe nobuflisted
  -- setft=fzf
  apis.set_buf_option(previewer_bufnr, "bufhidden", "wipe")
  apis.set_buf_option(previewer_bufnr, "buflisted", false)
  apis.set_buf_option(previewer_bufnr, "filetype", "fzf_previewer")

  local provider_window_config = M.make_provider_opts(provider_win_opts)
  local previewer_window_config = M.make_previewer_opts(previewer_win_opts)
  previewer_window_config.focusable = false

  local previewer_winnr =
    vim.api.nvim_open_win(previewer_bufnr, true, previewer_win_opts)

  apis.set_win_option(previewer_winnr, "spell", false)
  apis.set_win_option(previewer_winnr, "number", false)
  apis.set_win_option(previewer_winnr, "winhighlight", "Pmenu:,Normal:Normal")
  apis.set_win_option(previewer_winnr, "colorcolumn", "")

  local provider_winnr =
    vim.api.nvim_open_win(provider_bufnr, true, provider_win_opts)
  --- setlocal nospell nonumber
  --- set winhighlight='Pmenu:,Normal:Normal'
  --- set colorcolumn=''
  apis.set_win_option(provider_winnr, "spell", false)
  apis.set_win_option(provider_winnr, "number", false)
  apis.set_win_option(provider_winnr, "winhighlight", "Pmenu:,Normal:Normal")
  apis.set_win_option(provider_winnr, "colorcolumn", "")

  local o = {
    window_opts_context = window_opts_context,
    provider_bufnr = provider_bufnr,
    provider_winnr = provider_winnr,
    _saved_provider_win_opts = provider_win_opts,
    _resizing = false,
  }
  setmetatable(o, self)
  self.__index = self

  BufferPopupWindowInstances[provider_winnr] = o
  return o
end

function BufferPopupWindow:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

  if vim.api.nvim_win_is_valid(self.provider_winnr) then
    vim.api.nvim_win_close(self.provider_winnr, true)
    -- else
    --     log.debug(
    --         "cannot close invalid popup window! %s",
    --         vim.inspect(self.winnr)
    --     )
  end

  ---@diagnostic disable-next-line: undefined-field
  self.window_opts_context:restore()

  local instance = BufferPopupWindowInstances[self.provider_winnr]
  if instance then
    BufferPopupWindowInstances[self.provider_winnr] = nil
  end
end

function BufferPopupWindow:resize()
  if self._resizing then
    return
  end
  self._resizing = true
  local new_popup_window_config = _make_window_config(self._saved_win_opts)
  vim.api.nvim_win_set_config(self.provider_winnr, new_popup_window_config)
  vim.schedule(function()
    self._resizing = false
  end)
end
