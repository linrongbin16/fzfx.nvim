local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")
local fio = require("fzfx.commons.fio")
local uv = require("fzfx.commons.uv")

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
  name = "FzfxColors",
  desc = "Search colorschemes",
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
--- @param context fzfx.VimColorsPipelineContext
--- @return string[]
local function _provider(query, context)
  local commands = M._get_commands(context, { ex_commands = true, user_commands = true })
  return M._render_lines(commands, context)
end

M.providers = {
  key = "default",
  provider = _provider,
  provider_type = ProviderTypeEnum.DIRECT,
}

M.previewers = {
  previewer = function() end,
  previewer_type = PreviewerTypeEnum.COMMAND_ARRAY,
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.feed_vim_command,
  ["double-click"] = actions_helper.feed_vim_command,
}

M.fzf_opts = {
  "--no-multi",
  "--header-lines=1",
  { "--preview-window", "~1" },
  { "--prompt", "Commands > " },
}

--- @alias fzfx.VimColorsPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,output_lines:string[],name_column_width:integer,opts_column_width:integer}
--- @return fzfx.VimColorsPipelineContext
M._context_maker = function()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }

  ctx.output_lines = M._get_commands_output_in_lines()
  local commands = M._get_commands(ctx, { ex_commands = true, user_commands = true })
  local name_column_width, opts_column_width = M._calculate_column_widths(commands)
  ctx.name_column_width = name_column_width
  ctx.opts_column_width = opts_column_width

  return ctx
end

M.other_opts = {
  context_maker = M._context_maker,
}

return M
