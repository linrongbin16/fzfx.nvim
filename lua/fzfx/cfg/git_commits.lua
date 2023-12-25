local consts = require("fzfx.lib.constants")
local bufs = require("fzfx.lib.bufs")
local cmds = require("fzfx.lib.commands")
local tbls = require("fzfx.lib.tables")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local actions_helper = require("fzfx.helper.actions")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.commands = {
  -- normal
  {
    name = "FzfxGCommits",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      desc = "Search git commits",
    },
    default_provider = "all_commits",
  },
  {
    name = "FzfxGCommitsB",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      desc = "Search git commits on current buffer",
    },
    default_provider = "buffer_commits",
  },
  -- visual
  {
    name = "FzfxGCommitsV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Search git commits by visual select",
    },
    default_provider = "all_commits",
  },
  {
    name = "FzfxGCommitsBV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Search git commits on current buffer by visual select",
    },
    default_provider = "buffer_commits",
  },
  -- cword
  {
    name = "FzfxGCommitsW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Search git commits by cursor word",
    },
    default_provider = "all_commits",
  },
  {
    name = "FzfxGCommitsBW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Search git commits on current buffer by cursor word",
    },
    default_provider = "buffer_commits",
  },
  -- put
  {
    name = "FzfxGCommitsP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Search git commits by yank text",
    },
    default_provider = "all_commits",
  },
  {
    name = "FzfxGCommitsBP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Search git commits on current buffer by yank text",
    },
    default_provider = "buffer_commits",
  },
  -- resume
  {
    name = "FzfxGCommitsR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Search git commits by resume last",
    },
    default_provider = "all_commits",
  },
  {
    name = "FzfxGCommitsBR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Search git commits on current buffer by resume last",
    },
    default_provider = "buffer_commits",
  },
}

local GIT_LOG_PRETTY_FORMAT =
  "%C(yellow)%h %C(cyan)%cd %C(green)%aN%C(auto)%d %Creset%s"

--- @param opts {buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
M._make_git_commits_provider = function(opts)
  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, "not in git repo.")
      return nil
    end
    if tbls.tbl_get(opts, "buffer") then
      if not bufs.buf_is_valid(context.bufnr) then
        log.echo(
          LogLevels.INFO,
          "invalid buffer(%s).",
          vim.inspect(context.bufnr)
        )
        return nil
      end
      return {
        "git",
        "log",
        "--pretty=" .. GIT_LOG_PRETTY_FORMAT,
        "--date=short",
        "--color=always",
        "--",
        vim.api.nvim_buf_get_name(context.bufnr),
      }
    else
      return {
        "git",
        "log",
        "--pretty=" .. GIT_LOG_PRETTY_FORMAT,
        "--date=short",
        "--color=always",
      }
    end
  end
  return impl
end

local all_commits_provider = M._make_git_commits_provider()
local buffer_commits_provider = M._make_git_commits_provider({ buffer = true })

M.providers = {
  all_commits = {
    key = "ctrl-a",
    provider = all_commits_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
  },
  buffer_commits = {
    key = "ctrl-u",
    provider = buffer_commits_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
  },
}

M.previewers = {
  all_commits = {
    previewer = previewers_helper.preview_git_commit,
  },
  buffer_commits = {
    previewer = previewers_helper.preview_git_commit,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.yank_git_commit,
  ["double-click"] = actions_helper.yank_git_commit,
}

M.fzf_opts = {
  consts.FZF_OPTS.NO_MULTI,
  { "--preview-window", "wrap" },
  { "--prompt", "Git Commits > " },
}

return M
