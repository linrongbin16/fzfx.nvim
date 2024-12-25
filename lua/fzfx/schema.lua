-- ========== Context ==========
--
--- @alias fzfx.PipelineContext {bufnr:integer,winnr:integer,tabnr:integer}
--- @alias fzfx.PipelineContextMaker fun():fzfx.PipelineContext
--
--
-- ========== Provider ==========
--
--- @alias fzfx.PlainCommandStringProvider string?
--- @alias fzfx.PlainCommandArrayProvider string[]?
--- @alias fzfx.FunctionalCommandStringProvider fun(query:string?,context:fzfx.PipelineContext?):string?
--- @alias fzfx.FunctionalCommandArrayProvider fun(query:string?,context:fzfx.PipelineContext?):string[]?
--- @alias fzfx.DirectProvider fun(query:string?,context:fzfx.PipelineContext?):string[]?
--- @alias fzfx.AsyncDirectProvider fun(query:string?,context:fzfx.PipelineContext?,on_complete:fun(data:string[]|nil):nil):nil
--- @alias fzfx.Provider fzfx.PlainCommandStringProvider|fzfx.PlainCommandArrayProvider|fzfx.FunctionalCommandStringProvider|fzfx.FunctionalCommandArrayProvider|fzfx.DirectProvider
---
--- @alias fzfx.ProviderType "PLAIN_COMMAND_STRING"|"PLAIN_COMMAND_ARRAY"|"FUNCTIONAL_COMMAND_STRING"|"FUNCTIONAL_COMMAND_ARRAY"|"DIRECT"|"ASYNC_DIRECT"
--- @enum fzfx.ProviderTypeEnum
local ProviderTypeEnum = {
  PLAIN_COMMAND_STRING = "PLAIN_COMMAND_STRING",
  PLAIN_COMMAND_ARRAY = "PLAIN_COMMAND_ARRAY",
  FUNCTIONAL_COMMAND_STRING = "FUNCTIONAL_COMMAND_STRING",
  FUNCTIONAL_COMMAND_ARRAY = "FUNCTIONAL_COMMAND_ARRAY",
  DIRECT = "DIRECT",
  ASYNC_DIRECT = "ASYNC_DIRECT",
}
--
-- ========== Provider Decorator ==========
--
--- @alias fzfx._FunctionalProviderDecorator fun(line:string?):string?
--- @alias fzfx.ProviderDecorator {module:string,rtp:string?}
--
-- ========== Previewer ==========
--
--- @alias fzfx.FunctionalCommandStringPreviewer fun(line:string?,context:fzfx.PipelineContext?):string?
--- @alias fzfx.FunctionalCommandArrayPreviewer fun(line:string?,context:fzfx.PipelineContext?):string[]?
--- @alias fzfx.BufferPreviewerResult {filename:string,lineno:integer?,column:integer?}
--- @alias fzfx.BufferPreviewer fun(line:string?,context:fzfx.PipelineContext?):fzfx.BufferPreviewerResult?
--- @alias fzfx.Previewer fzfx.FunctionalCommandStringPreviewer|fzfx.FunctionalCommandArrayPreviewer|fzfx.BufferPreviewer
---
--- @alias fzfx.PreviewerType "FUNCTIONAL_COMMAND_STRING"|"FUNCTIONAL_COMMAND_ARRAY"|"BUFFER"
--- @enum fzfx.PreviewerTypeEnum
local PreviewerTypeEnum = {
  FUNCTIONAL_COMMAND_STRING = "FUNCTIONAL_COMMAND_STRING",
  FUNCTIONAL_COMMAND_ARRAY = "FUNCTIONAL_COMMAND_ARRAY",
  BUFFER = "BUFFER",
}
--
-- ========== Previewer Label ==========
--
--- @alias fzfx.PreviewerLabel fun(line:string?,context:fzfx.PipelineContext?):string?
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
-- ========== Fzf Option ==========
--
--- @alias fzfx.PlainFzfOpt string
--- @alias fzfx.PairFzfOpt string[]
--- @alias fzfx.FunctionFzfOpt fun():fzfx.PlainFzfOpt|fzfx.PairFzfOpt
---
--- @alias fzfx.FzfOpt fzfx.PlainFzfOpt|fzfx.PairFzfOpt|fzfx.FunctionFzfOpt
--
-- ========== Interaction/Action ==========
--
--- @alias fzfx.ActionKey string
-- Note: The 1st parameter in `Interaction` is the current line.
--- @alias fzfx.Interaction fun(line:string?,context:fzfx.PipelineContext):any
-- Note: The 1st parameter in `Action` is the selected line(s).
--- @alias fzfx.Action fun(line:string[]|nil,context:fzfx.PipelineContext):any
--
-- ========== Config ==========
--
-- Note:
-- 1. The "key" option is to press and switch to this provider. For example in "FzfxFiles" command, user press "CTRL-U" to switch to **unrestricted mode**, press "CTRL-R" to switch to **restricted mode** (here a **mode** is actually a provider).
-- 2. The "provider" option is the **provider** we mentioned above, that provides the data source, i.e. the lines (in the left side) of fzf binary.
-- 3. The "provider_type" option by default is "plain" or "plain_list". Also see "get_provider_type_or_default" function in below.
-- 4. The "provider_decorator" option is optional.
--- @alias fzfx.ProviderConfig {key:fzfx.ActionKey,provider:fzfx.Provider,provider_type:fzfx.ProviderType?,provider_decorator:fzfx.ProviderDecorator?}
--
-- Note:
-- 1. The "previewer" option is the **previewer** we mentioned above, that previews the content of the current line, i.e. generates lines (in the right side) of fzf binary.
-- 2. The "previewer_type" option by default "command". Also see "get_previewer_type_or_default" function in below.
-- 3. The "previewer_label" option is optional.
--- @alias fzfx.PreviewerConfig {previewer:fzfx.Previewer,previewer_type:fzfx.PreviewerType?,previewer_label:fzfx.PreviewerLabel?}
---
--
-- Note: A pipeline name is the same with the provider name.
--- @alias fzfx.PipelineName string
--
--- @alias fzfx.InteractionName string
--
-- Note:
-- 1. The "key" option is to press and invokes the binded lua function.
-- 2. The "interaction" option is the **interaction** we mentioned above.
-- 3. The "reload_after_execute" option is to tell fzf binary, that reloads the query after execute this interaction.
--- @alias fzfx.InteractionConfig {key:fzfx.ActionKey,interaction:fzfx.Interaction,reload_after_execute:boolean?}
---
-- Note: Please refer to the command configurations in "fzfx.cfg" packages for the usage.
--- @alias fzfx.VariantConfig {name:string,feed:fzfx.CommandFeed,default_provider:fzfx.PipelineName?}
--
-- Note: Please refer to the command configurations in "fzfx.cfg" packages for the usage.
--- @alias fzfx.CommandConfig {name:string,desc:string?}
--
-- Note: Please refer to the command configurations in "fzfx.cfg" packages for the usage.
--- @alias fzfx.GroupConfig {command:fzfx.CommandConfig,variants:fzfx.VariantConfig[],providers:fzfx.ProviderConfig|table<fzfx.PipelineName,fzfx.ProviderConfig>,previewers:fzfx.PreviewerConfig|table<fzfx.PipelineName,fzfx.PreviewerConfig>,actions:table<fzfx.ActionKey,fzfx.Action>,interactions:table<fzfx.InteractionName,fzfx.InteractionConfig>?,fzf_opts:fzfx.FzfOpt[]?}

