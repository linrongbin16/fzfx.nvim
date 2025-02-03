local shells = require("fzfx.lib.shells")
local constants = require("fzfx.lib.constants")
local bufs = require("fzfx.lib.bufs")
local cmds = require("fzfx.lib.commands")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local actions_helper = require("fzfx.helper.actions")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.command = {
  name = "FzfxGBlame",
  desc = "Search git blame",
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

--- @param query string
--- @param context fzfx.GitBlamePipelineContext
--- @return string?
M._provider = function(query, context)
  local git_root_cmd = context.git_root_cmd
  if git_root_cmd:failed() then
    log.echo(LogLevels.INFO, "not in git repo.")
    return nil
  end
  if not bufs.buf_is_valid(context.bufnr) then
    log.echo(LogLevels.INFO, string.format("invalid buffer(%s).", vim.inspect(context.bufnr)))
    return nil
  end
  local bufname = vim.api.nvim_buf_get_name(context.bufnr)
  local bufpath = vim.fn.fnamemodify(bufname, ":~:.")
  if constants.HAS_DELTA then
    return string.format(
      [[git blame %s | delta -n --tabs 4 --blame-format %s]],
      vim.fn.fnameescape(bufpath --[[@as string]]),
      shells.escape("{commit:<8} {author:<15.14} {timestamp:<15}")
    )
  else
    return string.format(
      [[git blame --date=short --color-lines %s]],
      vim.fn.fnameescape(bufpath --[[@as string]])
    )
  end
end

M.providers = {
  default = {
    key = "default",
    provider = M._provider,
    provider_type = ProviderTypeEnum.COMMAND_STRING,
  },
}

M.previewers = {
  default = {
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
  { "--prompt", "Git Blame > " },
}

--- @alias fzfx.GitBlamePipelineContext {bufnr:integer,winnr:integer,tabnr:integer,git_root_cmd:fzfx.CommandResult}
--- @return fzfx.GitBlamePipelineContext
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
}

return M
