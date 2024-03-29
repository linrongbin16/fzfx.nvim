local tbl = require("fzfx.commons.tbl")
local path = require("fzfx.commons.path")

local cmds = require("fzfx.lib.commands")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels
local switches = require("fzfx.lib.switches")

local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.command = {
  name = "FzfxGFiles",
  desc = "Find git files",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "workspace",
  },
  {
    name = "cwd_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "current_folder",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "workspace",
  },
  {
    name = "cwd_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "current_folder",
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "workspace",
  },
  {
    name = "cwd_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "current_folder",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "workspace",
  },
  {
    name = "cwd_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "current_folder",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "workspace",
  },
  {
    name = "cwd_resume",
    feed = CommandFeedEnum.RESUME,
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
    return tbl.tbl_get(opts, "current_folder") and { "git", "ls-files" }
      or { "git", "ls-files", ":/" }
  end
  return impl
end

local current_folder_provider = M._make_git_files_provider({ current_folder = true })
local workspace_provider = M._make_git_files_provider()

M.providers = {
  current_folder = {
    key = "ctrl-u",
    provider = current_folder_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
    provider_decorator = { module = "prepend_icon_find", builtin = true },
  },
  workspace = {
    key = "ctrl-w",
    provider = workspace_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
    provider_decorator = { module = "prepend_icon_find", builtin = true },
  },
}

-- if you want to use fzf-builtin previewer with bat, please use below configs:
--
-- previewer = previewers_helper.preview_files_find
-- previewer_type = PreviewerTypeEnum.COMMAND_LIST

-- if you want to use nvim buffer previewer, please use below configs:
--
-- previewer = previewers_helper.buffer_preview_files_find
-- previewer_type = PreviewerTypeEnum.BUFFER_FILE

local previewer = switches.buffer_previewer_disabled() and previewers_helper.preview_files_find
  or previewers_helper.buffer_preview_files_find
local previewer_type = switches.buffer_previewer_disabled() and PreviewerTypeEnum.COMMAND_LIST
  or PreviewerTypeEnum.BUFFER_FILE

M.previewers = {
  current_folder = {
    previewer = previewer,
    previewer_type = previewer_type,
    previewer_label = labels_helper.label_find,
  },
  workspace = {
    previewer = previewer,
    previewer_type = previewer_type,
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
  "--multi",
  function()
    return { "--prompt", path.shorten() .. " > " }
  end,
}

return M
