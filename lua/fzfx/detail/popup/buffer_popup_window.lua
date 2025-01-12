local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local num = require("fzfx.commons.num")
local fio = require("fzfx.commons.fio")

local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")
local popup_helpers = require("fzfx.detail.popup.popup_helpers")
local buffer_popup_window_helpers = require("fzfx.detail.popup.buffer_popup_window_helpers")

local M = {}

--- @return integer
local function minimal_line_step()
  return math.max(30, vim.o.lines)
end

--- @alias fzfx.BufferPreviewerOpts  {fzf_preview_window_opts:fzfx.FzfPreviewWindowOpts,fzf_border_opts:string}
--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferPreviewerOpts
--- @param relative_winnr integer
--- @param relative_win_first_line integer
--- @return {provider:fzfx.NvimFloatWinOpts,previewer:fzfx.NvimFloatWinOpts}
M._make_cursor_opts = function(
  win_opts,
  buffer_previewer_opts,
  relative_winnr,
  relative_win_first_line
)
  win_opts = vim.deepcopy(win_opts)
  buffer_previewer_opts = vim.deepcopy(buffer_previewer_opts)

  local relative = "win"
  local layout = popup_helpers.make_cursor_layout(
    relative_winnr,
    relative_win_first_line,
    win_opts,
    buffer_previewer_opts.fzf_preview_window_opts
  )
  log.debug("|_make_cursor_opts| layout:" .. vim.inspect(layout))
  local provider_border = fzf_helpers.FZF_BORDER_OPTS_MAP[buffer_previewer_opts.fzf_border_opts]
    or fzf_helpers.FZF_DEFAULT_BORDER_OPTS
  local previewer_border = fzf_helpers.FZF_BORDER_OPTS_MAP[buffer_previewer_opts.fzf_preview_window_opts.border]
    or fzf_helpers.FZF_DEFAULT_BORDER_OPTS

  local result = {
    anchor = "NW",
    relative = relative,
    width = layout.width,
    height = layout.height,
    row = layout.start_row,
    col = layout.start_col,
    style = popup_helpers.FLOAT_WIN_STYLE,
    border = provider_border,
    zindex = popup_helpers.FLOAT_WIN_ZINDEX,
  }
  result.provider = {
    anchor = "NW",
    relative = relative,
    width = layout.provider.width,
    height = layout.provider.height,
    row = layout.provider.start_row,
    col = layout.provider.start_col,
    style = popup_helpers.FLOAT_WIN_STYLE,
    border = provider_border,
    zindex = popup_helpers.FLOAT_WIN_ZINDEX,
  }
  result.previewer = {
    anchor = "NW",
    relative = relative,
    width = layout.previewer.width,
    height = layout.previewer.height,
    row = layout.previewer.start_row,
    col = layout.previewer.start_col,
    style = popup_helpers.FLOAT_WIN_STYLE,
    border = previewer_border,
    zindex = popup_helpers.FLOAT_WIN_ZINDEX,
    focusable = false,
  }

  if relative == "win" then
    result.provider.win = relative_winnr
    result.previewer.win = relative_winnr
  end
  log.debug("|_make_cursor_opts| result:" .. vim.inspect(result))
  return result
end

--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferPreviewerOpts
--- @param relative_winnr integer
--- @param relative_win_first_line integer
--- @return {provider:fzfx.NvimFloatWinOpts,previewer:fzfx.NvimFloatWinOpts}
M._make_center_opts = function(
  win_opts,
  buffer_previewer_opts,
  relative_winnr,
  relative_win_first_line
)
  win_opts = vim.deepcopy(win_opts)
  buffer_previewer_opts = vim.deepcopy(buffer_previewer_opts)

  win_opts.relative = win_opts.relative or "editor"
  assert(win_opts.relative == "win" or win_opts.relative == "editor")

  local layout = popup_helpers.make_center_layout(
    relative_winnr,
    relative_win_first_line,
    win_opts,
    buffer_previewer_opts.fzf_preview_window_opts
  )
  local provider_border = fzf_helpers.FZF_BORDER_OPTS_MAP[buffer_previewer_opts.fzf_border_opts]
    or fzf_helpers.FZF_DEFAULT_BORDER_OPTS
  local previewer_border = fzf_helpers.FZF_BORDER_OPTS_MAP[buffer_previewer_opts.fzf_preview_window_opts.border]
    or fzf_helpers.FZF_DEFAULT_BORDER_OPTS

  local result = {
    anchor = "NW",
    relative = win_opts.relative,
    width = layout.width,
    height = layout.height,
    row = layout.start_row,
    col = layout.start_col,
    style = popup_helpers.FLOAT_WIN_STYLE,
    border = provider_border,
    zindex = popup_helpers.FLOAT_WIN_ZINDEX,
  }
  result.provider = {
    anchor = "NW",
    relative = win_opts.relative,
    width = layout.provider.width,
    height = layout.provider.height,
    row = layout.provider.start_row,
    col = layout.provider.start_col,
    style = popup_helpers.FLOAT_WIN_STYLE,
    border = provider_border,
    zindex = popup_helpers.FLOAT_WIN_ZINDEX,
  }
  result.previewer = {
    anchor = "NW",
    relative = win_opts.relative,
    width = layout.previewer.width,
    height = layout.previewer.height,
    row = layout.previewer.start_row,
    col = layout.previewer.start_col,
    style = popup_helpers.FLOAT_WIN_STYLE,
    border = previewer_border,
    zindex = popup_helpers.FLOAT_WIN_ZINDEX,
    focusable = false,
  }

  if win_opts.relative == "win" then
    result.provider.win = relative_winnr
    result.previewer.win = relative_winnr
  end
  return result
