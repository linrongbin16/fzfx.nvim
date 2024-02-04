---@diagnostic disable: missing-return
local numbers = require("fzfx.commons.numbers")
local apis = require("fzfx.commons.apis")
local fileios = require("fzfx.commons.fileios")
local tables = require("fzfx.commons.tables")
local strings = require("fzfx.commons.strings")

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
      + sign
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
      + sign
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

  local fzf_preview_window_opts = buffer_previewer_opts.fzf_preview_window_opts
  if
    fzf_preview_window_opts.position == "left"
    or fzf_preview_window_opts.position == "right"
  then
    width = width + 1
  elseif
    fzf_preview_window_opts.position == "up"
    or fzf_preview_window_opts.position == "down"
  then
    height = height + 1
  end

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
--- @field _saved_preview_files fzfx.BufferPopupWindowPreviewFiles
--- @field _saved_preview_file_contents fzfx.BufferPopupWindowPreviewFileContents
--- @field _resizing boolean
--- @field preview_files_queue fzfx.BufferPopupWindowPreviewFiles[]
--- @field preview_file_contents_queue fzfx.BufferPopupWindowPreviewFileContents[]
--- @field previewer_is_hidden boolean
--- @field _scrolling_preview_page boolean
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
  apis.set_win_option(winnr, "wrap", false)
  apis.set_win_option(winnr, "scrolloff", 0)
  apis.set_win_option(winnr, "sidescrolloff", 0)
end

local function _set_default_provider_win_options(winnr)
  apis.set_win_option(winnr, "number", false)
  apis.set_win_option(winnr, "spell", false)
  apis.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
  apis.set_win_option(winnr, "colorcolumn", "")
  apis.set_win_option(winnr, "wrap", false)
  apis.set_win_option(winnr, "scrolloff", 0)
  apis.set_win_option(winnr, "sidescrolloff", 0)
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

  local provider_win_confs =
    M.make_provider_opts(win_opts, buffer_previewer_opts)
  local previewer_win_confs =
    M.make_previewer_opts(win_opts, buffer_previewer_opts)
  previewer_win_confs.focusable = false

  local previewer_winnr =
    vim.api.nvim_open_win(previewer_bufnr, true, previewer_win_confs)
  _set_default_previewer_win_options(previewer_winnr)

  local provider_winnr =
    vim.api.nvim_open_win(provider_bufnr, true, provider_win_confs)
  _set_default_provider_win_options(provider_winnr)

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
    _saved_preview_file_contents = nil,
    _saved_preview_files = nil,
    _resizing = false,
    preview_files_queue = {},
    preview_file_contents_queue = {},
    previewer_is_hidden = false,
    _scrolling_preview_page = false,
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
  if not self:provider_is_valid() then
    return
  end

  self._resizing = true

  if self.previewer_is_hidden then
    local old_provider_win_confs =
      vim.api.nvim_win_get_config(self.provider_winnr)
    local provider_win_confs = M.make_provider_opts_with_hidden_previewer(
      self._saved_win_opts,
      self._saved_buffer_previewer_opts
    )
    log.debug(
      "|BufferPopupWindow:resize| is hidden, provider - old:%s, new:%s",
      vim.inspect(old_provider_win_confs),
      vim.inspect(provider_win_confs)
    )
    vim.api.nvim_win_set_config(
      self.provider_winnr,
      vim.tbl_deep_extend(
        "force",
        old_provider_win_confs,
        provider_win_confs or {}
      )
    )
    _set_default_provider_win_options(self.provider_winnr)
  else
    local old_provider_win_confs =
      vim.api.nvim_win_get_config(self.provider_winnr)
    local provider_win_confs = M.make_provider_opts(
      self._saved_win_opts,
      self._saved_buffer_previewer_opts
    )
    log.debug(
      "|BufferPopupWindow:resize| not hidden, provider - old:%s, new:%s",
      vim.inspect(old_provider_win_confs),
      vim.inspect(provider_win_confs)
    )
    vim.api.nvim_win_set_config(
      self.provider_winnr,
      vim.tbl_deep_extend(
        "force",
        old_provider_win_confs,
        provider_win_confs or {}
      )
    )
    _set_default_provider_win_options(self.provider_winnr)

    if self:previewer_is_valid() then
      local old_previewer_win_confs =
        vim.api.nvim_win_get_config(self.previewer_winnr)
      local previewer_win_confs = M.make_previewer_opts(
        self._saved_win_opts,
        self._saved_buffer_previewer_opts
      )
      log.debug(
        "|BufferPopupWindow:resize| not hidden, previewer - old:%s, new:%s",
        vim.inspect(old_previewer_win_confs),
        vim.inspect(previewer_win_confs)
      )
      vim.api.nvim_win_set_config(
        self.previewer_winnr,
        vim.tbl_deep_extend(
          "force",
          old_previewer_win_confs,
          previewer_win_confs or {}
        )
      )
      _set_default_previewer_win_options(self.previewer_winnr)
    end
  end

  vim.schedule(function()
    self._resizing = false
  end)
