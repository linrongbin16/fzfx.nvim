-- ========== Context ==========
--
--- @alias fzfx.PipelineContext {bufnr:integer,winnr:integer,tabnr:integer}
--- @alias fzfx.PipelineContextMaker fun():fzfx.PipelineContext
--
--
-- ========== Provider ==========
--
--- @alias fzfx.PlainProvider string|string[]
--- @alias fzfx.CommandProvider fun(query:string?,context:fzfx.PipelineContext?):string?|string[]?
--- @alias fzfx.ListProvider fun(query:string?,context:fzfx.PipelineContext?):string[]?
--- @alias fzfx.Provider fzfx.PlainProvider|fzfx.CommandProvider|fzfx.ListProvider
---
--- @alias fzfx.ProviderType "plain"|"command"|"list"|"plain_list"|"command_list"
--- @enum fzfx.ProviderTypeEnum
local ProviderTypeEnum = {
  -- A lua string or strings list.
  PLAIN = "plain",
  PLAIN_LIST = "plain_list",
  -- A lua function, that returns a string or strings list.
  COMMAND = "command",
  COMMAND_LIST = "command_list",
  -- A lua function, that directly returns lines.
  LIST = "list",
}
--
-- Note: the 1st parameter 'query' is the user input query in fzf prompt.
--
--
-- ========== Provider Decorator ==========
--
--- @alias fzfx._FunctionProviderDecorator fun(line:string?):string?
--- @alias fzfx.ProviderDecorator {module:string,rtp:string?,builtin:boolean?}
--
-- Note: in `fzfx._FunctionProviderDecorator`, the 1st parameter `line` is the raw generated line from providers.
--
--
-- ========== Previewer ==========
--
--- @alias fzfx.CommandPreviewer fun(line:string?,context:fzfx.PipelineContext?):string?
--- @alias fzfx.ListPreviewer fun(line:string?,context:fzfx.PipelineContext?):string[]?
--- @alias fzfx.BufferFilePreviewerResult {filename:string,lineno:integer?,column:integer?}
--- @alias fzfx.BufferFilePreviewer fun(line:string?,context:fzfx.PipelineContext?):fzfx.BufferFilePreviewerResult?
--- @alias fzfx.Previewer fzfx.CommandPreviewer|fzfx.ListPreviewer|fzfx.BufferFilePreviewer
---
--- @alias fzfx.PreviewerType "command"|"command_list"|"list"|"buffer_file"
--- @enum fzfx.PreviewerTypeEnum
local PreviewerTypeEnum = {
  COMMAND = "command",
  COMMAND_LIST = "command_list",
  LIST = "list",
  BUFFER_FILE = "buffer_file",
}
--
-- Note: the 1st parameter 'line' is the current selected line in (the left side of) the fzf binary.
--
--
-- ========== Previewer Label ==========
--
--- @alias fzfx.PlainPreviewerLabel string
--- @alias fzfx.FunctionPreviewerLabel fun(line:string?,context:fzfx.PipelineContext?):string?
--- @alias fzfx.PreviewerLabel fzfx.PlainPreviewerLabel|fzfx.FunctionPreviewerLabel
---
--- @alias fzfx.PreviewerLabelType "plain"|"function"
--- @enum PreviewerLabelTypeEnum
local PreviewerLabelTypeEnum = {
  PLAIN = "plain",
  FUNCTION = "function",
}
--
-- Note: the 1st parameter 'line' is the current selected line in (the left side of) the fzf binary.
--
--
-- ========== Command Feed ==========
--
--- @alias fzfx.CommandFeed "args"|"visual"|"cword"|"put"|"resume"
--- @enum fzfx.CommandFeedEnum
local CommandFeedEnum = {
  ARGS = "args",
  VISUAL = "visual",
  CWORD = "cword",
  PUT = "put",
  RESUME = "resume",
}
--
--
-- ========== Fzf Option ==========
--
--- @alias fzfx.PlainFzfOpt string
--- @alias fzfx.PairFzfOpt string[]
--- @alias fzfx.FunctionFzfOpt fun():fzfx.PlainFzfOpt|fzfx.PairFzfOpt
---
--- @alias fzfx.FzfOpt fzfx.PlainFzfOpt|fzfx.PairFzfOpt|fzfx.FunctionFzfOpt
--
--
-- ========== Interaction/Action ==========
--
--- @alias fzfx.ActionKey string
--- @alias fzfx.Interaction fun(line:string?,context:fzfx.PipelineContext):any
--- @alias fzfx.Action fun(line:string[]|nil,context:fzfx.PipelineContext):any
--
-- Note: the 1st parameter in `Interaction` is the current line.
-- Note: the 1st parameter in `Action` is the selected line(s).
--
--
-- ========== Config ==========
--
--- @alias fzfx.ProviderConfig {key:fzfx.ActionKey,provider:fzfx.Provider,provider_type:fzfx.ProviderType?,provider_decorator:fzfx.ProviderDecorator?}
--- The 'provider_type' by default is "plain"

