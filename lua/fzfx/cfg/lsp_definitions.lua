local consts = require("fzfx.lib.constants")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local _lsp_locations = require("fzfx.cfg._lsp_locations")
local _decorator = require("fzfx.cfg._decorator")

local M = {}

M.command = {
  name = "FzfxLspDefinitions",
  desc = "Search lsp definitions",
}

M.variants = {
  name = "args",
  feed = CommandFeedEnum.ARGS,
}

M.providers = {
  key = "default",
  provider = _lsp_locations._make_lsp_locations_provider({
    method = "textDocument/definition",
    capability = "definitionProvider",
  }),
  provider_type = ProviderTypeEnum.DIRECT,
  provider_decorator = { module = _decorator.PREPEND_ICON_GREP },
}

M.fzf_opts = {
  "--multi",
  { "--delimiter", ":" },
  { "--preview-window", "left,65%,+{2}-/2" },
  "--border=none",
  { "--prompt", "Definitions > " },
}

M.previewers = _lsp_locations.previewers

M.actions = _lsp_locations.actions

M.win_opts = _lsp_locations.win_opts

M.other_opts = _lsp_locations.other_opts

return M
