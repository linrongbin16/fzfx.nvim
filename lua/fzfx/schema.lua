-- Zero Dependency

-- Schema Definitions
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
--- @alias PlainProvider string
--- @alias CommandProvider fun(context:any,query:string?):string
--- @alias ListProvider fun(context:any,query:string?):string[]
--
--- @alias Provider PlainProvider|CommandProvider|ListProvider
--
--- @alias ProviderType "plain"|"command"|"list"
--- @enum ProviderTypeEnum
local ProviderTypeEnum = {
    PLAIN = "plain",
    COMMAND = "command",
    LIST = "list",
}

-- ========== Line Processor ==========
--
-- A line processor is a lua function that read a line produced from provider and returned a new line.
-- E.g. the icons prepended for files.
-- We have 2 types of line processors:
--  * FunctionLineProcessor: a lua function that input a line and returned a new line. **Note**: it needs a RPC call from lua script to nvim editor.
--  * BuiltinLineProcessor: builtin options that process each line. **Note**: it's embeded into the shell_helpers so don't need RPC call.
--
--- @alias FunctionLineProcessor fun(line:string):string
--
--- @alias BuiltinLineProcessorKey "line_type"|"line_delimiter"|"line_index"
--- @alias BuiltinLineProcessorValue boolean|string|integer|number
--- @alias BuiltinLineProcessor table<BuiltinLineProcessorKey, BuiltinLineProcessorValue>
--
--- @alias LineProcessor FunctionLineProcessor|BuiltinLineProcessor
--
--- @alias LineProcessorType "function"|"builtin"
--- @enum LineProcessorTypeEnum
local LineProcessorTypeEnum = {
    FUNCTION = "function",
    BUILTIN = "builtin",
}

-- ========== Previewer ==========
--
-- A previewer is a shell command that run and echo details for fzf (e.g. things on the right side).
-- We have 2 types of previewers:
--  * Command previewer: a lua function that generate a command string to execute and echo details.
--  * Builtin previewer (todo): a nvim buffer & window, I think the biggest benefits can be allowing users to navigate to the buffer and edit it directly.
--
--- @alias CommandPreviewer fun(line:string):string
--
--- @alias Previewer CommandPreviewer
--
--- @alias PreviewerType "command"
--- @enum PreviewerTypeEnum
local PreviewerTypeEnum = {
    COMMAND = "command",
}

-- ========== User Command Option ==========
--
-- User command options are something that passing to nvim user command lua api.
-- See:
--  * https://neovim.io/doc/user/api.html#nvim_create_user_command()
--  * https://neovim.io/doc/user/map.html#command-attributes
--
--- @alias UserCommandOptionKey "nargs"|"bang"|"complete"|"desc"|"range"
--- @alias UserCommandOptionValue string|boolean
--- @alias UserCommandOption table<UserCommandOptionKey, UserCommandOptionValue>

-- ========== User Command Feed ==========
--
-- User command feeds are method that what to feed the fzfx command.
-- E.g. visual selected, cursor word, etc.
--
--- @alias UserCommandFeed "args"|"visual"|"cword"|"put"
--- @enum UserCommandFeedEnum
local UserCommandFeedEnum = {
    ARGS = "args",
    VISUAL = "visual",
    CWORD = "cword",
    PUT = "put",
}

-- ========== Fzf Option ==========
--
-- A fzf option is passing directly to the final fzf command (e.g. --multi, --bind=ctrl-e:toggle).
-- We have 3 types of fzf options:
--  * Plain fzf option: a simple string, e.g. '--multi'.
--  * Pair fzf option: a list of two strings, e.g. { '--bind', 'ctrl-e:toggle' }.
--  * Function fzf option: a lua function that run and generate above two kinds of fzf options.
--
--- @alias PlainFzfOption string
--- @alias PairFzfOption string[]
--- @alias FunctionFzfOption fun():PlainFzfOption|PairFzfOption
--
--- @alias FzfOption PlainFzfOption|PairFzfOption|FunctionFzfOption

local M = {
    ProviderTypeEnum = ProviderTypeEnum,
    LineProcessorTypeEnum = LineProcessorTypeEnum,
    PreviewerTypeEnum = PreviewerTypeEnum,
    UserCommandFeedEnum = UserCommandFeedEnum,
}

return M