end

--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferPreviewerOpts
--- @param relative_winnr integer
--- @param relative_win_first_line integer
--- @return {provider:fzfx.NvimFloatWinOpts,previewer:fzfx.NvimFloatWinOpts}
M.make_opts = function(win_opts, buffer_previewer_opts, relative_winnr, relative_win_first_line)
  win_opts = vim.deepcopy(win_opts)
  buffer_previewer_opts = vim.deepcopy(buffer_previewer_opts)

  win_opts.relative = win_opts.relative or "editor"

  log.ensure(
    win_opts.relative == "cursor" or win_opts.relative == "editor" or win_opts.relative == "win",
    string.format("window relative (%s) must be editor/win/cursor", vim.inspect(win_opts))
  )
  return win_opts.relative == "cursor"
      and M._make_cursor_opts(
        win_opts,
        buffer_previewer_opts,
        relative_winnr,
        relative_win_first_line
      )
    or M._make_center_opts(win_opts, buffer_previewer_opts, relative_winnr, relative_win_first_line)
end

-- BufferPopupWindow {

--- @class fzfx.BufferPopupWindow
--- @field saved_win_ctx fzfx.WindowContext?
--- @field provider_bufnr integer?
--- @field provider_winnr integer?
--- @field previewer_bufnr integer?
--- @field previewer_winnr integer?
--- @field _saved_current_winnr integer
--- @field _saved_current_win_first_line integer
--- @field _saved_win_opts fzfx.WindowOpts
--- @field _saved_buffer_previewer_opts fzfx.BufferPreviewerOpts
--- @field _saved_previewing_file_content_job fzfx.BufferPopupWindowPreviewFileContentJob
--- @field _saved_previewing_file_content_view fzfx.BufferPopupWindowPreviewFileContentView
--- @field _current_previewing_file_job_id integer?
--- @field _rendering boolean
--- @field _resizing boolean
--- @field _scrolling boolean
--- @field preview_files_queue fzfx.BufferPopupWindowPreviewFileJob[]
--- @field preview_file_contents_queue fzfx.BufferPopupWindowPreviewFileContentJob[]
--- @field previewer_is_hidden boolean
local BufferPopupWindow = {}

--- @param bufnr integer
local function _set_previewer_buf_opts(bufnr)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
  vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })
  -- vim.api.nvim_set_option_value("filetype", "fzf", { buf = bufnr })
end

--- @param winnr integer
--- @param wrap boolean
--- @param current_winnr integer
local function _set_previewer_win_opts(winnr, wrap, current_winnr)
  local number_opt = vim.api.nvim_get_option_value("number", { win = current_winnr })
  vim.api.nvim_set_option_value("number", number_opt, { win = winnr })
  vim.api.nvim_set_option_value("spell", false, { win = winnr })
  vim.api.nvim_set_option_value("winhighlight", "Pmenu:,Normal:Normal", { win = winnr })
  -- apis.set_win_option(winnr, "scrolloff", 0)
  -- apis.set_win_option(winnr, "sidescrolloff", 0)
  vim.api.nvim_set_option_value("foldenable", false, { win = winnr })
  vim.api.nvim_set_option_value("wrap", wrap, { win = winnr })
end

--- @param bufnr integer
local function _set_provider_buf_opts(bufnr)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
  vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })
  vim.api.nvim_set_option_value("filetype", "fzf", { buf = bufnr })
end

