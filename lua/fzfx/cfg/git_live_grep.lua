local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")
local cmds = require("fzfx.lib.commands")
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
    name = "FzfxGLiveGrep",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "*",
      desc = "Git live grep",
    },
  },
  -- visual
  {
    name = "FzfxGLiveGrepV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Git live grep by visual select",
    },
  },
  -- cword
  {
    name = "FzfxGLiveGrepW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Git live grep by cursor word",
    },
  },
  -- put
  {
    name = "FzfxGLiveGrepP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Git live grep by yank text",
    },
  },
  -- resume
  {
    name = "FzfxGLiveGrepR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Git live grep by resume last",
    },
  },
}

--- @param query string?
--- @param context fzfx.PipelineContext
--- @return string[]|nil
M._git_live_grep_provider = function(query, context)
  local git_root_cmd = cmds.GitRootCommand:run()
  if git_root_cmd:failed() then
    log.echo(LogLevels.INFO, "not in git repo.")
    return nil
  end

  local parsed = queries_helper.parse_flagged(query or "")
  local payload = parsed.payload
  local option = parsed.option

  local args = { "git", "grep", "--color=always", "-n" }
  if type(option) == "string" and string.len(option) > 0 then
    local option_splits = strs.split(option, " ")
    for _, o in ipairs(option_splits) do
      if type(o) == "string" and string.len(o) > 0 then
        table.insert(args, o)
      end
    end
  end
  table.insert(args, payload)
  return args
end

M.providers = {
  key = "default",
  provider = M._git_live_grep_provider,
  provider_type = ProviderTypeEnum.COMMAND_LIST,
  provider_decorator = { module = "prepend_icon_grep", builtin = true },
}

M.previewers = {
  previewer = previewers_helper.preview_files_grep,
  previewer_type = PreviewerTypeEnum.COMMAND_LIST,
  previewer_label = labels_helper.label_grep,
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_grep,
  ["double-click"] = actions_helper.edit_grep,
  ["ctrl-q"] = actions_helper.setqflist_grep,
}

M.fzf_opts = {
  consts.FZF_OPTS.MULTI,
  consts.FZF_OPTS.DISABLED,
  consts.FZF_OPTS.DELIMITER,
  consts.FZF_OPTS.GREP_PREVIEW_WINDOW,
  { "--prompt", "Git Live Grep > " },
}

M.other_opts = {
  reload_on_change = true,
}

return M
