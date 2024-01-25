---@diagnostic disable: missing-return
local numbers = require("fzfx.commons.numbers")
local apis = require("fzfx.commons.apis")
local fileios = require("fzfx.commons.fileios")
local tables = require("fzfx.commons.tables")
local strings = require("fzfx.commons.strings")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")
local popup_helpers = require("fzfx.detail.popup.popup_helpers")

local M = {}

-- cursor window {

--- @param opts fzfx.WindowOpts
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts
--- @return fzfx.NvimFloatWinOpts
M._make_provider_cursor_opts = function(opts, fzf_preview_window_opts) end

--- @param opts fzfx.WindowOpts
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts
--- @return fzfx.NvimFloatWinOpts
M._make_previewer_cursor_opts = function(opts, fzf_preview_window_opts) end

-- cursor window }

-- center window {

--- @param opts fzfx.WindowOpts
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts
--- @return fzfx.NvimFloatWinOpts
M._make_provider_center_opts = function(opts, fzf_preview_window_opts)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]

  local total_width = relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(0)
  local total_height = relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(0)
  local width = popup_helpers.get_window_size(opts.width, total_width)
  local height = popup_helpers.get_window_size(opts.height, total_height)

  local additional_row_offset = 0
  local additional_col_offset = 0
  if
    fzf_preview_window_opts.position == "left"
    or fzf_preview_window_opts.position == "right"
  then
    local old_width = width
    local sign = fzf_preview_window_opts.position == "right" and -1 or 1
    if fzf_preview_window_opts.size_is_percent then
      width = math.floor(width - (width / 100 * fzf_preview_window_opts.size))
    else
      width = width - fzf_preview_window_opts.size
    end
    additional_col_offset = math.floor(math.abs(old_width - width) / 2) * sign
    -- + sign
  elseif
    fzf_preview_window_opts.position == "up"
    or fzf_preview_window_opts.position == "down"
  then
    local old_height = height
    local sign = fzf_preview_window_opts.position == "down" and -1 or 1
    if fzf_preview_window_opts.size_is_percent then
      height =
        math.floor(height - (height / 100 * fzf_preview_window_opts.size))
    else
      height = height - fzf_preview_window_opts.size
    end
    additional_row_offset = math.floor(math.abs(old_height - height) / 2) * sign
    -- + sign
  end
  log.debug(
    "|_make_provider_center_opts| opts:%s, fzf_preview_window_opts:%s, height:%s(%s), width:%s(%s), additional_row_offset:%s, additional_col_offset:%s",
    vim.inspect(opts),
    vim.inspect(fzf_preview_window_opts),
    vim.inspect(height),
    vim.inspect(total_height),
    vim.inspect(width),
    vim.inspect(total_width),
    vim.inspect(additional_row_offset),
    vim.inspect(additional_col_offset)
  )

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
  local row = popup_helpers.shift_window_pos(
    total_height,
    height,
    opts.row,
    additional_row_offset
  )
  local col = popup_helpers.shift_window_pos(
    total_width,
    width,
    opts.col,
    additional_col_offset
  )

  local result = {
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
  log.debug("|_make_provider_center_opts| result:%s", vim.inspect(result))
  return result
end

--- @param opts fzfx.WindowOpts
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts
--- @return fzfx.NvimFloatWinOpts
M._make_previewer_center_opts = function(opts, fzf_preview_window_opts)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]

  local total_width = relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(0)
  local total_height = relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(0)
  local width = popup_helpers.get_window_size(opts.width, total_width)
  local height = popup_helpers.get_window_size(opts.height, total_height)

  local additional_row_offset = 0
  local additional_col_offset = 0
  if
    fzf_preview_window_opts.position == "left"
    or fzf_preview_window_opts.position == "right"
  then
    local old_width = width
    local sign = fzf_preview_window_opts.position == "left" and -1 or 1
    if fzf_preview_window_opts.size_is_percent then
      width = math.floor(width / 100 * fzf_preview_window_opts.size)
    else
      width = fzf_preview_window_opts.size
    end
    additional_col_offset = math.floor(math.abs(old_width - width) / 2) * sign
      + sign
  elseif
    fzf_preview_window_opts.position == "up"
    or fzf_preview_window_opts.position == "down"
  then
    local old_height = height
    local sign = fzf_preview_window_opts.position == "up" and -1 or 1
    if fzf_preview_window_opts.size_is_percent then
      height = math.floor(height / 100 * fzf_preview_window_opts.size)
    else
      height = fzf_preview_window_opts.size
    end
    additional_row_offset = math.floor(math.abs(old_height - height) / 2) * sign
      + sign
  end
  log.debug(
    "|_make_previewer_center_opts| opts:%s, fzf_preview_window_opts:%s, height:%s(%s), width:%s(%s), additional_row_offset:%s, additional_col_offset:%s",
    vim.inspect(opts),
    vim.inspect(fzf_preview_window_opts),
    vim.inspect(height),
    vim.inspect(total_height),
    vim.inspect(width),
    vim.inspect(total_width),
    vim.inspect(additional_row_offset),
    vim.inspect(additional_col_offset)
  )

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
  local row = popup_helpers.shift_window_pos(
    total_height,
    height,
    opts.row,
    additional_row_offset
  )
  local col = popup_helpers.shift_window_pos(
    total_width,
    width,
    opts.col,
    additional_col_offset
  )

  local result = {
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
  log.debug("|_make_previewer_center_opts| result:%s", vim.inspect(result))
  return result
end

-- center window }

