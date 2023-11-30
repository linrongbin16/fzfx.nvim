-- Schema
-- See: https://github.com/linrongbin16/fzfx.nvim/wiki/A-General-Schema-for-Creating-FZF-Command
--
-- ========== Provider ==========
--
-- A provider is a shell command that run and generate the lines list for fzf (e.g. things on the left side).
-- We have 3 types of providers:
--  * Plain provider: a simple command string to execute and generate the lines list for fzf.
--  * Command provider: a lua function to run and generate the command string, execute it and generate the lines.
--  * List provider: a lua function to run and directly generate the lines.
--
-- The 1st parameter 'query' is the query in fzf prompt.
-- The 2nd parameter 'context' contains information before this plugin start.
-- E.g. the bufnr, winnr before this plugin start.
-- Since some providers will need the context before plugin starting, for example some buffer only commands needs the buffer number before plugin start.
--
--- @class fzfx.PipelineContext
--- @field bufnr integer
--- @field winnr integer
--- @field tabnr integer
--- ...
--
--- @alias fzfx.PipelineContextMaker fun():fzfx.PipelineContext
--
--- @alias fzfx.PlainProvider string|string[]
--- @alias fzfx.CommandProvider fun(query:string?,context:fzfx.PipelineContext?):string?|string[]?
--- @alias fzfx.ListProvider fun(query:string?,context:fzfx.PipelineContext?):string[]?
--
--- @alias fzfx.Provider fzfx.PlainProvider|fzfx.CommandProvider|fzfx.ListProvider
--- @alias fzfx.ProviderType "plain"|"command"|"list"|"plain_list"|"command_list"
--- @enum fzfx.ProviderTypeEnum
local ProviderTypeEnum = {
  PLAIN = "plain",
  PLAIN_LIST = "plain_list",
  COMMAND = "command",
  COMMAND_LIST = "command_list",
  LIST = "list",
}

-- ========== Previewer ==========
--
-- A previewer is a shell command that run and echo details for fzf (e.g. things on the right side).
-- We have 3 types of previewers:
--  * Command previewer: a lua function that generate a command string to execute and echo details.
--  * List previewer: a lua function that directly generate a list of strings.
--  * Buffer previewer (todo): a nvim buffer & window, I think the biggest benefits can be allowing users to navigate to the buffer and edit it directly.
--
-- The BufferPreviewer returns the configs for the nvim window.
--
--- @alias fzfx.CommandPreviewer fun(line:string?,context:fzfx.PipelineContext?):string?
--- @alias fzfx.ListPreviewer fun(line:string?,context:fzfx.PipelineContext?):string[]?
--- @alias fzfx.BufferPreviewer fun(line:string?,context:fzfx.PipelineContext?):table?
--
--- @alias fzfx.Previewer fzfx.CommandPreviewer|fzfx.ListPreviewer|fzfx.BufferPreviewer
--- @alias fzfx.PreviewerType "command"|"command_list"|"list"|"buffer"
--- @enum fzfx.PreviewerTypeEnum
local PreviewerTypeEnum = {
  COMMAND = "command",
  COMMAND_LIST = "command_list",
  LIST = "list",
}

-- ========== Previewer Label ==========
--
-- A previewer label is the label/title of the preview window.
-- We have 2 types of previewers:
--  * Plain previewer: a simple string which is the label/title of the preview window.
--  * Function previewer: a lua function to run and generate the string for the preview window.
--
--- @alias fzfx.PlainPreviewerLabel string
--- @alias fzfx.FunctionPreviewerLabel fun(line:string?,context:fzfx.PipelineContext?):string?
--- @alias fzfx.PreviewerLabel fzfx.PlainPreviewerLabel|fzfx.FunctionPreviewerLabel
--- @alias fzfx.PreviewerLabelType "plain"|"function"
--- @enum PreviewerLabelTypeEnum
local PreviewerLabelTypeEnum = {
  PLAIN = "plain",
  FUNCTION = "function",
}

-- ========== Command Option ==========
--
-- User command options are something that passing to nvim user command lua api.
-- See:
--  * https://neovim.io/doc/user/api.html#nvim_create_user_command()
--  * https://neovim.io/doc/user/map.html#command-attributes
--
--- @alias fzfx.CommandOptKey "nargs"|"bang"|"complete"|"desc"|"range"
--- @alias fzfx.CommandOptValue string|boolean
--- @alias fzfx.CommandOpt table<fzfx.CommandOptKey, fzfx.CommandOptValue>

-- ========== Command Feed ==========
--
-- User command feeds are method that what to feed the fzfx command.
-- E.g. visual selected, cursor word, etc.
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

-- ========== Fzf Option ==========
--
-- A fzf option is passing directly to the final fzf command (e.g. --multi, --bind=ctrl-e:toggle).
-- We have 3 types of fzf options:
--  * Plain fzf option: a simple string, e.g. '--multi'.
--  * Pair fzf option: a list of two strings, e.g. { '--bind', 'ctrl-e:toggle' }.
--  * Function fzf option: a lua function that run and generate above two kinds of fzf options.
--
--- @alias fzfx.PlainFzfOpt string
--- @alias fzfx.PairFzfOpt string[]
--- @alias fzfx.FunctionFzfOpt fun():fzfx.PlainFzfOpt|fzfx.PairFzfOpt
--
--- @alias fzfx.FzfOpt fzfx.PlainFzfOpt|fzfx.PairFzfOpt|fzfx.FunctionFzfOpt

