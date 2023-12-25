local consts = require("fzfx.lib.constants")
local shells = require("fzfx.lib.shells")
local cmds = require("fzfx.lib.commands")
local tbls = require("fzfx.lib.tables")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local actions_helper = require("fzfx.helper.actions")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.commands = {
  -- normal
  {
    name = "FzfxGStatus",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "dir",
      desc = "Find changed git files (status)",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGStatusC",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "dir",
      desc = "Find changed git files (status) in current directory",
    },
    default_provider = "current_folder",
  },
  -- visual
  {
    name = "FzfxGStatusV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find changed git files (status) by visual select",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGStatusCV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find changed git files (status) in current directory by visual select",
    },
    default_provider = "current_folder",
  },
  -- cword
  {
    name = "FzfxGStatusW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find changed git files (status) by cursor word",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGStatusCW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find changed git files (status) in current directory by cursor word",
    },
    default_provider = "current_folder",
  },
  -- put
  {
    name = "FzfxGStatusP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find changed git files (status) by yank text",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGStatusCP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find changed git files (status) in current directory by yank text",
    },
    default_provider = "current_folder",
  },
  -- resume
  {
    name = "FzfxGStatusR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find changed git files (status) by resume last",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGStatusCR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find changed git files (status) in current directory by resume last",
    },
    default_provider = "current_folder",
  },
}

--- @param opts {current_folder:boolean?}?
--- @return boolean
M._is_current_folder_mode = function(opts)
  ---@diagnostic disable-next-line: need-check-nil
  return tbls.tbl_not_empty(opts) and opts.current_folder --[[@as boolean]]
end

--- @param opts {current_folder:boolean?}?
--- @return fun():string[]|nil
M._make_git_status_provider = function(opts)
  local function impl()
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, "not in git repo.")
      return nil
    end
    return M._is_current_folder_mode(opts)
        and {
          "git",
          "-c",
          "color.status=always",
          "status",
          "--short",
          ".",
        }
      or { "git", "-c", "color.status=always", "status", "--short" }
  end
  return impl
end

local current_folder_provider =
  M._make_git_status_provider({ current_folder = true })
local workspace_provider = M._make_git_status_provider()

M.providers = {
  current_folder = {
    key = "ctrl-u",
    provider = current_folder_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
  },
  workspace = {
    key = "ctrl-w",
    provider = workspace_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
  },
}

--- @param line string
--- @return string?
M._git_status_previewer = function(line)
  local parsed = parsers_helper.parse_git_status(line)
  if consts.HAS_DELTA then
    local win_width = previewers_helper.get_preview_window_width()
    return string.format(
      [[git diff %s | delta -n --tabs 4 --width %d]],
      shells.shellescape(parsed.filename),
      win_width
    )
  else
    return string.format(
      [[git diff --color=always %s]],
      shells.shellescape(parsed.filename)
    )
  end
end

M.previewers = {
  current_folder = {
    previewer = M._git_status_previewer,
  },
  workspace = {
    previewer = M._git_status_previewer,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_git_status,
  ["double-click"] = actions_helper.edit_git_status,
  ["ctrl-q"] = actions_helper.setqflist_git_status,
}

M.fzf_opts = {
  consts.FZF_OPTS.MULTI,
  { "--preview-window", "wrap" },
  { "--prompt", "Git Status > " },
}

return M