-- provider window {

--- @param win_opts fzfx.WindowOpts
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts
--- @return fzfx.NvimFloatWinOpts
M.make_provider_opts = function(win_opts, fzf_preview_window_opts)
  local opts = vim.deepcopy(win_opts)
  local relative = opts.relative or "editor"
  log.ensure(
    relative == "cursor" or relative == "editor" or relative == "win",
    "window relative (%s) must be editor/win/cursor",
    vim.inspect(opts)
  )
  if relative == "cursor" then
    return M._make_provider_cursor_opts(opts, fzf_preview_window_opts)
  else
    return M._make_provider_center_opts(opts, fzf_preview_window_opts)
  end
end

-- provider window }

-- previewer window {

--- @param win_opts fzfx.WindowOpts
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts
--- @return fzfx.NvimFloatWinOpts
M.make_previewer_opts = function(win_opts, fzf_preview_window_opts)
  local opts = vim.deepcopy(win_opts)
  local relative = opts.relative or "editor"
  log.ensure(
    relative == "cursor" or relative == "editor" or relative == "win",
    "window relative (%s) must be editor/win/cursor",
    vim.inspect(opts)
  )
  if relative == "cursor" then
    return M._make_previewer_cursor_opts(opts, fzf_preview_window_opts)
  else
    return M._make_previewer_center_opts(opts, fzf_preview_window_opts)
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
--- @field _saved_fzf_preview_window_opts fzfx.FzfPreviewWindowOpts
--- @field _resizing boolean
--- @field preview_files_queue fzfx.BuiltinFilePreviewerResult[]
--- @field preview_file_contents_queue {lines:string[],preview_result:fzfx.BuiltinFilePreviewerResult}[]
local BufferPopupWindow = {}

--- @package
--- @param win_opts fzfx.WindowOpts
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts
--- @return fzfx.BufferPopupWindow
function BufferPopupWindow:new(win_opts, fzf_preview_window_opts)
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

  local provider_nvim_float_win_opts =
    M.make_provider_opts(win_opts, fzf_preview_window_opts)
  provider_nvim_float_win_opts.border = "rounded"
  local previewer_nvim_float_win_opts =
    M.make_previewer_opts(win_opts, fzf_preview_window_opts)
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
    _saved_fzf_preview_window_opts = fzf_preview_window_opts,
    _resizing = false,
    preview_files_queue = {},
    preview_file_contents_queue = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function BufferPopupWindow:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

  if vim.api.nvim_win_is_valid(self.provider_winnr) then
    vim.api.nvim_win_close(self.provider_winnr, true)
    self.provider_winnr = nil
  end
  if vim.api.nvim_win_is_valid(self.previewer_winnr) then
    vim.api.nvim_win_close(self.previewer_winnr, true)
    self.previewer_winnr = nil
  end

  self.provider_bufnr = nil
  self.previewer_bufnr = nil
  self.window_opts_context:restore()
end

function BufferPopupWindow:resize()
  if self._resizing then
    return
  end
  self._resizing = true
  local provider_nvim_float_win_opts = M.make_provider_opts(
    self._saved_win_opts,
    self._saved_fzf_preview_window_opts
  )
  local previewer_nvim_float_win_opts = M.make_previewer_opts(
    self._saved_win_opts,
    self._saved_fzf_preview_window_opts
  )
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

function BufferPopupWindow:preview_files_queue_empty()
  return #self.preview_files_queue == 0
end

function BufferPopupWindow:preview_files_queue_last()
  return self.preview_files_queue[#self.preview_files_queue]
end

function BufferPopupWindow:preview_files_queue_clear()
  self.preview_files_queue = {}
end

function BufferPopupWindow:preview_file_contents_queue_empty()
  return #self.preview_file_contents_queue == 0
end

function BufferPopupWindow:preview_file_contents_queue_last()
  return self.preview_file_contents_queue[#self.preview_file_contents_queue]
end

function BufferPopupWindow:preview_file_contents_queue_clear()
  self.preview_file_contents_queue = {}
end

function BufferPopupWindow:clear_preview_file_job()
  self:preview_files_queue_clear()
  self:preview_file_contents_queue_clear()
end

function BufferPopupWindow:is_valid()
  if vim.in_fast_event() then
    return type(self.previewer_winnr) == "number"
      and type(self.previewer_bufnr) == "number"
  else
    return type(self.previewer_winnr) == "number"
      and vim.api.nvim_win_is_valid(self.previewer_winnr)
      and type(self.previewer_bufnr) == "number"
      and vim.api.nvim_buf_is_valid(self.previewer_bufnr)
  end
end

--- @param previewer_result fzfx.BuiltinFilePreviewerResult
function BufferPopupWindow:preview_file(previewer_result)
  if strings.empty(tables.tbl_get(previewer_result, "filename")) then
    return
  end
  table.insert(self.preview_files_queue, previewer_result)

  vim.defer_fn(function()
    if not self:is_valid() then
      return
    end
    if self:preview_files_queue_empty() then
      return
    end

    local last_result = self:preview_files_queue_last()
    self:preview_files_queue_clear()

    -- read file content
    fileios.asyncreadfile(last_result.filename, function(file_content)
      if self:is_valid() then
        return
      end
      if not self:preview_files_queue_empty() then
        return
      end

      local lines = {}
      if strings.not_empty(file_content) then
        file_content = file_content:gsub("\r\n", "\n")
        lines = strings.split(file_content, "\n")
      end
      table.insert(
        self.preview_file_contents_queue,
        { lines = lines, preview_result = last_result }
      )

      -- show file contents by lines
      vim.defer_fn(function()
        if not self:is_valid() then
          return
        end
        if not self:preview_files_queue_empty() then
          return
        end
        if self:preview_file_contents_queue_empty() then
          return
        end

        local last_lines = self:preview_file_contents_queue_last()
        self:preview_file_contents_queue_clear()

        vim.api.nvim_buf_set_lines(self.previewer_bufnr, 0, -1, false, {})
        local set_name_ok, set_name_err = pcall(
          vim.api.nvim_buf_set_name,
          self.previewer_bufnr,
          last_lines.preview_result.filename
        )
        if not set_name_ok then
          log.debug(
            "|BufferPopupWindow:preview_file.asyncreadfile| failed to set name for previewer buffer:%s(%s), error:%s",
            vim.inspect(last_lines.preview_result.filename),
            vim.inspect(self.previewer_bufnr),
            vim.inspect(set_name_err)
          )
        end
        vim.api.nvim_buf_call(self.previewer_bufnr, function()
          vim.api.nvim_command([[filetype detect]])
        end)

        local LINE_COUNT = 5
        local line_index = 1

        local function set_buf_lines()
          vim.defer_fn(function()
            if not self:is_valid() then
              return
            end
            if not self:preview_files_queue_empty() then
              return
            end
            if not self:preview_file_contents_queue_empty() then
              return
            end

            local buf_lines = {}
            for i = line_index, line_index + LINE_COUNT do
              if i <= #last_lines.lines then
                table.insert(buf_lines, last_lines.lines[i])
              end
            end
            vim.api.nvim_buf_set_lines(
              self.previewer_bufnr,
              line_index - 1,
              line_index - 1 + LINE_COUNT,
              false,
              buf_lines
            )
            line_index = line_index + LINE_COUNT
            if line_index <= #last_lines.lines then
              set_buf_lines()
            end
          end, 25)
        end
        set_buf_lines()
      end, 25)
    end)
  end, 80)
end

M.BufferPopupWindow = BufferPopupWindow

-- BufferPopupWindow }

return M
