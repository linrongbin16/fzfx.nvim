-- No Setup Need

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
--- @class PipelineContext
--- @field bufnr integer
--- @field winnr integer
--- @field tabnr integer
--- ...
--
--- @alias PipelineContextMaker fun():PipelineContext
--
--- @alias PlainProvider string|string[]
--- @alias CommandProvider fun(query:string?,context:PipelineContext?):string?|string[]?
--- @alias ListProvider fun(query:string?,context:PipelineContext?):string[]?
--
--- @alias Provider PlainProvider|CommandProvider|ListProvider
--- @alias ProviderType "plain"|"command"|"list"|"plain_list"|"command_list"
--- @enum ProviderTypeEnum
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
--- @alias CommandPreviewer fun(line:string?,context:PipelineContext?):string?
--- @alias ListPreviewer fun(line:string?,context:PipelineContext?):string[]?
--- @alias BufferPreviewer fun(line:string?,context:PipelineContext?):table?
--
--- @alias Previewer CommandPreviewer|ListPreviewer|BufferPreviewer
--- @alias PreviewerType "command"|"command_list"|"list"|"buffer"
--- @enum PreviewerTypeEnum
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
--- @alias PlainPreviewerLabel string
--- @alias FunctionPreviewerLabel fun(line:string?,context:PipelineContext?):string?
--- @alias PreviewerLabel PlainPreviewerLabel|FunctionPreviewerLabel
--- @alias PreviewerLabelType "plain"|"function"
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
--- @alias CommandOptKey "nargs"|"bang"|"complete"|"desc"|"range"
--- @alias CommandOptValue string|boolean
--- @alias CommandOpt table<CommandOptKey, CommandOptValue>

-- ========== Command Feed ==========
--
-- User command feeds are method that what to feed the fzfx command.
-- E.g. visual selected, cursor word, etc.
--
--- @alias CommandFeed "args"|"visual"|"cword"|"put"|"resume"
--- @enum CommandFeedEnum
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
--- @alias PlainFzfOpt string
--- @alias PairFzfOpt string[]
--- @alias FunctionFzfOpt fun():PlainFzfOpt|PairFzfOpt
--
--- @alias FzfOpt PlainFzfOpt|PairFzfOpt|FunctionFzfOpt

-- ========== Action ==========
--
-- An action is user press a key and we do something.
-- We have 2 types of actions:
--  * Interaction: interactively do something on current line without exit fzf.
--  * Action: exit fzf and invoke lua callback with selected lines.
--
--- @alias ActionKey string
--- @alias Interaction fun(line:string?,context:PipelineContext):any
--- @alias Action fun(line:string[]|nil,context:PipelineContext):any

-- ========== Pipeline ==========
--
-- A pipeline binds a provider with a previewer, with a interactive action to switch the data sources, and the help message.
-- (Note: when you only have 1 provider, the interaction key and help message can be ommitted).
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

--- @class ProviderConfigLineOpts
--- @field prepend_icon_by_ft boolean?
--- @field prepend_icon_path_delimiter string? -- working with `prepend_icon_by_ft=true`
--- @field prepend_icon_path_position integer? -- working with `prepend_icon_by_ft=true`
--
--- @class ProviderConfig
--- @field key ActionKey
--- @field provider Provider
--- @field provider_type ProviderType? by default "plain"
--- @field line_opts ProviderConfigLineOpts?

--- @class PreviewerConfig
--- @field previewer Previewer
--- @field previewer_type PreviewerType?
--- @field previewer_label PreviewerLabel?
--- @field previewer_label_type PreviewerLabelType?

--- @alias PipelineName string a pipeline name is a provider name, a previewer name
--- @class CommandConfig
--- @field name string
--- @field feed CommandFeed
--- @field opts CommandOpt
--- @field default_provider PipelineName?

--- @alias InteractionName string
--
--- @class InteractionConfig
--- @field key ActionKey
--- @field interaction Interaction
--- @field reload_after_execute boolean?

--- @class GroupConfig
--- @field commands CommandConfig|CommandConfig[]
--- @field providers ProviderConfig|table<PipelineName, ProviderConfig>
--- @field previewers PreviewerConfig|table<PipelineName, PreviewerConfig>
--- @field interactions table<InteractionName, InteractionConfig>?
--- @field actions table<ActionKey, Action>
--- @field fzf_opts FzfOpt[]?

--- @param cfg CommandConfig?
--- @return boolean
local function is_command_config(cfg)
    return type(cfg) == "table"
        and type(cfg.name) == "string"
        and string.len(cfg.name) > 0
        and type(cfg.feed) == "string"
        and string.len(cfg.feed) > 0
        and type(cfg.opts) == "table"
end

--- @param cfg ProviderConfig?
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

--- @param cfg PreviewerConfig?
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

--- @param provider_config ProviderConfig
--- @return ProviderType
local function get_provider_type_or_default(provider_config)
    return provider_config.provider_type
        or (
            type(provider_config.provider) == "string"
                and ProviderTypeEnum.PLAIN
            or ProviderTypeEnum.PLAIN_LIST
        )
end

--- @param previewer_config PreviewerConfig
--- @return PreviewerType
local function get_previewer_type_or_default(previewer_config)
    return previewer_config.previewer_type or PreviewerTypeEnum.COMMAND
end

--- @param previewer_config PreviewerConfig
--- @return PreviewerLabelType
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
