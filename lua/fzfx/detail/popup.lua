local fileio = require("fzfx.commons.fileio")
local path = require("fzfx.commons.path")
local version = require("fzfx.commons.version")

local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")

local popup_helpers = require("fzfx.detail.popup.popup_helpers")
local fzf_popup_window = require("fzfx.detail.popup.fzf_popup_window")
local buffer_popup_window = require("fzfx.detail.popup.buffer_popup_window")

--- @type table<integer, fzfx.PopupWindow>
local PopupWindowInstances = {}

--- @class fzfx.PopupWindow
--- @field instance fzfx.FzfPopupWindow|fzfx.BufferPopupWindow
local PopupWindow = {}

--- @package
--- @param win_opts fzfx.WindowOpts
--- @param window_type "fzf"|"buffer"
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.PopupWindow
function PopupWindow:new(win_opts, window_type, buffer_previewer_opts)
  -- check executables
  fzf_helpers.nvim_exec()
  fzf_helpers.fzf_exec()

  --- @type fzfx.FzfPopupWindow|fzfx.BufferPopupWindow
  local instance = nil
  if window_type == "fzf" then
    instance = fzf_popup_window.FzfPopupWindow:new(win_opts, buffer_previewer_opts)
  elseif window_type == "buffer" then
    instance = buffer_popup_window.BufferPopupWindow:new(win_opts, buffer_previewer_opts)
  end

  local o = {
    instance = instance,
  }
  setmetatable(o, self)
  self.__index = self

  PopupWindowInstances[instance:handle()] = o

  return o
end

function PopupWindow:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

  if self.instance then
    PopupWindowInstances[self.instance:handle()] = nil
    self.instance:close()
    self.instance = nil
  end
end

function PopupWindow:resize()
  if self.instance then
    self.instance:resize()
  end
end

--- @param job_id integer
--- @param previewer_result fzfx.BufferFilePreviewerResult
--- @param previewer_label_result string?
function PopupWindow:preview_file(job_id, previewer_result, previewer_label_result)
  self.instance:preview_file(job_id, previewer_result, previewer_label_result)
end

--- @param action_name string
function PopupWindow:preview_action(action_name)
  self.instance:preview_action(action_name)
end

function PopupWindow:previewer_is_valid()
  return self.instance ~= nil and self.instance:previewer_is_valid()
end

function PopupWindow:provider_is_valid()
  return self.instance ~= nil and self.instance:provider_is_valid()
end

--- @param jobid integer
function PopupWindow:set_current_previewing_file_job_id(jobid)
  self.instance:set_current_previewing_file_job_id(jobid)
end

--- @alias fzfx.NvimFloatWinOpts {anchor:"NW"?,relative:"editor"|"win"|"cursor"|nil,width:integer?,height:integer?,row:integer?,col:integer?,style:"minimal"?,border:"none"|"single"|"double"|"rounded"|"solid"|"shadow"|nil,zindex:integer?,focusable:boolean?}
--- @alias fzfx.WindowOpts {relative:"editor"|"win"|"cursor",win:integer?,row:number,col:number,height:integer,width:integer,zindex:integer,border:string,title:string?,title_pos:string?,noautocmd:boolean?}
--
--- @class fzfx.Popup
--- @field popup_window fzfx.PopupWindow?
--- @field source string|string[]|nil
--- @field jobid integer|nil
--- @field result string|nil
local Popup = {}

--- @param actions table<string, any>
--- @return string[][]
local function _make_expect_keys(actions)
  local expect_keys = {}
  if type(actions) == "table" then
    for name, _ in pairs(actions) do
      table.insert(expect_keys, { "--expect", name })
    end
  end
  return expect_keys
end

