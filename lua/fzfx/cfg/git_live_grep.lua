local str = require("fzfx.commons.str")

local cmds = require("fzfx.lib.commands")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum
local _grep = require("fzfx.cfg._grep")
local _decorator = require("fzfx.cfg._decorator")

local M = {}

M.command = {
  name = "FzfxGLiveGrep",
  desc = "Live git grep",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
  },
}

M._GIT_GREP = { "git", "grep", "--color=always", "-n" }

--- @param query string?
--- @param context fzfx.GitLiveGrepPipelineContext
--- @return string[]|nil
M._provider = function(query, context)
  local git_root_cmd = context.git_root_cmd
  if git_root_cmd:failed() then
    log.echo(LogLevels.INFO, "not in git repo.")
    return nil
  end

  local parsed = _grep.parse_query(query or "")
  local payload = parsed.payload
  local option = parsed.option

  local args = vim.deepcopy(M._GIT_GREP)
  args = _grep.append_options(args, option)
  table.insert(args, payload)
  return args
end

M.providers = {
  key = "default",
  provider = M._provider,
  provider_type = ProviderTypeEnum.COMMAND_ARRAY,
  provider_decorator = { module = _decorator.PREPEND_ICON_GREP },
}

M.previewers = {
  previewer = previewers_helper.preview_grep,
  previewer_type = PreviewerTypeEnum.COMMAND_ARRAY,
  previewer_label = labels_helper.label_grep,
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_grep,
  ["double-click"] = actions_helper.edit_grep,
  ["ctrl-q"] = actions_helper.setqflist_grep,
}

M.fzf_opts = {
  "--multi",
  "--disabled",
  { "--delimiter", ":" },
  { "--preview-window", "+{2}-/2" },
  { "--prompt", "Live Git Grep > " },
}

--- @alias fzfx.GitLiveGrepPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,git_root_cmd:fzfx.CommandResult}
--- @return fzfx.GitLiveGrepPipelineContext
M._context_maker = function()
  local git_root_cmd = cmds.run_git_root_sync()
  local context = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
    git_root_cmd = git_root_cmd,
  }
  return context
end

M.other_opts = {
  context_maker = M._context_maker,
  reload_on_change = true,
}

return M
