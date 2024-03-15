local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local api = require("fzfx.commons.api")
local fileio = require("fzfx.commons.fileio")

local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")
local popup_helpers = require("fzfx.detail.popup.popup_helpers")

local M = {}

local FLOAT_WIN_DEFAULT_ZINDEX = 60
local FLOAT_WIN_DEFAULT_STYLE = "minimal"

--- @alias fzfx.BufferFilePreviewerOpts {fzf_preview_window_opts:fzfx.FzfPreviewWindowOpts,fzf_border_opts:string}

--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @param relative_winnr integer?
--- @return {provider:fzfx.NvimFloatWinOpts,previewer:fzfx.NvimFloatWinOpts}
M.make_opts = function(win_opts, buffer_previewer_opts, relative_winnr)
  local opts = vim.deepcopy(win_opts)
  opts.relative = opts.relative or "editor"
  local layout = popup_helpers.make_layout(opts, buffer_previewer_opts.fzf_preview_window_opts)

  local relative = opts.relative
  local border = fzf_helpers.FZF_BORDER_OPTS_MAP[buffer_previewer_opts.fzf_border_opts]
    or fzf_helpers.FZF_DEFAULT_BORDER_OPTS

  local result = {
    anchor = "NW",
    relative = relative,
    width = layout.width,
    height = layout.height,
    row = layout.start_row,
    col = layout.start_col,
    style = FLOAT_WIN_DEFAULT_STYLE,
    border = border,
    zindex = FLOAT_WIN_DEFAULT_ZINDEX,
  }
  result.provider = {
    anchor = "NW",
    relative = relative,
    width = layout.provider.width,
    height = layout.provider.height,
    row = layout.provider.start_row,
    col = layout.provider.start_col,
    style = FLOAT_WIN_DEFAULT_STYLE,
    border = border,
    zindex = FLOAT_WIN_DEFAULT_ZINDEX,
  }
  result.previewer = {
    anchor = "NW",
    relative = relative,
    width = layout.previewer.width,
    height = layout.previewer.height,
    row = layout.previewer.start_row,
    col = layout.previewer.start_col,
    style = FLOAT_WIN_DEFAULT_STYLE,
    border = border,
    zindex = FLOAT_WIN_DEFAULT_ZINDEX,
  }

  if relative ~= "editor" and type(relative_winnr) == "number" then
    result.provider.win = relative_winnr
    result.previewer.win = relative_winnr
  end
  log.debug("|make_opts| result:%s", vim.inspect(result))
  return result
end

