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

local FLOAT_WIN_DEFAULT_ZINDEX = 60

--- @alias fzfx.BufferFilePreviewerOpts {fzf_preview_window_opts:fzfx.FzfPreviewWindowOpts,fzf_border_opts:string}

-- cursor window {

--- @param opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.NvimFloatWinOpts
M._make_provider_cursor_opts = function(opts, buffer_previewer_opts) end

--- @param opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.NvimFloatWinOpts
M._make_provider_cursor_opts_with_hidden_previewer = function(
  opts,
  buffer_previewer_opts
)
end

--- @param opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.NvimFloatWinOpts
M._make_previewer_cursor_opts = function(opts, buffer_previewer_opts) end

-- cursor window }

-- center window {

--- @param opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.NvimFloatWinOpts
M._make_provider_center_opts = function(opts, buffer_previewer_opts)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]

  local total_width = relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(0)
  local total_height = relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(0)
  local width = popup_helpers.get_window_size(opts.width, total_width)
  local height = popup_helpers.get_window_size(opts.height, total_height)

  local fzf_preview_window_opts = buffer_previewer_opts.fzf_preview_window_opts

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
      width = math.max(width - fzf_preview_window_opts.size, 1)
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
      height = math.max(height - fzf_preview_window_opts.size, 1)
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
    border = fzf_helpers.FZF_BORDER_OPTS_MAP[buffer_previewer_opts.fzf_border_opts]
      or fzf_helpers.FZF_DEFAULT_BORDER_OPTS,
    zindex = FLOAT_WIN_DEFAULT_ZINDEX,
  }
  log.debug("|_make_provider_center_opts| result:%s", vim.inspect(result))
  return result
end

--- @param opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.NvimFloatWinOpts
M._make_provider_center_opts_with_hidden_previewer = function(
  opts,
  buffer_previewer_opts
)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]

  local total_width = relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(0)
  local total_height = relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(0)
  local width = popup_helpers.get_window_size(opts.width, total_width)
  local height = popup_helpers.get_window_size(opts.height, total_height)

  log.ensure(
    (opts.row >= -0.5 and opts.row <= 0.5) or opts.row <= -1 or opts.row >= 1,
    "buffer provider window row (%s) opts must in range [-0.5, 0.5] or (-inf, -1] or [1, +inf]",
    vim.inspect(opts)
  )
  log.ensure(
    (opts.col >= -0.5 and opts.col <= 0.5) or opts.col <= -1 or opts.col >= 1,
    "buffer provider window col (%s) opts must in range [-0.5, 0.5] or (-inf, -1] or [1, +inf]",
    vim.inspect(opts)
  )
  local row = popup_helpers.shift_window_pos(total_height, height, opts.row)
  local col = popup_helpers.shift_window_pos(total_width, width, opts.col)

  local result = {
    anchor = "NW",
    relative = relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = fzf_helpers.FZF_BORDER_OPTS_MAP[buffer_previewer_opts.fzf_border_opts]
      or fzf_helpers.FZF_DEFAULT_BORDER_OPTS,
    zindex = FLOAT_WIN_DEFAULT_ZINDEX,
  }
  log.debug("|_make_provider_center_opts| result:%s", vim.inspect(result))
  return result
end

--- @param opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.NvimFloatWinOpts
M._make_previewer_center_opts = function(opts, buffer_previewer_opts)
  local relative = opts.relative or "editor" --[[@as "editor"|"win"]]

  local total_width = relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(0)
  local total_height = relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(0)
  local width = popup_helpers.get_window_size(opts.width, total_width)
  local height = popup_helpers.get_window_size(opts.height, total_height)

  local fzf_preview_window_opts = buffer_previewer_opts.fzf_preview_window_opts

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
    border = fzf_preview_window_opts.border,
    zindex = FLOAT_WIN_DEFAULT_ZINDEX,
  }
  log.debug("|_make_previewer_center_opts| result:%s", vim.inspect(result))
  return result
end

-- center window }

-- provider window {

--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.NvimFloatWinOpts
M.make_provider_opts = function(win_opts, buffer_previewer_opts)
  local opts = vim.deepcopy(win_opts)
  local relative = opts.relative or "editor"
  log.ensure(
    relative == "cursor" or relative == "editor" or relative == "win",
    "window relative (%s) must be editor/win/cursor",
    vim.inspect(opts)
  )
  if relative == "cursor" then
    return M._make_provider_cursor_opts(opts, buffer_previewer_opts)
  else
    return M._make_provider_center_opts(opts, buffer_previewer_opts)
  end
end

--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.NvimFloatWinOpts
M.make_provider_opts_with_hidden_previewer = function(
  win_opts,
  buffer_previewer_opts
)
  local opts = vim.deepcopy(win_opts)
  local relative = opts.relative or "editor"
  log.ensure(
    relative == "cursor" or relative == "editor" or relative == "win",
    "window relative (%s) must be editor/win/cursor",
    vim.inspect(opts)
  )
  if relative == "cursor" then
    return M._make_provider_cursor_opts_with_hidden_previewer(
      opts,
      buffer_previewer_opts
    )
  else
    return M._make_provider_center_opts_with_hidden_previewer(
      opts,
      buffer_previewer_opts
    )
  end
end

-- provider window }

