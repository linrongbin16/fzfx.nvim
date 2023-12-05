local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")
local cmds = require("fzfx.lib.commands")
local colors = require("fzfx.lib.colors")
local paths = require("fzfx.lib.paths")
local fs = require("fzfx.lib.filesystems")
local tbls = require("fzfx.lib.tables")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local queries_helper = require("fzfx.helper.queries")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local providers_helper = require("fzfx.helper.providers")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.commands = {
  -- normal
  {
    name = "FzfxGFiles",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "dir",
      desc = "Find git files",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGFilesC",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "dir",
      desc = "Find git files in current directory",
    },
    default_provider = "current_folder",
  },
  -- visual
  {
    name = "FzfxGFilesV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find git files by visual select",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGFilesCV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find git files in current directory by visual select",
    },
    default_provider = "current_folder",
  },
  -- cword
  {
    name = "FzfxGFilesW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find git files by cursor word",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGFilesCW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find git files in current directory by cursor word",
    },
    default_provider = "current_folder",
  },
  -- put
  {
    name = "FzfxGFilesP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find git files by yank text",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGFilesCP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find git files in current directory by yank text",
    },
    default_provider = "current_folder",
  },
  -- resume
  {
    name = "FzfxGFilesR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find git files by resume last",
    },
    default_provider = "workspace",
  },
  {
    name = "FzfxGFilesCR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find git files in current directory by resume last",
    },
    default_provider = "current_folder",
  },
}

--- @param opts {current_folder:boolean?}?
--- @return fun():string[]|nil
M._make_git_files_provider = function(opts)
  --- @return string[]|nil
  local function impl()
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, "not in git repo.")
      return nil
    end
    return (type(opts) == "table" and opts.current_folder)
        and { "git", "ls-files" }
      or { "git", "ls-files", ":/" }
  end
  return impl
end

local current_folder_provider =
  M._make_git_files_provider({ current_folder = true })
local workspace_provider = M._make_git_files_provider()

M.providers = {
  current_folder = {
    key = "ctrl-u",
    provider = current_folder_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
    line_opts = { prepend_icon_by_ft = true },
  },
  workspace = {
    key = "ctrl-w",
    provider = workspace_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
    line_opts = { prepend_icon_by_ft = true },
  },
}

M.previewers = {
  current_folder = {
    previewer = previewers_helper.preview_files_find,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_find,
  },
  workspace = {
    previewer = previewers_helper.preview_files_find,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_find,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_find,
  ["double-click"] = actions_helper.edit_find,
  ["ctrl-q"] = actions_helper.setqflist_find,
}

M.fzf_opts = {
  consts.FZF_OPTS.MULTI,
  function()
    return { "--prompt", paths.shorten() .. " > " }
  end,
}

return M
