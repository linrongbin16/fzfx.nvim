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
    name = "FzfxGBlame",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      desc = "Search git commits",
    },
  },
  -- visual
  {
    name = "FzfxGBlameV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Search git commits by visual select",
    },
  },
  -- cword
  {
    name = "FzfxGBlameW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Search git commits by cursor word",
    },
  },
  -- put
  {
    name = "FzfxGBlameP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Search git commits by yank text",
    },
  },
  -- resume
  {
    name = "FzfxGBlameR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Search git commits by resume last",
    },
  },
}

--- @param query string
--- @param context fzfx.PipelineContext
--- @return string?
M._git_blame_provider = function(query, context)
  local git_root_cmd = cmds.GitRootCommand:run()
  if git_root_cmd:failed() then
    log.echo(LogLevels.INFO, "not in git repo.")
    return nil
  end
  if not nvims.buf_is_valid(context.bufnr) then
    log.echo(LogLevels.INFO, "invalid buffer(%s).", vim.inspect(context.bufnr))
    return nil
  end
  local bufname = vim.api.nvim_buf_get_name(context.bufnr)
  local bufpath = vim.fn.fnamemodify(bufname, ":~:.")
  if consts.HAS_DELTA then
    return string.format(
      [[git blame %s | delta -n --tabs 4 --blame-format %s]],
      nvims.shellescape(bufpath --[[@as string]]),
      nvims.shellescape("{commit:<8} {author:<15.14} {timestamp:<15}")
    )
  else
    return string.format(
      [[git blame --date=short --color-lines %s]],
      nvims.shellescape(bufpath --[[@as string]])
    )
  end
end

M.providers = {
  default = {
    key = "default",
    provider = M._git_blame_provider,
    provider_type = ProviderTypeEnum.COMMAND,
  },
}

M.previewers = {
  default = {
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
  { "--prompt", "Git Blame > " },
}

return M