--- @param winnr integer
--- @param current_winnr integer
local function _set_provider_win_opts(winnr, current_winnr)
  vim.api.nvim_set_option_value("number", false, { win = winnr })
  vim.api.nvim_set_option_value("spell", false, { win = winnr })
  vim.api.nvim_set_option_value("winhighlight", "Pmenu:,Normal:Normal", { win = winnr })
  vim.api.nvim_set_option_value("colorcolumn", "", { win = winnr })
  -- apis.set_win_option(winnr, "scrolloff", 0)
  -- apis.set_win_option(winnr, "sidescrolloff", 0)
  vim.api.nvim_set_option_value("foldenable", false, { win = winnr })
end

--- @package
--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferPreviewerOpts
--- @return fzfx.BufferPopupWindow
function BufferPopupWindow:new(win_opts, buffer_previewer_opts)
  local current_winnr = vim.api.nvim_get_current_win()
  local current_win_first_line = vim.fn.line("w0")

  -- save current window context
  local saved_win_ctx = popup_helpers.WindowContext:save()

  local provider_bufnr = vim.api.nvim_create_buf(false, true) --[[@as integer]]
  log.ensure(provider_bufnr > 0, "failed to create provider buf")
  _set_provider_buf_opts(provider_bufnr)

  local previewer_bufnr --[[@as integer]]
  if not buffer_previewer_opts.fzf_preview_window_opts.hidden then
    previewer_bufnr = vim.api.nvim_create_buf(false, true)
    log.ensure(previewer_bufnr > 0, "failed to create previewer buf")
    _set_previewer_buf_opts(previewer_bufnr)
  end

  local win_confs =
    M.make_opts(win_opts, buffer_previewer_opts, current_winnr, current_win_first_line)

  local provider_win_confs
  local previewer_win_confs
  if not buffer_previewer_opts.fzf_preview_window_opts.hidden then
    provider_win_confs = win_confs.provider
    previewer_win_confs = win_confs.previewer
  else
    provider_win_confs = vim.deepcopy(win_confs)
    provider_win_confs.provider = nil
    provider_win_confs.previewer = nil
  end

  local previewer_winnr --[[@as integer]]
  if previewer_bufnr then
    previewer_winnr = vim.api.nvim_open_win(previewer_bufnr, true, previewer_win_confs) --[[@as integer]]
    log.ensure(previewer_winnr > 0, "failed to create previewer win")
    local wrap = buffer_previewer_opts.fzf_preview_window_opts.wrap
    _set_previewer_win_opts(previewer_winnr, wrap, current_winnr)
  end

  local provider_winnr = vim.api.nvim_open_win(provider_bufnr, true, provider_win_confs) --[[@as integer]]
  log.ensure(provider_winnr > 0, "failed to create provider win")
  _set_provider_win_opts(provider_winnr, current_winnr)

  -- set cursor at provider window
  vim.api.nvim_set_current_win(provider_winnr)

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = provider_bufnr,
    nested = true,
    callback = function()
      -- log.debug("|BufferPopupWindow:new| enter provider buffer")
      vim.cmd("startinsert")
    end,
  })

  local o = {
    saved_win_ctx = saved_win_ctx,
    provider_bufnr = provider_bufnr,
    provider_winnr = provider_winnr,
    previewer_bufnr = previewer_bufnr,
    previewer_winnr = previewer_winnr,
    _saved_current_winnr = current_winnr,
    _saved_current_win_first_line = current_win_first_line,
    _saved_win_opts = win_opts,
    _saved_buffer_previewer_opts = buffer_previewer_opts,
    _saved_previewing_file_content_job = nil,
    _saved_previewing_file_content_view = nil,
    _current_previewing_file_job_id = nil,
    _rendering = false,
    _scrolling = false,
    _resizing = false,
    preview_files_queue = {},
    preview_file_contents_queue = {},
    previewer_is_hidden = buffer_previewer_opts.fzf_preview_window_opts.hidden,
  }
  setmetatable(o, self)
  self.__index = self

  return o
end

function BufferPopupWindow:close()
  -- log.debug(
  --   string.format(
  --     "|BufferPopupWindow:close| provider_winnr:%s, previewer_winnr:%s",
  --     vim.inspect(self.provider_winnr),
  --     vim.inspect(self.previewer_winnr)
  --   )
  -- )

  -- Clean up windows.
  if type(self.provider_winnr) == "number" and vim.api.nvim_win_is_valid(self.provider_winnr) then
    vim.api.nvim_win_close(self.provider_winnr, true)
  end
  if type(self.previewer_winnr) == "number" and vim.api.nvim_win_is_valid(self.previewer_winnr) then
    vim.api.nvim_win_close(self.previewer_winnr, true)
  end
  self.provider_winnr = nil
  self.previewer_winnr = nil

  -- Clean up buffers.
  if type(self.provider_bufnr) == "number" and vim.api.nvim_buf_is_valid(self.provider_bufnr) then
    vim.api.nvim_buf_delete(self.provider_bufnr, { force = true })
  end
  if type(self.previewer_bufnr) == "number" and vim.api.nvim_buf_is_valid(self.previewer_bufnr) then
    vim.api.nvim_buf_delete(self.previewer_bufnr, { force = true })
  end
  self.provider_bufnr = nil
  self.previewer_bufnr = nil

  -- Restore window context.
  self.saved_win_ctx:restore()