-- ========== Action ==========
--
-- An action is user press a key and we do something.
-- We have 2 types of actions:
--  * Interaction: interactively do something on current line without exit fzf.
--  * Action: exit fzf and invoke lua callback with selected lines.
--
--- @alias fzfx.ActionKey string
--- @alias fzfx.Interaction fun(line:string?,context:fzfx.PipelineContext):any
--- @alias fzfx.Action fun(line:string[]|nil,context:fzfx.PipelineContext):any

-- ========== Pipeline ==========
--
-- A pipeline binds a provider with a previewer, with a interactive action to switch the data sources, and the help message.
-- (Note: when you only have 1 provider, the interaction key and help message can be omitted).
-- The provider-interaction-previewer is a pipeline/dataflow.
--
-- See below `GroupConfig`.

-- ========== Commands Group ==========
--
-- Finally a commands group defines the real-world command we are using, e.g. `FzfxLiveGrep`, `FzfxFiles`, etc.
-- The command is powerful:
--
--  - It has multiple data sources from different providers, switch by different interactive keys.
--  - It has multiple previewers, bind to a specific provider.
--  - It has multiple action keys to exit fzf and invoke lua callbacks with selected lines.
--  - (Optionally) It has multiple interactive keys to do something without exiting fzf.
--  - (Optionally) It has some extra fzf options and other options for some specific abilities.
--
-- See below `GroupConfig`.

-- ========== Config ==========
--
-- Utility for easier writing 'fzfx.config'.

--- @class fzfx.ProviderConfigLineOpts
--- @field prepend_icon_by_ft boolean?
--- @field prepend_icon_path_delimiter string? -- working with `prepend_icon_by_ft=true`
--- @field prepend_icon_path_position integer? -- working with `prepend_icon_by_ft=true`
--
--- @class fzfx.ProviderConfig
--- @field key fzfx.ActionKey
--- @field provider fzfx.Provider
--- @field provider_type fzfx.ProviderType? by default "plain"
--- @field line_opts fzfx.ProviderConfigLineOpts?

--- @class fzfx.PreviewerConfig
--- @field previewer fzfx.Previewer
--- @field previewer_type fzfx.PreviewerType?
--- @field previewer_label fzfx.PreviewerLabel?
--- @field previewer_label_type fzfx.PreviewerLabelType?

--- @alias fzfx.PipelineName string a pipeline name is a provider name, a previewer name
--- @class fzfx.CommandConfig
--- @field name string
--- @field feed fzfx.CommandFeed
--- @field opts fzfx.CommandOpt
--- @field default_provider fzfx.PipelineName?

--- @alias fzfx.InteractionName string
--
--- @class fzfx.InteractionConfig
--- @field key fzfx.ActionKey
--- @field interaction fzfx.Interaction
--- @field reload_after_execute boolean?

--- @class fzfx.GroupConfig
--- @field commands fzfx.CommandConfig|fzfx.CommandConfig[]
--- @field providers fzfx.ProviderConfig|table<fzfx.PipelineName, fzfx.ProviderConfig>
--- @field previewers fzfx.PreviewerConfig|table<fzfx.PipelineName, fzfx.PreviewerConfig>
--- @field interactions table<fzfx.InteractionName, fzfx.InteractionConfig>?
--- @field actions table<fzfx.ActionKey, fzfx.Action>
--- @field fzf_opts fzfx.FzfOpt[]?

--- @param cfg fzfx.CommandConfig?
--- @return boolean
local function is_command_config(cfg)
  return type(cfg) == "table"
    and type(cfg.name) == "string"
    and string.len(cfg.name) > 0
    and type(cfg.feed) == "string"
    and string.len(cfg.feed) > 0
    and type(cfg.opts) == "table"
end

--- @param cfg fzfx.ProviderConfig?
--- @return boolean
local function is_provider_config(cfg)
  return type(cfg) == "table"
    and type(cfg.key) == "string"
    and string.len(cfg.key) > 0
    and (
      (
        type(cfg.provider) == "string"
        and string.len(cfg.provider --[[@as string]]) > 0
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
      or (
        type(cfg.previewer_type) == "string"
        and string.len(cfg.previewer_type) > 0
      )
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
      type(previewer_config.previewer_label) == "function"
        and PreviewerLabelTypeEnum.FUNCTION
      or PreviewerLabelTypeEnum.PLAIN
    )
end

local M = {
  ProviderTypeEnum = ProviderTypeEnum,
  PreviewerTypeEnum = PreviewerTypeEnum,
  PreviewerLabelTypeEnum = PreviewerLabelTypeEnum,
  CommandFeedEnum = CommandFeedEnum,

  is_command_config = is_command_config,
  is_provider_config = is_provider_config,
  is_previewer_config = is_previewer_config,
  get_provider_type_or_default = get_provider_type_or_default,
  get_previewer_type_or_default = get_previewer_type_or_default,
  get_previewer_label_type_or_default = get_previewer_label_type_or_default,
}

return M
