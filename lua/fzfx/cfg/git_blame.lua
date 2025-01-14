local constants = require("fzfx.lib.constants")
local shells = require("fzfx.lib.shells")
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
--- @param context fzfx.PipelineContext
--- @return string?
M._provider = function(query, context)
  local git_root_cmd = cmds.GitRootCommand:run()
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
      shells.shellescape(bufpath --[[@as string]]),
      shells.shellescape("{commit:<8} {author:<15.14} {timestamp:<15}")
    )
  else
    return string.format(
      [[git blame --date=short --color-lines %s]],
      shells.shellescape(bufpath --[[@as string]])
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
    previewer = previewers_helper.fzf_preview_git_commit,
    previewer_type = PreviewerTypeEnum.FUNCTIONAL_COMMAND_STRING,
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

return M
