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

local contexts_helper = require("fzfx.helper.contexts")
local parsers_helper = require("fzfx.helper.parsers")
local queries_helper = require("fzfx.helper.queries")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local providers_helper = require("fzfx.helper.providers")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local _lsp_locations = require("fzfx.cfg._lsp_locations")

local M = {}

M.commands = {
  name = "FzfxLspDefinitions",
  feed = CommandFeedEnum.ARGS,
  opts = {
    bang = true,
    desc = "Search lsp definitions",
  },
}

M.providers = {
  key = "default",
  provider = _lsp_locations.make_lsp_locations_provider({
    method = "textDocument/definition",
    capability = "definitionProvider",
  }),
  provider_type = ProviderTypeEnum.LIST,
  line_opts = {
    prepend_icon_by_ft = true,
    prepend_icon_path_delimiter = ":",
    prepend_icon_path_position = 1,
  },
}

M.previewers = {
  previewer = previewers_helper.preview_files_grep,
  previewer_type = PreviewerTypeEnum.COMMAND_LIST,
  previewer_label = labels_helper.label_rg,
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_rg,
  ["double-click"] = actions_helper.edit_rg,
}

M.fzf_opts = {
  consts.FZF_OPTS.MULTI,
  consts.FZF_OPTS.LSP_PREVIEW_WINDOW,
  consts.FZF_OPTS.DELIMITER,
  "--border=none",
  { "--prompt", "Definitions > " },
}

M.win_opts = {
  relative = "cursor",
  height = 0.45,
  width = 1,
  row = 1,
  col = 0,
  border = "none",
  zindex = 51,
}

M.other_opts = {
  context_maker = _lsp_locations.lsp_position_context_maker,
}

return M