end

function BufferPopupWindow:is_resizing()
  return self._resizing
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
    local old_win_confs = vim.api.nvim_win_get_config(self.provider_winnr)
    local new_win_confs = M.make_opts(
      self._saved_win_opts,
      self._saved_buffer_previewer_opts,
      self._saved_current_winnr,
      self._saved_current_win_first_line
    )
    new_win_confs.provider = nil
    new_win_confs.previewer = nil
    vim.api.nvim_win_set_config(
      self.provider_winnr,
      vim.tbl_deep_extend("force", old_win_confs, new_win_confs)
    )
    _set_provider_win_opts(self.provider_winnr, self._saved_current_winnr)
  else
    local old_provider_win_confs = vim.api.nvim_win_get_config(self.provider_winnr)
    local win_confs = M.make_opts(
      self._saved_win_opts,
      self._saved_buffer_previewer_opts,
      self._saved_current_winnr,
      self._saved_current_win_first_line
    )
    vim.api.nvim_win_set_config(
      self.provider_winnr,
      vim.tbl_deep_extend("force", old_provider_win_confs, win_confs.provider or {})
    )
    _set_provider_win_opts(self.provider_winnr, self._saved_current_winnr)

    if self:previewer_is_valid() then
      local old_previewer_win_confs = vim.api.nvim_win_get_config(self.previewer_winnr)
      vim.api.nvim_win_set_config(
        self.previewer_winnr,
        vim.tbl_deep_extend("force", old_previewer_win_confs, win_confs.previewer or {})
      )

      local wrap = self._saved_buffer_previewer_opts.fzf_preview_window_opts.wrap
      _set_previewer_win_opts(self.previewer_winnr, wrap, self._saved_current_winnr)
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
    return type(self.previewer_winnr) == "number" and type(self.previewer_bufnr) == "number"
  else
    return type(self.previewer_winnr) == "number"
      and vim.api.nvim_win_is_valid(self.previewer_winnr)
      and type(self.previewer_bufnr) == "number"
      and vim.api.nvim_buf_is_valid(self.previewer_bufnr)
  end
end

function BufferPopupWindow:provider_is_valid()
  if vim.in_fast_event() then
    return type(self.provider_winnr) == "number" and type(self.provider_bufnr) == "number"
  else
    return type(self.provider_winnr) == "number"
      and vim.api.nvim_win_is_valid(self.provider_winnr)
      and type(self.provider_bufnr) == "number"
      and vim.api.nvim_buf_is_valid(self.provider_bufnr)
  end
end

--- @param jobid integer
--- @return boolean
function BufferPopupWindow:is_last_previewing_file_job_id(jobid)
  return self._current_previewing_file_job_id == jobid
end

--- @param jobid integer
function BufferPopupWindow:set_current_previewing_file_job_id(jobid)
  self._current_previewing_file_job_id = jobid
end

-- make a view based on preview file content
--- @param preview_file_content fzfx.BufferPopupWindowPreviewFileContentJob
--- @return fzfx.BufferPopupWindowPreviewFileContentView
function BufferPopupWindow:_make_view(preview_file_content)
  log.ensure(preview_file_content ~= nil, "|_make_view| preview_file_content must not be nil")
  log.ensure(self:previewer_is_valid(), "|_make_view| previewer must be valid")
  local center_line = preview_file_content.previewer_result.lineno
  local lines_count = #preview_file_content.contents
  local win_height = vim.api.nvim_win_get_height(self.previewer_winnr)
  local view = center_line
      and buffer_popup_window_helpers.make_center_view(lines_count, win_height, center_line)
    or buffer_popup_window_helpers.make_top_view(lines_count, win_height)
  -- log.debug(
  --   string.format(
  --     "|BufferPopupWindow:_make_view| center_line:%s, lines_count:%s, win_height:%s, view:%s",
  --     vim.inspect(center_line),
  --     vim.inspect(lines_count),
  --     vim.inspect(win_height),
  --     vim.inspect(view)
  --   )
  -- )
  return view