-- BufferPopupWindow {

--- @class fzfx.BufferPopupWindow
--- @field window_opts_context fzfx.WindowOptsContext?
--- @field provider_bufnr integer?
--- @field provider_winnr integer?
--- @field previewer_bufnr integer?
--- @field previewer_winnr integer?
--- @field _saved_current_winnr integer
--- @field _saved_win_opts fzfx.WindowOpts
--- @field _saved_buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @field _saved_previewing_file_content_job fzfx.BufferPopupWindowPreviewFileContentJob
--- @field _saved_previewing_file_content_context {top_line:integer}
--- @field _current_previewing_file_job_id integer?
--- @field _rendering boolean
--- @field _resizing boolean
--- @field _scrolling boolean
--- @field preview_files_queue fzfx.BufferPopupWindowPreviewFileJob[]
--- @field preview_file_contents_queue fzfx.BufferPopupWindowPreviewFileContentJob[]
--- @field previewer_is_hidden boolean
local BufferPopupWindow = {}

local function _set_default_buf_options(bufnr)
  api.set_buf_option(bufnr, "bufhidden", "wipe")
  api.set_buf_option(bufnr, "buflisted", false)
  api.set_buf_option(bufnr, "filetype", "fzf")
end

local function _set_default_previewer_win_options(winnr)
  api.set_win_option(winnr, "number", true)
  api.set_win_option(winnr, "spell", false)
  api.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
  -- apis.set_win_option(winnr, "scrolloff", 0)
  -- apis.set_win_option(winnr, "sidescrolloff", 0)
  api.set_win_option(winnr, "foldenable", false)
end

local function _set_default_provider_win_options(winnr)
  api.set_win_option(winnr, "number", false)
  api.set_win_option(winnr, "spell", false)
  api.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
  api.set_win_option(winnr, "colorcolumn", "")
  -- apis.set_win_option(winnr, "scrolloff", 0)
  -- apis.set_win_option(winnr, "sidescrolloff", 0)
  api.set_win_option(winnr, "foldenable", false)
end

--- @package
--- @param win_opts fzfx.WindowOpts
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.BufferPopupWindow
function BufferPopupWindow:new(win_opts, buffer_previewer_opts)
  local current_winnr = vim.api.nvim_get_current_win()

  -- save current window context
  local window_opts_context = popup_helpers.WindowOptsContext:save()

  --- @type integer
  local provider_bufnr = vim.api.nvim_create_buf(false, true)
  log.ensure(provider_bufnr > 0, "failed to create provider buf")
  _set_default_buf_options(provider_bufnr)

  --- @type integer
  local previewer_bufnr = vim.api.nvim_create_buf(false, true)
  log.ensure(previewer_bufnr > 0, "failed to create previewer buf")
  _set_default_buf_options(previewer_bufnr)

  local win_confs = M.make_opts(win_opts, buffer_previewer_opts, current_winnr)
  local provider_win_confs = win_confs.provider
  local previewer_win_confs = win_confs.previewer
  -- local provider_win_confs = M.make_provider_opts(win_opts, buffer_previewer_opts)
  -- local previewer_win_confs = M.make_previewer_opts(win_opts, buffer_previewer_opts)
  previewer_win_confs.focusable = false

  log.debug(
    "|BufferPopupWindow:new| win_opts:%s, buffer_previewer_opts:%s, win_confs:%s",
    vim.inspect(win_opts),
    vim.inspect(buffer_previewer_opts),
    vim.inspect(win_confs)
  )
  local previewer_winnr = vim.api.nvim_open_win(previewer_bufnr, true, previewer_win_confs)
  log.ensure(previewer_winnr > 0, "failed to create previewer win")
  _set_default_previewer_win_options(previewer_winnr)

  local provider_winnr = vim.api.nvim_open_win(provider_bufnr, true, provider_win_confs)
  log.ensure(provider_winnr > 0, "failed to create provider win")
  _set_default_provider_win_options(provider_winnr)

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
    window_opts_context = window_opts_context,
    provider_bufnr = provider_bufnr,
    provider_winnr = provider_winnr,
    previewer_bufnr = previewer_bufnr,
    previewer_winnr = previewer_winnr,
    _saved_current_winnr = current_winnr,
    _saved_win_opts = win_opts,
    _saved_buffer_previewer_opts = buffer_previewer_opts,
    _saved_previewing_file_content_job = nil,
    _saved_previewing_file_content_context = nil,
    _current_previewing_file_job_id = nil,
    _rendering = false,
    _scrolling = false,
    _resizing = false,
    preview_files_queue = {},
    preview_file_contents_queue = {},
    previewer_is_hidden = false,
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
      self._saved_current_winnr
    )
    new_win_confs.provider = nil
    new_win_confs.previewer = nil
    -- log.debug(
    --   "|BufferPopupWindow:resize| is hidden, provider - old:%s, new:%s",
    --   vim.inspect(old_provider_win_confs),
    --   vim.inspect(provider_win_confs)
    -- )
    vim.api.nvim_win_set_config(
      self.provider_winnr,
      vim.tbl_deep_extend("force", old_win_confs, new_win_confs)
    )
    _set_default_provider_win_options(self.provider_winnr)
  else
    local old_provider_win_confs = vim.api.nvim_win_get_config(self.provider_winnr)
    local win_confs = M.make_opts(
      self._saved_win_opts,
      self._saved_buffer_previewer_opts,
      self._saved_current_winnr
    )
    -- log.debug(
    --   "|BufferPopupWindow:resize| not hidden, provider - old:%s, new:%s",
    --   vim.inspect(old_provider_win_confs),
    --   vim.inspect(provider_win_confs)
    -- )
    vim.api.nvim_win_set_config(
      self.provider_winnr,
      vim.tbl_deep_extend("force", old_provider_win_confs, win_confs.provider or {})
    )
    _set_default_provider_win_options(self.provider_winnr)

    if self:previewer_is_valid() then
      local old_previewer_win_confs = vim.api.nvim_win_get_config(self.previewer_winnr)
      -- log.debug(
      --   "|BufferPopupWindow:resize| not hidden, previewer - old:%s, new:%s",
      --   vim.inspect(old_previewer_win_confs),
      --   vim.inspect(previewer_win_confs)
      -- )
      vim.api.nvim_win_set_config(
        self.previewer_winnr,
        vim.tbl_deep_extend("force", old_previewer_win_confs, win_confs.previewer or {})
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

--- @param lineno integer?
--- @param total_lines integer
--- @param winnr integer
--- @return {top_line:integer,highlight_line:integer?}
M._make_top_and_highlight_line = function(lineno, total_lines, winnr)
  if lineno == nil then
    return { top_line = 1, highlight_line = 1 }
  end
  local win_height = vim.api.nvim_win_get_height(winnr)
  local highlight_line = lineno
  local top_line = math.max(1, math.ceil(highlight_line - win_height / 2))
  local bottom_line = top_line + win_height
  if bottom_line > total_lines then
    local diff = bottom_line - total_lines
    top_line = math.max(1, top_line - diff)
  end
  return { top_line = top_line, highlight_line = highlight_line }
end

--- @alias fzfx.BufferPopupWindowPreviewFileJob {job_id:integer,previewer_result:fzfx.BufferFilePreviewerResult,previewer_label_result:string?}
--- @param job_id integer
--- @param previewer_result fzfx.BufferFilePreviewerResult
--- @param previewer_label_result string?
function BufferPopupWindow:preview_file(job_id, previewer_result, previewer_label_result)
  if str.empty(tbl.tbl_get(previewer_result, "filename")) then
    return
  end

  -- log.debug(
  --   "|BufferPopupWindow:preview_file| previewer_result:%s, previewer_label_result:%s",
  --   vim.inspect(previewer_result),
  --   vim.inspect(previewer_label_result)
  -- )
  table.insert(self.preview_files_queue, {
    job_id = job_id,
    previewer_result = previewer_result,
    previewer_label_result = previewer_label_result,
  })

  vim.defer_fn(function()
    if not self:previewer_is_valid() then
      -- log.debug("|BufferPopupWindow:preview_file| invalid previewer:%s", vim.inspect(self))
      return
    end
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

    -- read file content
    fileio.asyncreadfile(last_job.previewer_result.filename, function(contents)
      if not self:previewer_is_valid() then
        return
      end
      if not self:is_last_previewing_file_job_id(last_job.job_id) then
        return
      end

      local lines = {}
      if str.not_empty(contents) then
        contents = contents:gsub("\r\n", "\n")
        lines = str.split(contents, "\n")
      end
      table.insert(self.preview_file_contents_queue, {
        contents = lines,
        job_id = last_job.job_id,
        previewer_result = last_job.previewer_result,
        previewer_label_result = last_job.previewer_label_result,
      })

      -- show file contents by lines
      vim.defer_fn(function()
        if not self:previewer_is_valid() then
          -- log.debug(
          --   "|BufferPopupWindow:preview_file - asyncreadfile - done content| invalid previewer:%s",
          --   vim.inspect(self)
          -- )
          return
        end

        local last_content = self.preview_file_contents_queue[#self.preview_file_contents_queue]
        self.preview_file_contents_queue = {}

        if not self:is_last_previewing_file_job_id(last_content.job_id) then
          return
        end

        self._saved_previewing_file_content_job = last_content
        local line_pos = M._make_top_and_highlight_line(
          last_content.previewer_result.lineno,
          #last_content.contents,
          self.previewer_winnr
        )
        self:preview_file_contents(last_content, line_pos.top_line, line_pos.highlight_line)
      end, 10)
    end)
  end, 20)
end

--- @alias fzfx.BufferPopupWindowPreviewFileContentJob {contents:string[],job_id:integer,previewer_result:fzfx.BufferFilePreviewerResult,previewer_label_result:string?}
--- @param file_content fzfx.BufferPopupWindowPreviewFileContentJob
--- @param top_line integer
--- @param highlight_line integer?
--- @param on_complete (fun(done:boolean):any)|nil
function BufferPopupWindow:preview_file_contents(
  file_content,
  top_line,
  highlight_line,
  on_complete
)
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
  api.set_buf_option(self.previewer_bufnr, "filetype", file_type)

  vim.defer_fn(function()
    if not self:previewer_is_valid() then
      do_complete(false)
      return
    end
    if not self:is_last_previewing_file_job_id(file_content.job_id) then
      do_complete(false)
      return
    end

    -- vim.api.nvim_buf_call(self.previewer_bufnr, function()
    --   vim.api.nvim_command([[filetype detect]])
    -- end)

    vim.api.nvim_buf_set_lines(self.previewer_bufnr, 0, -1, false, {})

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
      api.set_win_option(self.previewer_winnr, "number", true)
    end

    if str.not_empty(file_content.previewer_label_result) then
      vim.defer_fn(set_win_title, 100)
    end

    self:render_file_contents(file_content, top_line, on_complete)
  end, 20)
end

--- @param file_content fzfx.BufferPopupWindowPreviewFileContentJob
--- @param top_line integer
--- @param on_complete (fun(done:boolean):any)|nil
--- @param line_step integer?
function BufferPopupWindow:render_file_contents(file_content, top_line, on_complete, line_step)
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

    local WIN_HEIGHT = vim.api.nvim_win_get_height(self.previewer_winnr)
    local LINES = file_content.contents
    local LINES_COUNT = #LINES
    local TOP_LINE = top_line
    local BOTTOM_LINE = math.min(WIN_HEIGHT + TOP_LINE, LINES_COUNT)
    local line_index = TOP_LINE
    line_step = line_step or 5

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

        local buf_lines = {}
        for i = line_index, line_index + line_step do
          if i <= BOTTOM_LINE then
            table.insert(buf_lines, LINES[i])
          else
            break
          end
        end

        local set_start = line_index - 1
        local set_end = math.min(line_index + line_step, BOTTOM_LINE + 1) - 1
        -- log.debug(
        --   "|BufferPopupWindow:render_file_contents - set_buf_lines| line_index:%s, set start:%s, end:%s, TOP_LINE/BOTTOM_LINE:%s/%s",
        --   vim.inspect(line_index),
        --   vim.inspect(set_start),
        --   vim.inspect(set_end),
        --   vim.inspect(TOP_LINE),
        --   vim.inspect(BOTTOM_LINE)
        -- )
        vim.api.nvim_buf_set_lines(self.previewer_bufnr, set_start, set_end, false, buf_lines)

        line_index = line_index + line_step
        if line_index <= BOTTOM_LINE then
          set_buf_lines()
        else
          vim.api.nvim_win_call(self.previewer_winnr, function()
            vim.api.nvim_command(string.format([[call winrestview({'topline':%d})]], TOP_LINE))
          end)
          self._saved_previewing_file_content_context = { top_line = TOP_LINE }
          do_complete(true)
          falsy_rendering()
        end
      end, 10)
    end
    set_buf_lines()
  end, 20)
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
  local win_confs =
    M.make_opts(self._saved_win_opts, self._saved_buffer_previewer_opts, self._saved_current_winnr)
  win_confs.previewer.focusable = false

  self.previewer_bufnr = vim.api.nvim_create_buf(false, true)
  _set_default_buf_options(self.previewer_bufnr)
  self.previewer_winnr = vim.api.nvim_open_win(self.previewer_bufnr, true, win_confs.previewer)
  vim.api.nvim_set_current_win(self.provider_winnr)

  self:resize()

  -- restore last file preview contents
  vim.schedule(function()
    if not self:previewer_is_valid() then
      -- log.debug(
      --   "|BufferPopupWindow:preview_file - asyncreadfile - done content| invalid previewer:%s",
      --   vim.inspect(self)
      -- )
      return
    end
    if tbl.tbl_not_empty(self._saved_previewing_file_content_job) then
      local last_content = self._saved_previewing_file_content_job
      local line_pos = M._make_top_and_highlight_line(
        last_content.previewer_result.lineno,
        #last_content.contents,
        self.previewer_winnr
      )
      self:preview_file_contents(last_content, line_pos.top_line, line_pos.highlight_line)
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
  if self._saved_previewing_file_content_job == nil then
    return
  end
  local file_content = self._saved_previewing_file_content_job
  if not self:is_last_previewing_file_job_id(file_content.job_id) then
    return
  end
  if self._scrolling then
    return
  end
  if self._rendering then
    return
  end

  local down = not up
  self._scrolling = true

  local function falsy_scrolling()
    vim.schedule(function()
      self._scrolling = false
    end)
  end

  local LINES = file_content.contents
  local LINES_COUNT = #LINES
  local WIN_HEIGHT = math.max(vim.api.nvim_win_get_height(self.previewer_winnr), 1)
  local TOP_LINE = tbl.tbl_get(self._saved_previewing_file_content_context, "top_line")
    or vim.fn.line("w0", self.previewer_winnr)
  local BOTTOM_LINE = math.min(TOP_LINE + WIN_HEIGHT, LINES_COUNT)
  local SHIFT_LINES = math.max(math.floor(WIN_HEIGHT / 100 * percent), 0)
  if up then
    SHIFT_LINES = -SHIFT_LINES
  end
  local TARGET_FIRST_LINENO = math.max(TOP_LINE + SHIFT_LINES, 1)
  local TARGET_LAST_LINENO = math.min(BOTTOM_LINE + SHIFT_LINES, LINES_COUNT)
  if TARGET_LAST_LINENO >= LINES_COUNT then
    TARGET_FIRST_LINENO = math.max(1, TARGET_LAST_LINENO - WIN_HEIGHT + 1)
  end

  log.debug(
    "|BufferPopupWindow:scroll_by| percent:%s, up:%s, LINES/HEIGHT/SHIFT:%s/%s/%s, top/bottom:%s/%s, target top/bottom:%s/%s",
    vim.inspect(percent),
    vim.inspect(up),
    vim.inspect(LINES_COUNT),
    vim.inspect(WIN_HEIGHT),
    vim.inspect(SHIFT_LINES),
    vim.inspect(TOP_LINE),
    vim.inspect(BOTTOM_LINE),
    vim.inspect(TARGET_FIRST_LINENO),
    vim.inspect(TARGET_LAST_LINENO)
  )

  if up and TOP_LINE <= 1 then
    falsy_scrolling()
    return
  end
  if down and BOTTOM_LINE >= LINES_COUNT then
    falsy_scrolling()
    return
  end

  self:render_file_contents(file_content, TARGET_FIRST_LINENO, function()
    falsy_scrolling()
  end, math.max(WIN_HEIGHT, 30))
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