-- previewer window {

--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.NvimFloatWinOpts
M.make_previewer_opts = function(win_opts, buffer_previewer_opts)
  local opts = vim.deepcopy(win_opts)
  local relative = opts.relative or "editor"
  log.ensure(
    relative == "cursor" or relative == "editor" or relative == "win",
    "window relative (%s) must be editor/win/cursor",
    vim.inspect(opts)
  )
  if relative == "cursor" then
    return M._make_previewer_cursor_opts(opts, buffer_previewer_opts)
  else
    return M._make_previewer_center_opts(opts, buffer_previewer_opts)
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
--- @field _saved_buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @field _resizing boolean
--- @field preview_files_queue {previewer_result:fzfx.BufferFilePreviewerResult,previewer_label_result:string?,job_id:integer}[]
--- @field preview_file_contents_queue {lines:string[],previewer_result:fzfx.BufferFilePreviewerResult,previewer_label_result:string?,job_id:integer}[]
--- @field preview_file_job_id integer
local BufferPopupWindow = {}

local function _set_default_buf_options(bufnr)
  apis.set_buf_option(bufnr, "bufhidden", "wipe")
  apis.set_buf_option(bufnr, "buflisted", false)
  apis.set_buf_option(bufnr, "filetype", "fzf")
end

local function _set_default_previewer_win_options(winnr)
  apis.set_win_option(winnr, "number", true)
  apis.set_win_option(winnr, "spell", false)
  apis.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
end

local function _set_default_provider_win_options(winnr)
  apis.set_win_option(winnr, "number", false)
  apis.set_win_option(winnr, "spell", false)
  apis.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
end

--- @package
--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.BufferPopupWindow
function BufferPopupWindow:new(win_opts, buffer_previewer_opts)
  -- save current window context
  local window_opts_context = popup_helpers.WindowOptsContext:save()

  --- @type integer
  local provider_bufnr = vim.api.nvim_create_buf(false, true)
  _set_default_buf_options(provider_bufnr)

  --- @type integer
  local previewer_bufnr = vim.api.nvim_create_buf(false, true)
  _set_default_buf_options(previewer_bufnr)

  local provider_nvim_float_win_opts =
    M.make_provider_opts(win_opts, buffer_previewer_opts)
  local previewer_nvim_float_win_opts =
    M.make_previewer_opts(win_opts, buffer_previewer_opts)
  previewer_nvim_float_win_opts.focusable = false

  local previewer_winnr =
    vim.api.nvim_open_win(previewer_bufnr, true, previewer_nvim_float_win_opts)
  _set_default_previewer_win_options(previewer_winnr)

  local provider_winnr =
    vim.api.nvim_open_win(provider_bufnr, true, provider_nvim_float_win_opts)
  _set_default_provider_win_options(provider_winnr)
  apis.set_win_option(provider_winnr, "colorcolumn", "")

  -- set cursor at provider window
  vim.api.nvim_set_current_win(provider_winnr)

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = provider_bufnr,
    nested = true,
    callback = function()
      log.debug("|BufferPopupWindow:new| enter provider buffer")
      vim.cmd("startinsert")
    end,
  })

  local o = {
    window_opts_context = window_opts_context,
    provider_bufnr = provider_bufnr,
    provider_winnr = provider_winnr,
    previewer_bufnr = previewer_bufnr,
    previewer_winnr = previewer_winnr,
    _saved_win_opts = win_opts,
    _saved_buffer_previewer_opts = buffer_previewer_opts,
    _resizing = false,
    preview_files_queue = {},
    preview_file_contents_queue = {},
    preview_file_job_id = 0,
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
  if not self:is_valid() then
    return
  end

  self._resizing = true

  if self:preview_hidden() then
    local provider_win_confs = M.make_provider_opts_with_hidden_previewer(
      self._saved_win_opts,
      self._saved_buffer_previewer_opts
    )
    vim.api.nvim_win_set_config(self.provider_winnr, provider_win_confs)
  else
    local provider_win_confs = M.make_provider_opts(
      self._saved_win_opts,
      self._saved_buffer_previewer_opts
    )
    vim.api.nvim_win_set_config(self.provider_winnr, provider_win_confs)
    local previewer_win_confs = M.make_previewer_opts(
      self._saved_win_opts,
      self._saved_buffer_previewer_opts
    )
    vim.api.nvim_win_set_config(self.previewer_winnr, previewer_win_confs)
  end

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

--- @return {previewer_result:fzfx.BufferFilePreviewerResult,previewer_label_result:string?,job_id:integer}
function BufferPopupWindow:preview_files_queue_last()
  return self.preview_files_queue[#self.preview_files_queue]
end

function BufferPopupWindow:preview_files_queue_clear()
  self.preview_files_queue = {}
end

function BufferPopupWindow:preview_file_contents_queue_empty()
  return #self.preview_file_contents_queue == 0
end

--- @return {lines:string[],previewer_result:fzfx.BufferFilePreviewerResult,previewer_label_result:string?,job_id:integer}
function BufferPopupWindow:preview_file_contents_queue_last()
  return self.preview_file_contents_queue[#self.preview_file_contents_queue]
end

function BufferPopupWindow:preview_file_contents_queue_clear()
  self.preview_file_contents_queue = {}
end

--- @param job_id integer
function BufferPopupWindow:set_preview_file_job_id(job_id)
  self.preview_file_job_id = job_id
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

--- @param job_id integer
--- @param previewer_result fzfx.BufferFilePreviewerResult
--- @param previewer_label_result string?
function BufferPopupWindow:preview_file(
  job_id,
  previewer_result,
  previewer_label_result
)
  if strings.empty(tables.tbl_get(previewer_result, "filename")) then
    return
  end
  if job_id < self.preview_file_job_id then
    return
  end
  table.insert(self.preview_files_queue, {
    previewer_result = previewer_result,
    previewer_label_result = previewer_label_result,
    job_id = job_id,
  })

  vim.defer_fn(function()
    if not self:is_valid() then
      return
    end
    if self:preview_files_queue_empty() then
      return
    end

    local last_job = self:preview_files_queue_last()
    self:preview_files_queue_clear()
    if last_job.job_id < self.preview_file_job_id then
      return
    end

    -- read file content
    fileios.asyncreadfile(
      last_job.previewer_result.filename,
      function(file_content)
        if not self:is_valid() then
          return
        end
        if not self:preview_files_queue_empty() then
          return
        end
        if last_job.job_id < self.preview_file_job_id then
          return
        end

        local lines = {}
        if strings.not_empty(file_content) then
          file_content = file_content:gsub("\r\n", "\n")
          lines = strings.split(file_content, "\n")
        end
        table.insert(self.preview_file_contents_queue, {
          lines = lines,
          previewer_result = last_job.previewer_result,
          previewer_label_result = last_job.previewer_label_result,
          job_id = last_job.job_id,
        })

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

          local last_contents = self:preview_file_contents_queue_last()
          self:preview_file_contents_queue_clear()
          if last_contents.job_id < self.preview_file_job_id then
            return
          end

          vim.api.nvim_buf_set_lines(self.previewer_bufnr, 0, -1, false, {})
          local set_name_ok, set_name_err = pcall(
            vim.api.nvim_buf_set_name,
            self.previewer_bufnr,
            last_contents.previewer_result.filename
          )
          if not set_name_ok then
            log.debug(
              "|BufferPopupWindow:preview_file.asyncreadfile| failed to set name for previewer buffer:%s(%s), error:%s",
              vim.inspect(last_contents.previewer_result.filename),
              vim.inspect(self.previewer_bufnr),
              vim.inspect(set_name_err)
            )
          end
          local buf_call_ok, buf_call_err = pcall(
            vim.api.nvim_buf_call,
            self.previewer_bufnr,
            function()
              vim.api.nvim_command([[filetype detect]])
            end
          )
          if not buf_call_ok then
            log.debug(
              "|BufferPopupWindow:preview_file.asyncreadfile| failed to detect filetype for previewer buffer:%s(%s), error:%s",
              vim.inspect(last_contents.previewer_result.filename),
              vim.inspect(self.previewer_bufnr),
              vim.inspect(buf_call_err)
            )
          end

          local TOTAL_LINES = #last_contents.lines
          local LINE_COUNT = 5
          local SHOW_PREVIEW_LABEL_COUNT = math.min(50, TOTAL_LINES)
          local line_index = 1
          local set_win_title_done = false

          local function set_win_title()
            if set_win_title_done then
              return
            end
            if strings.empty(last_contents.previewer_label_result) then
              return
            end
            if not self:is_valid() then
              return
            end
            if not self:preview_files_queue_empty() then
              return
            end
            if not self:preview_file_contents_queue_empty() then
              return
            end
            if last_contents.job_id < self.preview_file_job_id then
              return
            end

            local title_opts = {
              title = last_contents.previewer_label_result,
              title_pos = "center",
            }
            local set_config_ok, set_config_err = pcall(
              vim.api.nvim_win_set_config,
              self.previewer_winnr,
              title_opts
            )
            if not set_config_ok then
              log.debug(
                "|BufferPopupWindow:preview_file.asyncreadfile| failed to set title for previewer window:%s(%s), error:%s",
                vim.inspect(last_contents.previewer_result.filename),
                vim.inspect(self.previewer_winnr),
                vim.inspect(set_config_err)
              )
            end
            local set_opts_ok, set_opts_err =
              pcall(_set_default_previewer_win_options, self.previewer_winnr)
            if not set_opts_ok then
              log.debug(
                "|BufferPopupWindow:preview_file.asyncreadfile| failed to reset default opts for previewer window:%s(%s), error:%s",
                vim.inspect(last_contents.previewer_result.filename),
                vim.inspect(self.previewer_winnr),
                vim.inspect(set_opts_err)
              )
            end
            vim.schedule(function()
              set_win_title_done = true
            end)
          end

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
              if last_contents.job_id < self.preview_file_job_id then
                return
              end

              local buf_lines = {}
              for i = line_index, line_index + LINE_COUNT do
                if i <= TOTAL_LINES then
                  table.insert(buf_lines, last_contents.lines[i])
                else
                  break
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
              if line_index <= TOTAL_LINES then
                set_buf_lines()
              end
              if line_index >= SHOW_PREVIEW_LABEL_COUNT then
                vim.schedule(set_win_title)
              end
            end, 5)
          end
          set_buf_lines()
        end, 20)
      end
    )
  end, 30)
end

--- @param action_name string
function BufferPopupWindow:preview_action(action_name)
  local actions_map = {
    ["hide-preview"] = function() end,
    ["show-preview"] = function() end,
    ["refresh-preview"] = function() end,
    ["preview-down"] = function() end,
    ["preview-up"] = function() end,
    ["preview-page-down"] = function() end,
    ["preview-page-up"] = function() end,
    ["preview-half-page-down"] = function()
      self:preview_half_page_down()
    end,
    ["preview-half-page-up"] = function()
      self:preview_half_page_up()
    end,
    ["preview-bottom"] = function() end,
    ["toggle-preview"] = function() end,
    ["toggle-preview-wrap"] = function() end,
  }
end

--- @return boolean
function BufferPopupWindow:preview_hidden()
  local preview_win_confs = vim.api.nvim_win_get_config(self.previewer_winnr)
  return preview_win_confs.hide or false
end

function BufferPopupWindow:show_preview()
  log.debug("|BufferPopupWindow:show_preview|")
  if not self:is_valid() then
    log.debug("|BufferPopupWindow:show_preview| invalid")
    return
  end
  vim.api.nvim_win_set_config(self.previewer_winnr, { hide = false })
  _set_default_previewer_win_options(self.previewer_winnr)
  self:resize()
end

function BufferPopupWindow:hide_preview()
  log.debug("|BufferPopupWindow:hide_preview|")
  if not self:is_valid() then
    log.debug("|BufferPopupWindow:hide_preview| invalid")
    return
  end
  vim.api.nvim_win_set_config(self.previewer_winnr, { hide = true })
  self:set_preview_file_job_id(numbers.auto_incremental_id())
  self:resize()
end

function BufferPopupWindow:toggle_preview()
  log.debug("|BufferPopupWindow:toggle_preview|")
  if not self:is_valid() then
    log.debug("|BufferPopupWindow:toggle_preview| invalid")
    return
  end
  -- already hide, show it
  if self:preview_hidden() then
    self:show_preview()
  else
    -- not hide, hide it
    self:hide_preview()
  end
end

function BufferPopupWindow:preview_half_page_down()
  if not self:is_valid() then
    log.debug(
      "|BufferPopupWindow:preview_half_page_down| invalid: %s",
      vim.inspect(self.previewer_winnr)
    )
    return
  end
  vim.api.nvim_win_call(self.previewer_winnr, function()
    local ctrl_d = vim.api.nvim_replace_termcodes("<C-d>", true, false, true)
    vim.api.nvim_feedkeys(ctrl_d, "x", false)
  end)
  log.debug(
    "|BufferPopupWindow:preview_half_page_down| call - done: %s",
    vim.inspect(self.previewer_winnr)
  )
end

function BufferPopupWindow:preview_half_page_up()
  if not self:is_valid() then
    log.debug(
      "|BufferPopupWindow:preview_half_page_up| invalid: %s",
      vim.inspect(self.previewer_winnr)
    )
    return
  end
  vim.api.nvim_win_call(self.previewer_winnr, function()
    local ctrl_u = vim.api.nvim_replace_termcodes("<C-u>", true, false, true)
    vim.api.nvim_feedkeys(ctrl_u, "x", false)
  end)
  log.debug(
    "|BufferPopupWindow:preview_half_page_up| call - done: %s",
    vim.inspect(self.previewer_winnr)
  )
end

M.BufferPopupWindow = BufferPopupWindow

-- BufferPopupWindow }

return M