-- Whether `cfg` is a `fzfx.VariantConfig` instance.
--- @param cfg fzfx.VariantConfig?
--- @return boolean
local function is_variant_config(cfg)
  return type(cfg) == "table"
    and type(cfg.name) == "string"
    and string.len(cfg.name) > 0
    and type(cfg.feed) == "string"
    and string.len(cfg.feed) > 0
end

-- Whether `cfg` is a `fzfx.ProviderConfig` instance.
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

-- Whether `cfg` is a `fzfx.PreviewerConfig` instance.
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

-- Get provider type or default.
--- @param provider_config fzfx.ProviderConfig
--- @return fzfx.ProviderType
local function get_provider_type_or_default(provider_config)
  return provider_config.provider_type
    or (
      type(provider_config.provider) == "string" and ProviderTypeEnum.PLAIN_COMMAND_STRING
      or ProviderTypeEnum.PLAIN_COMMAND_ARRAY
    )
end

-- Get previewer type or default.
--- @param previewer_config fzfx.PreviewerConfig
--- @return fzfx.PreviewerType
local function get_previewer_type_or_default(previewer_config)
  return previewer_config.previewer_type or PreviewerTypeEnum.FUNCTIONAL_COMMAND_STRING
end

local M = {
  ProviderTypeEnum = ProviderTypeEnum,
  PreviewerTypeEnum = PreviewerTypeEnum,
  CommandFeedEnum = CommandFeedEnum,

  is_variant_config = is_variant_config,
  is_provider_config = is_provider_config,
  is_previewer_config = is_previewer_config,

  get_provider_type_or_default = get_provider_type_or_default,
  get_previewer_type_or_default = get_previewer_type_or_default,
}

return M