--- @param fzf_opts string[]|string[][]
--- @param actions table<string, any>
--- @return string[]
local function _merge_fzf_actions(fzf_opts, actions)
  local expect_keys = _make_expect_keys(actions)
  local merged_opts = vim.list_extend(vim.deepcopy(fzf_opts), expect_keys)
  -- log.debug(
  --     "|fzfx.popup - _merge_fzf_actions| fzf_opts:%s, actions:%s, merged_opts:%s",
  --     vim.inspect(fzf_opts),
  --     vim.inspect(actions),
  --     vim.inspect(merged_opts)
  -- )
  return merged_opts
end

--- @param fzf_opts fzfx.Options
--- @param actions fzfx.Options
--- @param result string
--- @return string
local function _make_fzf_command(fzf_opts, actions, result)
  local final_opts = _merge_fzf_actions(fzf_opts, actions)
  local final_opts_string = fzf_helpers.make_fzf_opts(final_opts)
  -- log.debug(
  --     "|fzfx.popup - _make_fzf_command| final_opts:%s, builder:%s",
  --     vim.inspect(final_opts),
  --     vim.inspect(final_opts_string)
  -- )
  local command = string.format("%s %s >%s", fzf_helpers.fzf_exec(), final_opts_string, result)
  -- log.debug(
  --     "|fzfx.popup - _make_fzf_command| command:%s",
  --     vim.inspect(command)
  -- )
  return command
end

--- @alias fzfx.OnPopupExit fun(last_query:string):nil
--- @param win_opts fzfx.WindowOpts
--- @param source string
--- @param fzf_opts fzfx.FzfOpt[]
--- @param actions fzfx.Options
--- @param context fzfx.PipelineContext
--- @param on_close fzfx.OnPopupExit?
--- @param use_buffer_previewer boolean?
--- @param buffer_previewer_opts fzfx.BufferFilePreviewerOpts
--- @return fzfx.Popup
function Popup:new(
  win_opts,
  source,
  fzf_opts,
  actions,
  context,
  on_close,
  use_buffer_previewer,
  buffer_previewer_opts
)
  local result = vim.fn.tempname() --[[@as string]]
  local fzf_command = _make_fzf_command(fzf_opts, actions, result)
  local popup_window =
    PopupWindow:new(win_opts, use_buffer_previewer and "buffer" or "fzf", buffer_previewer_opts)

  local function on_fzf_exit(jobid2, exitcode, event)
    -- log.debug(
    --   "|Popup:new| fzf exit, jobid2:%s, exitcode:%s, event:%s",
    --   vim.inspect(jobid2),
    --   vim.inspect(exitcode),
    --   vim.inspect(event)
    -- )
    if exitcode > 1 and (exitcode ~= 130 and exitcode ~= 129) then
      log.err(
        string.format(
          "command '%s' exit with code: %d, event: %s",
          vim.inspect(fzf_command),
          vim.inspect(exitcode),
          vim.inspect(event)
        )
      )
      return
    end

    -- press <ESC> if still in fzf terminal
    local esc_key = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
    if vim.o.buftype == "terminal" and vim.o.filetype == "fzf" then
      vim.api.nvim_feedkeys(esc_key, "x", false)
    end

    -- close popup window and restore old window
    popup_window:close()

    -- -- press <ESC> if in insert mode
    -- vim.api.nvim_feedkeys(esc_key, "x", false)

    log.ensure(
      path.isfile(result),
      string.format("|Popup:new.on_fzf_exit| result %s must be readable", vim.inspect(result))
    )
    local lines = fileio.readlines(result --[[@as string]]) --[[@as table]]
    -- log.debug(
    --   "|Popup:new| fzf exit, result:%s, lines:%s",
    --   vim.inspect(result),
    --   vim.inspect(lines)
    -- )
    if (exitcode == 130 or exitcode == 129) and #lines == 0 then
      return
    end
    local last_query = vim.trim(lines[1])
    local action_key = vim.trim(lines[2])
    local action_lines = vim.list_slice(lines, 3)
    -- log.debug(
    --     "|fzfx.popup - Popup:new.on_fzf_exit| action_key:%s, action_lines:%s",
    --     vim.inspect(action_key),
    --     vim.inspect(action_lines)
    -- )
    vim.schedule(function()
      log.ensure(actions[action_key] ~= nil, "unknown action key: " .. vim.inspect(action_key))
      local action_callback = actions[action_key]
      log.ensure(
        type(action_callback) == "function",
        string.format(
          "wrong action type on key: %s, must be function(%s): %s",
          vim.inspect(action_key),
          type(action_callback),
          vim.inspect(action_callback)
        )
      )
      local ok, cb_err = pcall(action_callback, action_lines, context)
      log.ensure(
        ok,
        string.format(
          "failed to run action on callback(%s) with lines(%s)! %s",
          vim.inspect(action_callback),
          vim.inspect(action_lines),
          vim.inspect(cb_err)
        )
      )
      if type(on_close) == "function" then
        vim.schedule(function()
          on_close(last_query)
        end)
      end
    end)
  end

  -- save fzf/shell context
  local saved_shell_opts_context = popup_helpers.ShellOptsContext:save()
  local saved_fzf_default_command = vim.env.FZF_DEFAULT_COMMAND
  local saved_fzf_default_opts = vim.env.FZF_DEFAULT_OPTS
  vim.env.FZF_DEFAULT_OPTS = fzf_helpers.make_fzf_default_opts()
  vim.env.FZF_DEFAULT_COMMAND = source

  -- log.debug("|Popup:new| $FZF_DEFAULT_OPTS:%s", vim.inspect(vim.env.FZF_DEFAULT_OPTS))
  -- log.debug("|Popup:new| $FZF_DEFAULT_COMMAND:%s", vim.inspect(vim.env.FZF_DEFAULT_COMMAND))
  log.debug("|Popup:new| fzf_command:" .. vim.inspect(fzf_command))

  -- launch
  local jobid = vim.fn.termopen(fzf_command, { on_exit = on_fzf_exit }) --[[@as integer ]]

  -- restore fzf/shell context
  saved_shell_opts_context:restore()
  vim.env.FZF_DEFAULT_COMMAND = saved_fzf_default_command
  vim.env.FZF_DEFAULT_OPTS = saved_fzf_default_opts

  vim.cmd([[ startinsert ]])

  local o = {
    popup_window = popup_window,
    source = source,
    jobid = jobid,
    result = result,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function Popup:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))
