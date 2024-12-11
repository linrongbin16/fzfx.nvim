local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")
local fileio = require("fzfx.commons.fileio")

local consts = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.command = {
  name = "FzfxCommandHistory",
  desc = "Search command history",
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
--- @return string[]|nil
M._provider = function(query, context)
  local n = vim.fn.histnr(":")
  if type(n) ~= "number" or n <= 0 then
    log.echo(LogLevels.INFO, "no command history.")
    return nil
  end
  local index_fmt = " %" .. string.len(tostring(n)) .. "d"
  local results = {}
  for i = 1, n do
    local value = vim.fn.histget(":", -i)
    if str.not_blank(value) then
      table.insert(results, string.format(index_fmt, i) .. "  " .. value)
    end
  end
  return results
end

M.providers = {
  key = "default",
  provider = M._provider,
  provider_type = ProviderTypeEnum.LIST,
}

--- @param line string
--- @param context fzfx.PipelineContext
--- @return string|nil
M._previewer = function(line, context)
  return nil
end

M.previewers = {
  key = "default",
  previewer = M._previewer,
  previewer_type = PreviewerTypeEnum.COMMAND,
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.feed_vim_command,
  ["double-click"] = actions_helper.feed_vim_command,
}

M.fzf_opts = {
  "--no-multi",
  -- "--header-lines=1",
  -- { "--preview-window", "~1" },
  { "--prompt", "Command History (:) > " },
}

return M
