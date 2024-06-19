local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")

local shells = require("fzfx.lib.shells")
local cmds = require("fzfx.lib.commands")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local actions_helper = require("fzfx.helper.actions")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.command = {
  name = "FzfxGBranches",
  desc = "Search git branches",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "local_branch",
  },
  {
    name = "remote_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "remote_branch",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "local_branch",
  },
  {
    name = "remote_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "remote_branch",
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "local_branch",
  },
  {
    name = "remote_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "remote_branch",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "local_branch",
  },
  {
    name = "remote_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "remote_branch",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "local_branch",
  },
  {
    name = "remote_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "remote_branch",
  },
}

--- @param opts {remote_branch:boolean?}?
--- @return fun():string[]|nil
M._make_provider = function(opts)
  local remote_branch = tbl.tbl_get(opts, "remote_branch") or false

  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, "not in git repo.")
      return nil
    end
    local git_current_branch_cmd = cmds.GitCurrentBranchCommand:run()
    if git_current_branch_cmd:failed() then
      log.echo(LogLevels.WARN, table.concat(git_current_branch_cmd.result.stderr, " "))
      return nil
    end
    local results = {}
    table.insert(results, string.format("* %s", git_current_branch_cmd:output()))
    local git_branches_cmd = cmds.GitBranchesCommand:run(remote_branch)
    if git_branches_cmd:failed() then
      log.echo(LogLevels.WARN, table.concat(git_current_branch_cmd.result.stderr, " "))
      return nil
    end
    for _, line in ipairs(git_branches_cmd.result.stdout) do
      if vim.trim(line):sub(1, 1) ~= "*" then
        table.insert(results, string.format("  %s", vim.trim(line)))
      end
    end
    return results
  end

  return impl
end

local local_branch_provider = M._make_provider()
local remote_branch_provider = M._make_provider({ remote_branch = true })

M.providers = {
  local_branch = {
    key = "ctrl-o",
    provider = local_branch_provider,
    provider_type = ProviderTypeEnum.LIST,
  },
  remote_branch = {
    key = "ctrl-r",
    provider = remote_branch_provider,
    provider_type = ProviderTypeEnum.LIST,
  },
}

local GIT_LOG_PRETTY_FORMAT = "%C(yellow)%h %C(cyan)%cd %C(green)%aN%C(auto)%d %Creset%s"

--- @param line string
--- @param context fzfx.PipelineContext
--- @return string
M._previewer = function(line, context)
  local branch = str.split(line, " ")[1]
  return string.format(
    "git log --pretty=%s --graph --date=short --color=always %s",
    shells.shellescape(GIT_LOG_PRETTY_FORMAT),
    branch
  )
end

M.previewers = {
  local_branch = {
    previewer = M._previewer,
  },
  remote_branch = {
    previewer = M._previewer,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.git_checkout,
  ["double-click"] = actions_helper.git_checkout,
}

M.fzf_opts = {
  "--no-multi",
  { "--prompt", "Git Branches > " },
  function()
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      return nil
    end
    local git_current_branch_cmd = cmds.GitCurrentBranchCommand:run()
    if git_current_branch_cmd:failed() then
      return nil
    end
    return str.not_empty(git_current_branch_cmd:output()) and "--header-lines=1" or nil
  end,
}

-- This is actually for the "git checkout" actions.
--- @alias fzfx.GitBranchesPipelineContext {remotes:string[]|nil}
--- @return fzfx.GitBranchesPipelineContext
M._context_maker = function()
  local ctx = {}
  local git_remotes_cmd = cmds.GitRemotesCommand:run()
  if git_remotes_cmd:failed() then
    return ctx
  end
  ctx.remotes = git_remotes_cmd:output()
  return ctx
end

M.other_opts = {
  context_maker = M._context_maker,
}

return M
