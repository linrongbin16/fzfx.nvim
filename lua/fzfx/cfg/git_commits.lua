local tbl = require("fzfx.commons.tbl")

local bufs = require("fzfx.lib.bufs")
local cmds = require("fzfx.lib.commands")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local actions_helper = require("fzfx.helper.actions")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local _git = require("fzfx.cfg._git")

local M = {}

M.command = {
  name = "FzfxGCommits",
  desc = "Search git commits",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "all_commits",
  },
  {
    name = "buf_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "buffer_commits",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "all_commits",
  },
  {
    name = "buf_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "buffer_commits",
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "all_commits",
  },
  {
    name = "buf_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "buffer_commits",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "all_commits",
  },
  {
    name = "buf_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "buffer_commits",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "all_commits",
  },
  {
    name = "buf_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "buffer_commits",
  },
}

M._GIT_LOG_CURRENT_BUFFER = {
  "git",
  "log",
  "--pretty=" .. _git.GIT_LOG_PRETTY_FORMAT,
  "--date=short",
  "--color=always",
  "--",
}

M._GIT_LOG_WORKSPACE = {
  "git",
  "log",
  "--pretty=" .. _git.GIT_LOG_PRETTY_FORMAT,
  "--date=short",
  "--color=always",
}

--- @param opts {buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
M._make_provider = function(opts)
  local buffer_mode = tbl.tbl_get(opts, "buffer") or false

  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local git_root_cmd = cmds.run_git_root_sync()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, "not in git repo.")
      return nil
    end
    local args
    if buffer_mode then
      if not bufs.buf_is_valid(context.bufnr) then
        log.echo(LogLevels.INFO, string.format("invalid buffer(%s).", vim.inspect(context.bufnr)))
        return nil
      end
      args = vim.deepcopy(M._GIT_LOG_CURRENT_BUFFER)
      table.insert(args, vim.api.nvim_buf_get_name(context.bufnr))
    else
      args = vim.deepcopy(M._GIT_LOG_WORKSPACE)
    end
    return args
  end
  return impl
end

local all_commits_provider = M._make_provider()
local buffer_commits_provider = M._make_provider({ buffer = true })

M.providers = {
  all_commits = {
    key = "ctrl-a",
    provider = all_commits_provider,
    provider_type = ProviderTypeEnum.COMMAND_ARRAY,
  },
  buffer_commits = {
    key = "ctrl-u",
    provider = buffer_commits_provider,
    provider_type = ProviderTypeEnum.COMMAND_ARRAY,
  },
}

M.previewers = {
  all_commits = {
    previewer = previewers_helper.preview_git_commit,
    previewer_type = PreviewerTypeEnum.COMMAND_STRING,
  },
  buffer_commits = {
    previewer = previewers_helper.preview_git_commit,
    previewer_type = PreviewerTypeEnum.COMMAND_STRING,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.yank_git_commit,
  ["double-click"] = actions_helper.yank_git_commit,
}

M.fzf_opts = {
  "--no-multi",
  { "--preview-window", "wrap" },
  { "--prompt", "Git Commits > " },
}

return M