end

function Popup:previewer_is_valid()
  return self.popup_window ~= nil and self.popup_window:previewer_is_valid()
end

function Popup:provider_is_valid()
  return self.popup_window ~= nil and self.popup_window:provider_is_valid()
end

-- PopupWindowInstances {

--- @return table<integer, fzfx.PopupWindow>
local function _get_instances()
  return PopupWindowInstances
end

local function _clear_instances()
  PopupWindowInstances = {}
end

--- @return integer
local function _count_instances()
  local n = 0
  for _, popup_win in pairs(PopupWindowInstances) do
    if popup_win then
      n = n + 1
    end
  end
  return n
end

local function _resize_instances()
  for _, popup_win in pairs(PopupWindowInstances) do
    if popup_win then
      popup_win:resize()
    end
  end
end

-- PopupWindowInstances }

local function setup()
  vim.api.nvim_create_autocmd({ "VimResized" }, {
    callback = _resize_instances,
  })
  if version.ge("0.9") then
    vim.api.nvim_create_autocmd({ "WinResized" }, {
      callback = _resize_instances,
    })
  end
end

local M = {
  _get_instances = _get_instances,
  _clear_instances = _clear_instances,
  _count_instances = _count_instances,
  _resize_instances = _resize_instances,

  _make_expect_keys = _make_expect_keys,
  _merge_fzf_actions = _merge_fzf_actions,
  _make_fzf_command = _make_fzf_command,

  PopupWindow = PopupWindow,
  Popup = Popup,
  setup = setup,
}

return M
