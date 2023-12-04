-- ========== Schema ==========
--
-- A fzf-based search command usually consists of below components:
--
-- Provider: a shell command that can generate the lines list for (the left side of) the fzf binary.
-- Previewer: a shell command that generate the content to preview the current line (on the left side) for (the right side of) the fzf binary.
-- Interaction: an interactive key that user press and do something without quit the fzf binary, e.g. the CTRL-U/CTRL-R keys in FzfxLiveGrep to switch on restricted/unrestricted rg searching results.
-- Action: a key that user press to quit fzf binary, and invoke its registered callback lua functions on selected lines, e.g. the ENTER keys in most of commands.
-- Fzf options: other fzf options.
-- With this pattern, I hide all the details of constructing fzf command and interacting across different child processes with nvim editor, provide a friendly config layer to allow users to define any commands on their own needs.
--
-- Put all above components together, I name it Pipeline.
--
-- Let's defines this pattern more specifically.
--
--
-- ========== Context ==========
--
-- A context is some data that passing to pipeline.
--
-- After launching the fzf binary command, there's no way to get the current buffer's bufnr and current window's winnr by nvim API, since the current buffer/window is actually the terminal that running the fzf binary, not the buffer/file you're editing. So we need to create a context before actually creating the fzf binary terminal.
--
--- @class fzfx.PipelineContext
--- @field bufnr integer
--- @field winnr integer
--- @field tabnr integer
--- ...
--
--- @alias fzfx.PipelineContextMaker fun():fzfx.PipelineContext
--
--
-- ========== Provider ==========
--
-- A provider is a shell command that run and generate the lines list for (the left side of) the fzf binary.
--
-- We have below types of providers:
--  * Plain provider: a simple shell command (as a string or a string list), execute and generate the lines for fzf.
--  * Command provider: a lua function to run and returns the shell command (as a string or a string list), then execute and generate the lines for fzf.
--  * List provider: a lua function to run and directly returns the lines for fzf.
--
--
--- @alias fzfx.PlainProvider string|string[]
--- @alias fzfx.CommandProvider fun(query:string?,context:fzfx.PipelineContext?):string?|string[]?
--- @alias fzfx.ListProvider fun(query:string?,context:fzfx.PipelineContext?):string[]?
--- @alias fzfx.Provider fzfx.PlainProvider|fzfx.CommandProvider|fzfx.ListProvider
---
--- @alias fzfx.ProviderType "plain"|"command"|"list"|"plain_list"|"command_list"
--- @enum fzfx.ProviderTypeEnum
local ProviderTypeEnum = {
  PLAIN = "plain",
  PLAIN_LIST = "plain_list",
  COMMAND = "command",
  COMMAND_LIST = "command_list",
  LIST = "list",
}
--
-- Note: the 1st parameter 'query' is the user input query in fzf prompt.
--
--
-- ========== Previewer ==========
--
-- A previewer is a shell command that read current line and generate the preview contents for (the right side of) the fzf binary.
--
-- We have below types of previewers:
--  * Command previewer: a lua function to run and returns a shell command (as a string or a string list), then execute and generate the preview contents for fzf.
--  * List previewer: a lua function to run and directly returns the preview contents for fzf.
--  * Buffer previewer (todo): a nvim buffer to show the preview contents. (the biggest benefits are nvim builtin highlightings and allow navigate to the buffer and edit directly)
--
--- @alias fzfx.CommandPreviewer fun(line:string?,context:fzfx.PipelineContext?):string?
--- @alias fzfx.ListPreviewer fun(line:string?,context:fzfx.PipelineContext?):string[]?
--- @alias fzfx.Previewer fzfx.CommandPreviewer|fzfx.ListPreviewer
---
--- @alias fzfx.PreviewerType "command"|"command_list"|"list"
--- @enum fzfx.PreviewerTypeEnum
local PreviewerTypeEnum = {
  COMMAND = "command",
  COMMAND_LIST = "command_list",
  LIST = "list",
}
--
-- Note: the 1st parameter 'line' is the current selected line in (the left side of) the fzf binary.
--
--
-- ========== Previewer Label ==========
--
-- A previewer label is the label/title for the preview window.
--
-- We have 2 types of previewers:
--  * Plain previewer: a static string value which is the label for the preview window.
--  * Function previewer: a lua function to run and returns the string value for the preview window.
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
