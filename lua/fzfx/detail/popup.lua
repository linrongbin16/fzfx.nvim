local fio = require("fzfx.commons.fio")
local path = require("fzfx.commons.path")
local uv = require("fzfx.commons.uv")
local version = require("fzfx.commons.version")

local log = require("fzfx.lib.log")

local ShellContext = require("fzfx.detail.popup.shell_helpers").ShellContext
local fzf_helpers = require("fzfx.detail.fzf_helpers")
local PopupWindow = require("fzfx.detail.popup.window").PopupWindow
local PopupWindowsManager = require("fzfx.detail.popup.window_manager").PopupWindowsManager

local M = {}

--- @param actions table<string, any>
--- @return string[][]
M._make_expect_keys = function(actions)
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
M._merge_fzf_actions = function(fzf_opts, actions)
  local expect_keys = M._make_expect_keys(actions)
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
M._make_fzf_command = function(fzf_opts, actions, result)
  local final_opts = M._merge_fzf_actions(fzf_opts, actions)
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

--- @alias fzfx.WindowOpts {relative:"editor"|"win"|"cursor",win:integer?,row:number,col:number,height:integer,width:integer,zindex:integer,border:string,title:string?,title_pos:string?,noautocmd:boolean?}
--- @alias fzfx.OnPopupExit fun(last_query:string):nil
--- @param win_opts fzfx.WindowOpts
--- @param source string
--- @param fzf_opts fzfx.FzfOpt[]
--- @param actions fzfx.Options
--- @param context fzfx.PipelineContext
--- @param on_close fzfx.OnPopupExit?
M.popup = function(win_opts, source, fzf_opts, actions, context, on_close)
  local result = vim.fn.tempname() --[[@as string]]
  local fzf_command = M._make_fzf_command(fzf_opts, actions, result)
  local popup_window = PopupWindow:new(win_opts)

  assert(M._PopupWindowsManagerInstance ~= nil)
  M._PopupWindowsManagerInstance:add(popup_window)

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

    assert(M._PopupWindowsManagerInstance ~= nil)
    M._PopupWindowsManagerInstance:remove(popup_window)
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
      if uv.fs_stat(result) then
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
  local saved_shell_ctx = ShellContext:save()
  local saved_fzf_default_command = vim.env.FZF_DEFAULT_COMMAND
  local saved_fzf_default_opts = vim.env.FZF_DEFAULT_OPTS
  vim.env.FZF_DEFAULT_OPTS = fzf_helpers.make_fzf_default_opts()
  vim.env.FZF_DEFAULT_COMMAND = source

  log.debug("|Popup:new| $FZF_DEFAULT_OPTS:" .. vim.inspect(vim.env.FZF_DEFAULT_OPTS))
  log.debug("|Popup:new| $FZF_DEFAULT_COMMAND:" .. vim.inspect(vim.env.FZF_DEFAULT_COMMAND))
  log.debug("|Popup:new| fzf_command:" .. vim.inspect(fzf_command))

  -- launch
  local jobid = vim.fn.termopen(fzf_command, { on_exit = on_fzf_exit }) --[[@as integer ]]

  -- restore fzf/shell context
  saved_shell_ctx:restore()
  vim.env.FZF_DEFAULT_COMMAND = saved_fzf_default_command
  vim.env.FZF_DEFAULT_OPTS = saved_fzf_default_opts

  vim.cmd([[startinsert]])
end

M._PopupWindowsManagerInstance = PopupWindowsManager:new()

M.setup = function()
  vim.api.nvim_create_autocmd({ "VimResized" }, {
    callback = function()
      M._PopupWindowsManagerInstance:resize()
    end,
  })
  if version.ge("0.9") then
    vim.api.nvim_create_autocmd({ "WinResized" }, {
      callback = function()
        M._PopupWindowsManagerInstance:resize()
      end,
    })
  end
end

return M
