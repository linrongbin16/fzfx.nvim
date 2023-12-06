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

local _lsp_locations = require("fzfx.cfg._lsp_locations")

local M = {}

M.commands = {
  name = "FzfxLspOutgoingCalls",
  feed = CommandFeedEnum.ARGS,
  opts = {
    bang = true,
    desc = "Search lsp outgoing calls",
  },
}

M.providers = {
  key = "default",
  provider = _lsp_locations._make_lsp_call_hierarchy_provider({
    method = "callHierarchy/outgoingCalls",
    capability = "callHierarchyProvider",
  }),
  provider_type = ProviderTypeEnum.LIST,
  line_opts = {
    prepend_icon_by_ft = true,
    prepend_icon_path_delimiter = ":",
    prepend_icon_path_position = 1,
  },
}

M.previewers = _lsp_locations.previewers

M.actions = _lsp_locations.actions

M.win_opts = _lsp_locations.win_opts

M.other_opts = _lsp_locations.other_opts

M.fzf_opts = {
  consts.FZF_OPTS.MULTI,
  consts.FZF_OPTS.LSP_PREVIEW_WINDOW,
  consts.FZF_OPTS.DELIMITER,
  "--border=none",
  { "--prompt", "Outgoing Calls > " },
}

return M
