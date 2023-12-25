local tables = require("fzfx.commons.tables")
local strings = require("fzfx.commons.strings")

local consts = require("fzfx.lib.constants")
local shells = require("fzfx.lib.shells")
local cmds = require("fzfx.lib.commands")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local actions_helper = require("fzfx.helper.actions")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.commands = {
  -- normal
  {
    name = "FzfxGBranches",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      desc = "Search local git branches",
    },
    default_provider = "local_branch",
  },
  {
    name = "FzfxGBranchesR",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      desc = "Search remote git branches",
    },
    default_provider = "remote_branch",
  },
  -- visual
  {
    name = "FzfxGBranchesV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Search local git branches by visual select",
    },
    default_provider = "local_branch",
  },
  {
    name = "FzfxGBranchesRV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Search remote git branches by visual select",
    },
    default_provider = "remote_branch",
  },
  -- cword
  {
    name = "FzfxGBranchesW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Search local git branches by cursor word",
    },
    default_provider = "local_branch",
  },
  {
    name = "FzfxGBranchesRW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Search remote git branches by cursor word",
    },
    default_provider = "remote_branch",
  },
  -- put
  {
    name = "FzfxGBranchesP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Search local git branches by yank text",
    },
    default_provider = "local_branch",
  },
  {
    name = "FzfxGBranchesRP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Search remote git branches by yank text",
    },
    default_provider = "remote_branch",
  },
  -- resume
  {
    name = "FzfxGBranchesR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Search local git branches by resume last",
    },
    default_provider = "local_branch",
  },
  {
    name = "FzfxGBranchesRR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Search remote git branches by resume last",
    },
    default_provider = "remote_branch",
  },
}

--- @param opts {remote_branch:boolean?}?
--- @return fun():string[]|nil
M._make_git_branches_provider = function(opts)
  --- @return string[]|nil
  local function impl()
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, "not in git repo.")
      return nil
    end
    local git_current_branch_cmd = cmds.GitCurrentBranchCommand:run()
    if git_current_branch_cmd:failed() then
      log.echo(
        LogLevels.WARN,
        table.concat(git_current_branch_cmd.result.stderr, " ")
      )
      return nil
    end
    local branch_results = {}
    table.insert(
      branch_results,
      string.format("* %s", git_current_branch_cmd:output())
    )
    local git_branches_cmd = cmds.GitBranchesCommand:run(
      tables.tbl_get(opts, "remote_branch") and true or false
    )
    if git_branches_cmd:failed() then
      log.echo(
        LogLevels.WARN,
        table.concat(git_current_branch_cmd.result.stderr, " ")
      )
      return nil
    end
    for _, line in ipairs(git_branches_cmd.result.stdout) do
      if vim.trim(line):sub(1, 1) ~= "*" then
        table.insert(branch_results, string.format("  %s", vim.trim(line)))
      end
    end
    return branch_results
  end
  return impl
end

local local_branch_provider = M._make_git_branches_provider()
local remote_branch_provider =
  M._make_git_branches_provider({ remote_branch = true })

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

local GIT_LOG_PRETTY_FORMAT =
  "%C(yellow)%h %C(cyan)%cd %C(green)%aN%C(auto)%d %Creset%s"

--- @param line string
--- @return string
M._git_branches_previewer = function(line)
  local branch = strings.split(line, " ")[1]
  -- "git log --graph --date=short --color=always --pretty='%C(auto)%cd %h%d %s'",
  -- "git log --graph --color=always --date=relative",
  return string.format(
    "git log --pretty=%s --graph --date=short --color=always %s",
    shells.shellescape(GIT_LOG_PRETTY_FORMAT),
    branch
  )
end

M.previewers = {
  local_branch = {
    previewer = M._git_branches_previewer,
  },
  remote_branch = {
    previewer = M._git_branches_previewer,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.git_checkout,
  ["double-click"] = actions_helper.git_checkout,
}

M.fzf_opts = {
  consts.FZF_OPTS.NO_MULTI,
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
    return strings.not_empty(git_current_branch_cmd:output())
        and "--header-lines=1"
      or nil
  end,
}

--- @alias fzfx.GitBranchesPipelineContext {remotes:string[]|nil}
--- @return fzfx.GitBranchesPipelineContext
M._git_branches_context_maker = function()
  local ctx = {}
  local git_remotes_cmd = cmds.GitRemotesCommand:run()
  if git_remotes_cmd:failed() then
    return ctx
  end
  ctx.remotes = git_remotes_cmd:output()
  return ctx
end

M.other_opts = {
  context_maker = M._git_branches_context_maker,
}

return M
