---@diagnostic disable: invisible

local fio = require("fzfx.commons.fio")
local path = require("fzfx.commons.path")
local version = require("fzfx.commons.version")
local uv = require("fzfx.commons.uv")

local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")

local popup_helpers = require("fzfx.detail.popup.popup_helpers")
local window_helpers = require("fzfx.detail.popup.window_helpers")
local PopupWindow = require("fzfx.detail.popup.window").PopupWindow

local M = {}

--- @type table<integer, fzfx.PopupWindow>
M._PopupWindowInstances = {}

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
--- @return fzfx.Popup
function Popup:new(win_opts, source, fzf_opts, actions, context, on_close)
  local result = vim.fn.tempname() --[[@as string]]
  local fzf_command = _make_fzf_command(fzf_opts, actions, result)
  local popup_window = PopupWindow:new(win_opts)

  local function on_fzf_exit(jobid2, exitcode, event)
    -- log.debug(
    --   string.format(
    --     "|Popup:new - on_fzf_exit| jobid2:%s, exitcode:%s, event:%s",
    --     vim.inspect(jobid2),
    --     vim.inspect(exitcode),
    --     vim.inspect(event)
    --   )
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
    local lines = fio.readlines(result --[[@as string]]) --[[@as table]]
    -- log.debug(
    --   string.format(
    --     "|Popup:new - on_fzf_exit| result:%s, lines:%s",
    --     vim.inspect(result),
    --     vim.inspect(lines)
    --   )
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

      -- Clean up temp files
      ---@diagnostic disable-next-line: undefined-field
      if uv.fs_stat(result) then
        ---@diagnostic disable-next-line: undefined-field
        uv.fs_unlink(result, function(err, success)
          -- log.debug(
          --   string.format(
          --     "Remove popup result:%s, err:%s, success:%s",
          --     result,
          --     vim.inspect(err),
          --     vim.inspect(success)
          --   )
          -- )
        end)
      end

      if type(on_close) == "function" then
        vim.schedule(function()
          on_close(last_query)
        end)
      end
    end)
  end -- on_fzf_exit

  -- save fzf/shell context
  local saved_shell_ctx = window_helpers.ShellContext:save()
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
  saved_shell_ctx:restore()
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

-- function Popup:close() end

-- PopupWindowInstances {

--- @return table<integer, fzfx.PopupWindow>
local function _get_instances()
  return M._PopupWindowInstances
end

local function _clear_instances()
  M._PopupWindowInstances = {}
end

--- @return integer
local function _count_instances()
  local n = 0
  for _, popup_win in pairs(M._PopupWindowInstances) do
    if popup_win then
      n = n + 1
    end
  end
  return n
end

local function _resize_instances()
  for _, popup_win in pairs(M._PopupWindowInstances) do
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

M._get_instances = _get_instances
M._clear_instances = _clear_instances
M._count_instances = _count_instances
M._resize_instances = _resize_instances

M._make_expect_keys = _make_expect_keys
M._merge_fzf_actions = _merge_fzf_actions
M._make_fzf_command = _make_fzf_command

M.Popup = Popup
M.setup = setup

return M