end

--- @return integer
function BufferPopupWindow:handle()
  return self.provider_winnr
end

function BufferPopupWindow:previewer_is_valid()
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

function BufferPopupWindow:provider_is_valid()
  if vim.in_fast_event() then
    return type(self.provider_winnr) == "number"
      and type(self.provider_bufnr) == "number"
  else
    return type(self.provider_winnr) == "number"
      and vim.api.nvim_win_is_valid(self.provider_winnr)
      and type(self.provider_bufnr) == "number"
      and vim.api.nvim_buf_is_valid(self.provider_bufnr)
  end
end

--- @alias fzfx.BufferPopupWindowPreviewFiles {previewer_result:fzfx.BufferFilePreviewerResult,previewer_label_result:string?}
--- @param previewer_result fzfx.BufferFilePreviewerResult
--- @param previewer_label_result string?
function BufferPopupWindow:preview_file(
  previewer_result,
  previewer_label_result
)
  if strings.empty(tables.tbl_get(previewer_result, "filename")) then
    log.debug(
      "|BufferPopupWindow:preview_file| empty previewer_result:%s",
      vim.inspect(previewer_result)
    )
    return
  end

  log.debug(
    "|BufferPopupWindow:preview_file| previewer_result:%s, previewer_label_result:%s",
    vim.inspect(previewer_result),
    vim.inspect(previewer_label_result)
  )
  table.insert(self.preview_files_queue, {
    previewer_result = previewer_result,
    previewer_label_result = previewer_label_result,
  })

  vim.defer_fn(function()
    if not self:previewer_is_valid() then
      log.debug(
        "|BufferPopupWindow:preview_file| invalid previewer:%s",
        vim.inspect(self)
      )
      return
    end
    if #self.preview_files_queue == 0 then
      log.debug(
        "|BufferPopupWindow:preview_file| empty preview files queue:%s",
        vim.inspect(self.preview_files_queue)
      )
      return
    end

    local last_job = self.preview_files_queue[#self.preview_files_queue]
    self.preview_files_queue = {}

    -- check if the same file
    if vim.deep_equal(last_job, self._saved_preview_files) then
      log.debug(
        "|BufferPopupWindow:preview_file| same preview file, last_job:%s, saved_job:%s",
        vim.inspect(last_job),
        vim.inspect(self._saved_preview_files)
      )
      return
    end

    self._saved_preview_files = last_job

    -- read file content
    fileios.asyncreadfile(
      last_job.previewer_result.filename,
      function(file_content)
        if not self:previewer_is_valid() then
          log.debug(
            "|BufferPopupWindow:preview_file - asyncreadfile| invalid previewer:%s",
            vim.inspect(self)
          )
          return
        end

        if strings.not_empty(file_content) then
          file_content = file_content:gsub("\r\n", "\n")
        end
        table.insert(self.preview_file_contents_queue, {
          contents = file_content,
          previewer_result = last_job.previewer_result,
          previewer_label_result = last_job.previewer_label_result,
        })

        -- show file contents by lines
        vim.defer_fn(function()
          if not self:previewer_is_valid() then
            log.debug(
              "|BufferPopupWindow:preview_file - asyncreadfile - done content| invalid previewer:%s",
              vim.inspect(self)
            )
            return
          end

          local last_content =
            self.preview_file_contents_queue[#self.preview_file_contents_queue]
          if
            vim.deep_equal(last_content, self._saved_preview_file_contents)
          then
            log.debug(
              "|BufferPopupWindow:preview_file - asyncreadfile - done content| same preview file contents, last_content:%s, saved content:%s",
              vim.inspect(last_content),
              vim.inspect(self._saved_preview_file_contents)
            )
            self.preview_file_contents_queue = {}
            return
          end

          self.preview_file_contents_queue = {}

          self._saved_preview_file_contents = last_content
          self:preview_file_contents(last_content)
        end, 30)
      end
    )
  end, 30)
end

--- @alias fzfx.BufferPopupWindowPreviewFileContents {contents:string,previewer_result:fzfx.BufferFilePreviewerResult,previewer_label_result:string?}
--- @param file_contents fzfx.BufferPopupWindowPreviewFileContents?
function BufferPopupWindow:preview_file_contents(file_contents)
  -- log.debug(
  --   "|BufferPopupWindow:preview_file_contents| file_contents:%s, empty:%s",
  --   vim.inspect(file_contents),
  --   vim.inspect(tables.tbl_empty(file_contents))
  -- )
  if tables.tbl_empty(file_contents) then
    return
  end

  local last_contents = file_contents --[[@as fzfx.BufferPopupWindowPreviewFileContents]]

  local current_buf_name = vim.api.nvim_buf_get_name(self.previewer_bufnr)
  if current_buf_name == last_contents.previewer_result.filename then
    return
  end

  -- local set_name_ok, set_name_err =
  pcall(
    vim.api.nvim_buf_set_name,
    self.previewer_bufnr,
    last_contents.previewer_result.filename
  )
  -- if not set_name_ok then
  --   log.debug(
  --     "|BufferPopupWindow:preview_file - asyncreadfile| failed to set name for previewer buffer:%s(%s), error:%s",
  --     vim.inspect(last_contents.previewer_result.filename),
  --     vim.inspect(self.previewer_bufnr),
  --     vim.inspect(set_name_err)
  --   )
  -- end
  -- local buf_call_ok, buf_call_err =
  vim.api.nvim_buf_call(self.previewer_bufnr, function()
    vim.api.nvim_command([[filetype detect]])
  end)
  -- if not buf_call_ok then
  --   log.debug(
  --     "|BufferPopupWindow:preview_file - asyncreadfile| failed to detect filetype for previewer buffer:%s(%s), error:%s",
  --     vim.inspect(last_contents.previewer_result.filename),
  --     vim.inspect(self.previewer_bufnr),
  --     vim.inspect(buf_call_err)
  --   )
  -- end
  -- local set_cursor_ok, set_cursor_err =
  vim.api.nvim_win_set_cursor(self.previewer_winnr, { 1, 0 })
  -- if not set_cursor_ok then
  --   log.debug(
  --     "|BufferPopupWindow:preview_file - asyncreadfile| failed to set cursor at top of file for previewer buffer:%s(%s), error: %s",
  --     vim.inspect(last_contents.previewer_result.filename),
  --     vim.inspect(self.previewer_bufnr),
  --     vim.inspect(set_cursor_err)
  --   )
  -- end

  local LINES = strings.split(last_contents.contents, "\n")
  local TOTAL_LINES = #LINES
  local SHOW_PREVIEW_LABEL_COUNT = math.min(50, TOTAL_LINES)
  local line_index = 1
  local line_count = 5
  local set_win_title_done = false

  local function set_win_title()
    if set_win_title_done then
      return
    end
    if strings.empty(last_contents.previewer_label_result) then
      return
    end
    if not self:previewer_is_valid() then
      return
    end

    local title_opts = {
      title = last_contents.previewer_label_result,
      title_pos = "center",
    }
    -- local set_config_ok, set_config_err =
    vim.api.nvim_win_set_config(self.previewer_winnr, title_opts)
    -- if not set_config_ok then
    --   log.debug(
    --     "|BufferPopupWindow:preview_file.asyncreadfile| failed to set title for previewer window:%s(%s), error:%s",
    --     vim.inspect(last_contents.previewer_result.filename),
    --     vim.inspect(self.previewer_winnr),
    --     vim.inspect(set_config_err)
    --   )
    -- end
    -- local set_opts_ok, set_opts_err =
    -- pcall(_set_default_previewer_win_options, self.previewer_winnr)
    apis.set_win_option(self.previewer_winnr, "number", true)
    -- if not set_opts_ok then
    --   log.debug(
    --     "|BufferPopupWindow:preview_file.asyncreadfile| failed to reset default opts for previewer window:%s(%s), error:%s",
    --     vim.inspect(last_contents.previewer_result.filename),
    --     vim.inspect(self.previewer_winnr),
    --     vim.inspect(set_opts_err)
    --   )
    -- end
    vim.schedule(function()
      set_win_title_done = true
    end)
  end

  local function set_buf_lines()
    -- log.debug("|BufferPopupWindow:preview_file_contents| set_buf_lines")
    vim.defer_fn(function()
      if not self:previewer_is_valid() then
        -- log.debug(
        --   "|BufferPopupWindow:preview_file_contents| set_buf_lines, previewer_is_valid:%s",
        --   vim.inspect(self:previewer_is_valid())
        -- )
        return
      end

      local buf_lines = {}
      for i = line_index, line_index + line_count do
        if i <= TOTAL_LINES then
          table.insert(buf_lines, LINES[i])
        else
          break
        end
      end
      vim.api.nvim_buf_set_lines(
        self.previewer_bufnr,
        line_index - 1,
        line_index - 1 + line_count,
        false,
        buf_lines
      )
      line_index = line_index + line_count
      if line_index <= TOTAL_LINES then
        line_count = line_count + 5
        set_buf_lines()
      else
        vim.api.nvim_buf_set_lines(
          self.previewer_bufnr,
          TOTAL_LINES,
          -1,
          false,
          {}
        )
      end
      if line_index >= SHOW_PREVIEW_LABEL_COUNT then
        vim.schedule(set_win_title)
      end
    end, 3)
  end
  set_buf_lines()
end

--- @param action_name string
function BufferPopupWindow:preview_action(action_name)
  local actions_map = {
    ["hide-preview"] = function()
      self:hide_preview()
    end,
    ["show-preview"] = function()
      self:show_preview()
    end,
    ["refresh-preview"] = function() end,
    ["preview-down"] = function()
      self:preview_page_down()
    end,
    ["preview-up"] = function()
      self:preview_page_up()
    end,
    ["preview-page-down"] = function()
      self:preview_page_down()
    end,
    ["preview-page-up"] = function()
      self:preview_page_up()
    end,
    ["preview-half-page-down"] = function()
      self:preview_half_page_down()
    end,
    ["preview-half-page-up"] = function()
      self:preview_half_page_up()
    end,
    ["preview-bottom"] = function() end,
    ["toggle-preview"] = function()
      self:toggle_preview()
    end,
    ["toggle-preview-wrap"] = function()
      self:toggle_preview()
    end,
  }

  local action = actions_map[action_name]
  if vim.is_callable(action) then
    action()
  end
end

function BufferPopupWindow:show_preview()
  if not self.previewer_is_hidden then
    -- log.debug("|BufferPopupWindow:show_preview| already show")
    return
  end
  if not self:provider_is_valid() then
    -- log.debug("|BufferPopupWindow:show_preview| invalid")
    return
  end

  self.previewer_is_hidden = false
  local previewer_win_confs = M.make_previewer_opts(
    self._saved_win_opts,
    self._saved_buffer_previewer_opts
  )
  previewer_win_confs.focusable = false

  self.previewer_bufnr = vim.api.nvim_create_buf(false, true)
  _set_default_buf_options(self.previewer_bufnr)
  self.previewer_winnr =
    vim.api.nvim_open_win(self.previewer_bufnr, true, previewer_win_confs)
  vim.api.nvim_set_current_win(self.provider_winnr)

  self:resize()

  -- restore last file preview contents
  vim.schedule(function()
    -- log.debug(
    --   "|BufferPopupWindow:show_preview| restore file preview contents, saved:%s, not empty:%s",
    --   vim.inspect(self._saved_preview_file_contents),
    --   vim.inspect(tables.tbl_not_empty(self._saved_preview_file_contents))
    -- )
    if tables.tbl_not_empty(self._saved_preview_file_contents) then
      self:preview_file_contents(self._saved_preview_file_contents)
    end
  end)
end

function BufferPopupWindow:hide_preview()
  if self.previewer_is_hidden then
    -- log.debug("|BufferPopupWindow:hide_preview| already hidden")
    return
  end
  if not self:provider_is_valid() then
    -- log.debug("|BufferPopupWindow:show_preview| invalid provider")
    return
  end
  if not self:previewer_is_valid() then
    -- log.debug("|BufferPopupWindow:hide_preview| invalid previewer")
    return
  end

  self.previewer_is_hidden = true
  vim.api.nvim_win_close(self.previewer_winnr, true)
  self:resize()
end

function BufferPopupWindow:toggle_preview()
  -- log.debug(
  --   "|BufferPopupWindow:toggle_preview| previewer_is_hidden:%s",
  --   vim.inspect(self.previewer_is_hidden)
  -- )
  -- already hide, show it
  if self.previewer_is_hidden then
    self:show_preview()
  else
    -- not hide, hide it
    self:hide_preview()
  end
end

-- scroll page up by percentage (1% - 100%)
--- @param percent integer  1-100
--- @param up boolean
function BufferPopupWindow:scroll_by(percent, up)
  if not self:previewer_is_valid() then
    return
  end
  if self._scrolling_preview_page then
    return
  end

  self._scrolling_preview_page = true
  local down = not up

  local function before_exit()
    vim.schedule(function()
      self._scrolling_preview_page = false
    end)
  end

  local base_lineno = up and vim.fn.line("w0", self.previewer_winnr)
    or vim.fn.line("w$", self.previewer_winnr)
  if base_lineno == 1 and up then
    before_exit()
    return
  end
  local buf_lines = vim.api.nvim_buf_line_count(self.previewer_bufnr)
  if base_lineno >= buf_lines and down then
    before_exit()
    return
  end

  local win_height =
    math.max(vim.api.nvim_win_get_height(self.previewer_winnr), 1)
  local diff_lines = math.max(math.floor(win_height / 100 * percent), 0)
  if up then
    diff_lines = -diff_lines
  end
  local target_lineno = numbers.bound(base_lineno + diff_lines, 1, buf_lines)
  log.debug(
    "|scroll_by| percent:%s, up:%s, win_height:%s, buf_lines:%s, cursor_lineno:%s, diff_lines:%s, target_lineno:%s",
    vim.inspect(percent),
    vim.inspect(up),
    vim.inspect(win_height),
    vim.inspect(buf_lines),
    vim.inspect(base_lineno),
    vim.inspect(diff_lines),
    vim.inspect(target_lineno)
  )
  vim.api.nvim_win_set_cursor(self.previewer_winnr, { target_lineno, 0 })

  before_exit()
end

function BufferPopupWindow:preview_page_down()
  if not self:previewer_is_valid() then
    return
  end

  self:scroll_by(100, false)
end

function BufferPopupWindow:preview_page_up()
  if not self:previewer_is_valid() then
    return
  end

  self:scroll_by(100, true)
end

function BufferPopupWindow:preview_half_page_down()
  if not self:previewer_is_valid() then
    return
  end

  self:scroll_by(50, false)
end

function BufferPopupWindow:preview_half_page_up()
  if not self:previewer_is_valid() then
    return
  end

  self:scroll_by(50, true)
end

M.BufferPopupWindow = BufferPopupWindow

-- BufferPopupWindow }

return M