end

--- @alias fzfx.BufferPopupWindowPreviewFileJob {job_id:integer,previewer_result:fzfx.BufferPreviewerResult ,previewer_label_result:string?}
--- @param job_id integer
--- @param previewer_result fzfx.BufferPreviewerResult
--- @param previewer_label_result string?
function BufferPopupWindow:preview_file(job_id, previewer_result, previewer_label_result)
  if str.empty(tbl.tbl_get(previewer_result, "filename")) then
    -- log.debug(
    --   "|BufferPopupWindow:preview_file| empty previewer_result:%s",
    --   vim.inspect(previewer_result)
    -- )
    return
  end

  -- log.debug(
  --   string.format(
  --     "|BufferPopupWindow:preview_file| previewer_result:%s, previewer_label_result:%s",
  --     vim.inspect(previewer_result),
  --     vim.inspect(previewer_label_result)
  --   )
  -- )
  table.insert(self.preview_files_queue, {
    job_id = job_id,
    previewer_result = previewer_result,
    previewer_label_result = previewer_label_result,
  })

  vim.defer_fn(function()
    if #self.preview_files_queue == 0 then
      -- log.debug(
      --   "|BufferPopupWindow:preview_file| empty preview files queue:%s",
      --   vim.inspect(self.preview_files_queue)
      -- )
      return
    end

    local last_job = self.preview_files_queue[#self.preview_files_queue]
    self.preview_files_queue = {}

    -- check if the last job
    if not self:is_last_previewing_file_job_id(last_job.job_id) then
      return
    end

    local function async_read_file_handler(contents)
      if not self:is_last_previewing_file_job_id(last_job.job_id) then
        return
      end

      -- log.debug(
      --   string.format(
      --     "|BufferPopupWindow:preview_file - asyncreadfile| contents:%s",
      --     vim.inspect(contents)
      --   )
      -- )
      -- log.debug(
      --   string.format(
      --     "|BufferPopupWindow:preview_file - asyncreadfile| contents length:%s",
      --     vim.inspect(string.len(contents))
      --   )
      -- )
      local lines = {}
      if str.not_empty(contents) then
        contents = contents:gsub("\r\n", "\n")
        lines = str.split(contents, "\n")
        if str.endswith(contents, "\n") and #lines > 0 and lines[#lines] == "" then
          table.remove(lines, #lines)
        end
      end
      -- log.debug(
      --   string.format(
      --     "|BufferPopupWindow:preview_file - asyncreadfile| lines:%s",
      --     vim.inspect(lines)
      --   )
      -- )
      -- log.debug(
      --   string.format(
      --     "|BufferPopupWindow:preview_file - asyncreadfile| lines count:%s",
      --     vim.inspect(#lines)
      --   )
      -- )
      table.insert(self.preview_file_contents_queue, {
        contents = lines,
        job_id = last_job.job_id,
        previewer_result = last_job.previewer_result,
        previewer_label_result = last_job.previewer_label_result,
      })

      -- show file contents by lines
      vim.defer_fn(function()
        local last_content = self.preview_file_contents_queue[#self.preview_file_contents_queue]
        self.preview_file_contents_queue = {}
        self._saved_previewing_file_content_job = last_content

        if not self:is_last_previewing_file_job_id(last_content.job_id) then
          return
        end
        if not self:previewer_is_valid() then
          return
        end
        local view = self:_make_view(last_content)
        self:preview_file_contents(last_content, view)
      end, 10)
    end

    -- read file content
    fio.asyncreadfile(last_job.previewer_result.filename, {
      on_complete = async_read_file_handler,
      on_error = function()
        -- When failed to open/read the file, simply treats it as an empty file with empty text contents.
        async_read_file_handler("")
      end,
    })
  end, 20)
end

--- @alias fzfx.BufferPopupWindowPreviewFileContentJob {contents:string[],job_id:integer,previewer_result:fzfx.BufferPreviewerResult ,previewer_label_result:string?}
--- @param file_content fzfx.BufferPopupWindowPreviewFileContentJob
--- @param content_view fzfx.BufferPopupWindowPreviewFileContentView
--- @param on_complete (fun(done:boolean):any)|nil
function BufferPopupWindow:preview_file_contents(file_content, content_view, on_complete)
  local function do_complete(done)
    if type(on_complete) == "function" then
      on_complete(done)
    end
  end

  if tbl.tbl_empty(file_content) then
    do_complete(false)
    return
  end

  local file_type = vim.filetype.match({ filename = file_content.previewer_result.filename }) or ""
  vim.api.nvim_set_option_value("filetype", file_type, { buf = self.previewer_bufnr })

  vim.defer_fn(function()
    if not self:previewer_is_valid() then
      do_complete(false)
      return
    end
    if not self:is_last_previewing_file_job_id(file_content.job_id) then
      do_complete(false)
      return
    end

    local function set_win_title()
      if not self:previewer_is_valid() then
        return
      end
      if not self:is_last_previewing_file_job_id(file_content.job_id) then
        return
      end

      local title_opts = {
        title = file_content.previewer_label_result,
        title_pos = "center",
      }
      vim.api.nvim_win_set_config(self.previewer_winnr, title_opts)
      local wrap = self._saved_buffer_previewer_opts.fzf_preview_window_opts.wrap
      _set_previewer_win_opts(self.previewer_winnr, wrap, self._saved_current_winnr)
    end

    if str.not_empty(file_content.previewer_label_result) then
      vim.defer_fn(set_win_title, 100)
    end

    self:render_file_contents(file_content, content_view, on_complete)
  end, 10)
end

--- @param file_content fzfx.BufferPopupWindowPreviewFileContentJob
--- @param content_view fzfx.BufferPopupWindowPreviewFileContentView
--- @param on_complete (fun(done:boolean):any)|nil
--- @param line_step integer?
function BufferPopupWindow:render_file_contents(file_content, content_view, on_complete, line_step)
  local function do_complete(done)
    if type(on_complete) == "function" then
      on_complete(done)
    end
  end

  if tbl.tbl_empty(file_content) then
    do_complete(false)
    return
  end
  if self._rendering then
    do_complete(false)
    return
  end

  local function falsy_rendering()
    vim.schedule(function()
      self._rendering = false
    end)
  end

  self._rendering = true

  vim.defer_fn(function()
    if not self:previewer_is_valid() then
      do_complete(false)
      falsy_rendering()
      return
    end
    if not self:is_last_previewing_file_job_id(file_content.job_id) then
      do_complete(false)
      falsy_rendering()
      return
    end

    local extmark_ns = vim.api.nvim_create_namespace("fzfx-buffer-previewer")
    local old_extmarks = vim.api.nvim_buf_get_extmarks(
      self.previewer_bufnr,
      extmark_ns,
      { 0, 0 },
      { -1, -1 },
      {}
    )
    if tbl.list_not_empty(old_extmarks) then
      for i, m in ipairs(old_extmarks) do
        pcall(vim.api.nvim_buf_del_extmark, self.previewer_bufnr, extmark_ns, m[1])
      end
    end

    local LINES = file_content.contents
    local LINES_COUNT = #LINES
    local IS_LARGE_FILE = LINES_COUNT > 500
    local FIRST_LINE = 1
    local LAST_LINE = LINES_COUNT
    local line_index = FIRST_LINE
    if line_step == nil then
      line_step = math.max(math.ceil(math.sqrt(LINES_COUNT)), minimal_line_step())
    end
    -- log.debug(
    --   string.format(
    --     "|BufferPopupWindow:render_file_contents| LINES_COUNT:%s, FIRST/LAST:%s/%s, content_view:%s",
    --     vim.inspect(LINES_COUNT),
    --     vim.inspect(FIRST_LINE),
    --     vim.inspect(LAST_LINE),
    --     vim.inspect(content_view)
    --   )
    -- )

    -- local lines_been_cleared = false

    local function set_buf_lines()
      vim.defer_fn(function()
        if not self:previewer_is_valid() then
          do_complete(false)
          falsy_rendering()
          return
        end
        if not self:is_last_previewing_file_job_id(file_content.job_id) then
          do_complete(false)
          falsy_rendering()
          return
        end

        --- @type {line:string,lineno:integer,length:integer}?
        local hi_line = nil
        --- @type string[]
        local buf_lines = {}
        for i = line_index, line_index + line_step do
          if i <= LAST_LINE then
            if i < (content_view.top - 10) or i > (content_view.bottom + 10) then
              table.insert(buf_lines, "")
            else
              table.insert(buf_lines, LINES[i])
              if type(content_view.highlight) == "number" and content_view.highlight == i then
                hi_line = {
                  line = LINES[i],
                  lineno = i,
                  length = string.len(LINES[i]),
                }
              end
            end
          else
            break
          end
        end

        local set_start = line_index - 1
        local set_end = math.min(line_index + line_step - 1, LAST_LINE)
        -- log.debug(
        --   string.format(
        --     "|BufferPopupWindow:render_file_contents - set_buf_lines| previewer_label_result:%s line_index:%s, line_step:%s set start:%s, set_end:%s, FIRST_LINE/LAST_LINE:%s/%s, LINES_COUNT:%s",
        --     vim.inspect(file_content.previewer_label_result),
        --     vim.inspect(line_index),
        --     vim.inspect(line_step),
        --     vim.inspect(set_start),
        --     vim.inspect(set_end),
        --     vim.inspect(FIRST_LINE),
        --     vim.inspect(LAST_LINE),
        --     vim.inspect(LINES_COUNT)
        --   )
        -- )

        -- if not lines_been_cleared then
        --   vim.api.nvim_buf_set_lines(self.previewer_bufnr, 0, -1, false, {})
        --   lines_been_cleared = true
        -- end

        vim.api.nvim_buf_set_lines(self.previewer_bufnr, set_start, set_end, false, buf_lines)
        if hi_line then
          local start_row = hi_line.lineno - 1
          local end_row = hi_line.lineno - 1
          local start_col = 0
          local end_col = hi_line.length > 0 and hi_line.length or nil
          local opts = {
            end_row = end_row,
            end_col = end_col,
            strict = false,
            sign_hl_group = "CursorLineSign",
            number_hl_group = "CursorLineNr",
            line_hl_group = "Visual",
          }

          ---@diagnostic disable-next-line: unused-local
          local extmark_ok, extmark_result = pcall(
            vim.api.nvim_buf_set_extmark,
            self.previewer_bufnr,
            extmark_ns,
            start_row,
            start_col,
            opts
          )
          -- log.debug(
          --   "|BufferPopupWindow:render_file_contents - set_buf_lines| hi_line:%s, extmark ok:%s, extmark:%s, opts:%s",
          --   vim.inspect(hi_line),
          --   vim.inspect(extmark_ok),
          --   vim.inspect(extmark),
          --   vim.inspect(opts)
          -- )
        end

        line_index = line_index + line_step
        if line_index <= content_view.bottom then
          set_buf_lines()
        else
          -- Render complete, removes other bottom lines in the buffer.
          vim.api.nvim_buf_set_lines(self.previewer_bufnr, set_end, -1, false, {})
          self:_do_view(content_view)
          self._saved_previewing_file_content_view = content_view
          do_complete(true)
          falsy_rendering()
        end
      end, IS_LARGE_FILE and math.max(10 - string.len(tostring(LINES_COUNT)) * 2, 1) or 10)
    end
    set_buf_lines()
  end, 10)
end

--- @param content_view fzfx.BufferPopupWindowPreviewFileContentView
function BufferPopupWindow:_do_view(content_view)
  local ok, err = pcall(
    vim.api.nvim_win_set_cursor,
    self.previewer_winnr,
    { math.max(1, content_view.center), 0 }
  )
  log.ensure(
    ok,
    string.format(
      "|BufferPopupWindow:_do_view| failed to set cursor, view:%s, err:%s",
      vim.inspect(content_view),
      vim.inspect(err)
    )
  )
  vim.api.nvim_win_call(self.previewer_winnr, function()
    vim.api.nvim_command(string.format([[call winrestview({'topline':%d})]], content_view.top))
  end)
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
  if self:is_resizing() then
    return
  end

  self.previewer_is_hidden = false
  local win_confs = M.make_opts(
    self._saved_win_opts,
    self._saved_buffer_previewer_opts,
    self._saved_current_winnr,
    self._saved_current_win_first_line
  )

  self.previewer_bufnr = vim.api.nvim_create_buf(false, true)
  _set_provider_buf_opts(self.previewer_bufnr)
  self.previewer_winnr = vim.api.nvim_open_win(self.previewer_bufnr, true, win_confs.previewer)
  local wrap = self._saved_buffer_previewer_opts.fzf_preview_window_opts.wrap
  _set_previewer_win_opts(self.previewer_winnr, wrap, self._saved_current_winnr)
  vim.api.nvim_set_current_win(self.provider_winnr)

  self:resize()

  -- restore last file preview contents
  vim.schedule(function()
    if not self:previewer_is_valid() then
      return
    end
    if tbl.tbl_not_empty(self._saved_previewing_file_content_job) then
      local last_content = self._saved_previewing_file_content_job
      local last_view = self._saved_previewing_file_content_view ~= nil
          and self._saved_previewing_file_content_view
        or self:_make_view(last_content)
      self:preview_file_contents(last_content, last_view)
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
  if self:is_resizing() then
    return
  end

  self.previewer_is_hidden = true
  vim.api.nvim_win_close(self.previewer_winnr, true)
  self.previewer_winnr = nil
  self:resize()
end

function BufferPopupWindow:toggle_preview()
  -- log.debug(
  --   string.format(
  --     "|BufferPopupWindow:toggle_preview| previewer_is_hidden:%s",
  --     vim.inspect(self.previewer_is_hidden)
  --   )
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
    -- log.debug("|BufferPopupWindow:scroll_by| invalid")
    return
  end
  if self._saved_previewing_file_content_job == nil then
    -- log.debug("|BufferPopupWindow:scroll_by| no jobs")
    return
  end
  local file_content = self._saved_previewing_file_content_job
  if not self:is_last_previewing_file_job_id(file_content.job_id) then
    -- log.debug("|BufferPopupWindow:scroll_by| newer jobs")
    return
  end
  if self._scrolling then
    -- log.debug("|BufferPopupWindow:scroll_by| scrolling")
    return
  end
  if self._rendering then
    -- log.debug("|BufferPopupWindow:scroll_by| rendering")
    return
  end

  self._scrolling = true

  local function falsy_scrolling()
    vim.schedule(function()
      self._scrolling = false
    end)
  end

  local LINES = file_content.contents
  local LINES_COUNT = #LINES
  local WIN_HEIGHT = vim.api.nvim_win_get_height(self.previewer_winnr)

  local TOP_LINE = tbl.tbl_get(self._saved_previewing_file_content_view, "top")
    or vim.fn.line("w0", self.previewer_winnr)
  local BOTTOM_LINE = tbl.tbl_get(self._saved_previewing_file_content_view, "bottom")
    or math.min(TOP_LINE + WIN_HEIGHT, LINES_COUNT)
  local CENTER_LINE = tbl.tbl_get(self._saved_previewing_file_content_view, "center")
    or math.ceil((TOP_LINE + BOTTOM_LINE) / 2)
  local HIGHLIGHT_LINE = tbl.tbl_get(self._saved_previewing_file_content_view, "highlight")

  local shift_lines = math.max(math.floor(WIN_HEIGHT / 100 * percent), 0)
  if up then
    shift_lines = -shift_lines
  end
  local first_line = num.bound(TOP_LINE + shift_lines, 1, LINES_COUNT)
  local last_line =
    buffer_popup_window_helpers.calculate_bottom_by_top(first_line, LINES_COUNT, WIN_HEIGHT)
  -- log.debug(
  --   "|BufferPopupWindow:scroll_by|-1 percent:%s, up:%s, LINES/HEIGHT/SHIFT:%s/%s/%s, top/bottom/center:%s/%s/%s, first/last:%s/%s",
  --   vim.inspect(percent),
  --   vim.inspect(up),
  --   vim.inspect(LINES_COUNT),
  --   vim.inspect(WIN_HEIGHT),
  --   vim.inspect(shift_lines),
  --   vim.inspect(TOP_LINE),
  --   vim.inspect(BOTTOM_LINE),
  --   vim.inspect(CENTER_LINE),
  --   vim.inspect(first_line),
  --   vim.inspect(last_line)
  -- )
  local view = buffer_popup_window_helpers.make_range_view(
    LINES_COUNT,
    WIN_HEIGHT,
    first_line,
    last_line,
    HIGHLIGHT_LINE
  )
  -- log.debug(
  --   string.format(
  --     "|BufferPopupWindow:scroll_by|-2 percent:%s, up:%s, LINES/HEIGHT/SHIFT:%s/%s/%s, top/bottom/center:%s/%s/%s, view:%s",
  --     vim.inspect(percent),
  --     vim.inspect(up),
  --     vim.inspect(LINES_COUNT),
  --     vim.inspect(WIN_HEIGHT),
  --     vim.inspect(shift_lines),
  --     vim.inspect(TOP_LINE),
  --     vim.inspect(BOTTOM_LINE),
  --     vim.inspect(CENTER_LINE),
  --     vim.inspect(view)
  --   )
  -- )

  if TOP_LINE == view.top and BOTTOM_LINE == view.bottom then
    -- log.debug("|BufferPopupWindow:scroll_by| no change")
    falsy_scrolling()
    return
  end

  self:render_file_contents(
    file_content,
    view,
    falsy_scrolling,
    math.max(LINES_COUNT, minimal_line_step())
  )
end

function BufferPopupWindow:preview_page_down()
  self:scroll_by(100, false)
end

function BufferPopupWindow:preview_page_up()
  self:scroll_by(100, true)
end

function BufferPopupWindow:preview_half_page_down()
  self:scroll_by(50, false)
end

function BufferPopupWindow:preview_half_page_up()
  self:scroll_by(50, true)
end

M.BufferPopupWindow = BufferPopupWindow

-- BufferPopupWindow }

return M