--- @alias fzfx.PreviewerConfig {previewer:fzfx.Previewer,previewer_type:fzfx.PreviewerType?,previewer_label:fzfx.PreviewerLabel?,previewer_label_type:fzfx.PreviewerLabelType?}

--- @alias fzfx.PipelineName string
-- a pipeline name is a provider name, a previewer name
--
--- @alias fzfx.InteractionName string
--
--- @alias fzfx.InteractionConfig {key:fzfx.ActionKey,interaction:fzfx.Interaction,reload_after_execute:boolean?}
--
--- @alias fzfx.VariantConfig {name:string,feed:fzfx.CommandFeed,default_provider:fzfx.PipelineName?}
--
--- @alias fzfx.CommandConfig {name:string,desc:string?}
--
--- @alias fzfx.GroupConfig {command:fzfx.CommandConfig,variants:fzfx.VariantConfig[],providers:fzfx.ProviderConfig|table<fzfx.PipelineName,fzfx.ProviderConfig>,previewers:fzfx.PreviewerConfig|table<fzfx.PipelineName,fzfx.PreviewerConfig>,actions:table<fzfx.ActionKey,fzfx.Action>,interactions:table<fzfx.InteractionName,fzfx.InteractionConfig>?,fzf_opts:fzfx.FzfOpt[]?}

--- @param cfg fzfx.VariantConfig?
--- @return boolean
local function is_variant_config(cfg)
  return type(cfg) == "table"
    and type(cfg.name) == "string"
    and string.len(cfg.name) > 0
    and type(cfg.feed) == "string"
    and string.len(cfg.feed) > 0
end

--- @param cfg fzfx.ProviderConfig?
--- @return boolean
local function is_provider_config(cfg)
  return type(cfg) == "table"
    and type(cfg.key) == "string"
    and string.len(cfg.key) > 0
    and (
      (
        type(cfg.provider) == "string" and string.len(cfg.provider --[[@as string]]) > 0
      )
      or (type(cfg.provider) == "table" and #cfg.provider > 0)
      or type(cfg.provider) == "function"
    )
end

--- @param cfg fzfx.PreviewerConfig?
--- @return boolean
local function is_previewer_config(cfg)
  return type(cfg) == "table"
    and type(cfg.previewer) == "function"
    and (
      cfg.previewer_type == nil
      or (type(cfg.previewer_type) == "string" and string.len(cfg.previewer_type) > 0)
    )
end

--- @param provider_config fzfx.ProviderConfig
--- @return fzfx.ProviderType
local function get_provider_type_or_default(provider_config)
  return provider_config.provider_type
    or (
      type(provider_config.provider) == "string" and ProviderTypeEnum.PLAIN
      or ProviderTypeEnum.PLAIN_LIST
    )
end

--- @param previewer_config fzfx.PreviewerConfig
--- @return fzfx.PreviewerType
local function get_previewer_type_or_default(previewer_config)
  return previewer_config.previewer_type or PreviewerTypeEnum.COMMAND
end

--- @param previewer_config fzfx.PreviewerConfig
--- @return fzfx.PreviewerLabelType
local function get_previewer_label_type_or_default(previewer_config)
  return previewer_config.previewer_label_type
    or (
      type(previewer_config.previewer_label) == "function" and PreviewerLabelTypeEnum.FUNCTION
      or PreviewerLabelTypeEnum.PLAIN
    )
end

local M = {
  ProviderTypeEnum = ProviderTypeEnum,
  PreviewerTypeEnum = PreviewerTypeEnum,
  PreviewerLabelTypeEnum = PreviewerLabelTypeEnum,
  CommandFeedEnum = CommandFeedEnum,

  is_variant_config = is_variant_config,
  is_provider_config = is_provider_config,
  is_previewer_config = is_previewer_config,

  get_provider_type_or_default = get_provider_type_or_default,
  get_previewer_type_or_default = get_previewer_type_or_default,
  get_previewer_label_type_or_default = get_previewer_label_type_or_default,
}

return M
