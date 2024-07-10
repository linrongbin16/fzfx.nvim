# [`fzfx.lib`](https://github.com/linrongbin16/fzfx.nvim/tree/main/lua/fzfx/lib)

The `fzfx.lib` package contains all fundamental infrastructures.

## [`fzfx.lib.bufs`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/lib/bufs.lua)

Neovim buffer related APIs.

- [`buf_is_valid`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/bufs.lua?plain=1#L5): Whether the buffer (`bufnr`) is a valid and visible buffer for user

## [`fzfx.lib.commands`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/lib/commands.lua)

Executable shell command utilities.

- [`@class fzfx.CommandResult`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/commands.lua?plain=1#L14): The executed results of a shell command, i.e. outputs, errors, exit code, etc.
  - Fields
    - `@field stdout string[]|nil`: The `stdout` output in lines.
    - `@field stderr string[]|nil`: The `stderr` output in lines.
    - `@field code integer`: The exit code.
    - `@field signal integer`: The signal number.
  - Methods
    - `function CommandResult:new(stdout:string[]|nil, stderr:string[]|nil, code:integer, signal:integer):CommandResult`: Make a new command result.
    - `function CommandResult:failed():boolean`: Whether the shell command is failed, it's `true` when the exit code is not `0`, or there's error messages printed in `stderr`. Otherwise it's `false`.
- [`@class fzfx.Command`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/commands.lua?plain=1#L50): The executable shell command.
  - Fields
    - `@field source string[]`: The shell command splitted by whitespaces.
    - `@field result fzfx.CommandResult?`: The executed result.
  - Methods
    - `function Command:run(source):fzfx.Command`: Make a new command and run it synchronously. Note: this method will block the editor.
    - `function Command:failed():boolean`: Whether the shell command is failed. It's a short cut for `Command.result:failed()`.
- [`@class fzfx.GitRootCommand`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/commands.lua?plain=1#L98): Run git command to find out the git repository's root directory. This is super helpful to detect whether current working directory is in a git repository.
  - Methods
    - `function GitRootCommand:run():fzfx.GitRootCommand`: Run `git rev-parse --show-toplevel` and make a command instance.
    - `function GitRootCommand:failed():boolean`: Whether this command is failed.
    - `function GitRootCommand:output():string?`: Get the output of this command.
- [`@class fzfx.GitBranchesCommand`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/commands.lua?plain=1#L134): Run git command to find out it's local/remote branches.
  - Methods
    - `function GitBranchesCommand:run(remotes:boolean?):fzfx.GitBranchesCommand`: Run `git branch` (for local branches) or `git branches --remotes` (for remote branches) and make a command instance.
    - `function GitBranchesCommand:failed():boolean`: Whether this command is failed.
    - `function GitBranchesCommand:output():string[]|nil`: Get the output lines of this command. Each line is a git branch.
- [`@class fzfx.GitCurrentBranchCommand`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/commands.lua?plain=1#L171): Run git command to find out current branch name.
  - Methods
    - `function GitCurrentBranchCommand:run():fzfx.GitCurrentBranchCommand`: Run `git rev-parse --abbrev-ref HEAD` and make a command instance.
    - `function GitCurrentBranchCommand:failed():boolean`: Whether this command is failed.
    - `function GitCurrentBranchCommand:output():string?`: Get the output of this command. The output is the current branch name.
- [`@class fzfx.GitRemotesCommand`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/commands.lua?plain=1#L208): Run git command to find out the configured remotes.
  - Methods
    - `function GitRemotesCommand:run():fzfx.GitRemotesCommand`: Run `git remote` and make a command instance.
    - `function GitRemotesCommand:failed():boolean`: Whether this command is failed.
    - `function GitRemotesCommand:output():string[]|nil`: Get the output lines of this command. Each line is a configured remote, for example `origin`, `upstream`, etc.

## [`fzfx.lib.constants`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/lib/constants.lua)

All the constant variables, the value never change once the plugin is been setup.

## [`fzfx.lib.env`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/lib/env.lua)

Environment variable utilities.

- [`debug_enabled`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/env.lua?plain=1#L4): Whether debug mode is enabled or not.
- [`icon_enabled`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/env.lua?plain=1#L9): Whether icon is enabled or not.

## [`fzfx.lib.log`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/lib/log.lua)

Logging APIs, helpful for debugging and development.

- [`LogLevels`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/log.lua?plain=1#L5): Log levels .
  - Enums: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `OFF`, they're compatible with the [`vim.log.levels`](https://neovim.io/doc/user/lua.html#log_levels), but in this plugin we don't use `TRACE` and `OFF`.
- [`echo`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/log.lua?plain=1#L20): Print logs as Neovim's message. Note: This API doesn't require this plugin setup, thus you can use it even before this plugin setup.
- [`setup`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/log.lua?plain=1#L56): Setup the logging system. Note: This API is been invoked automatically when this plugin setup.
  - Function Signature: `function(opts:fzfx.Options?):nil`. The `opts` parameter is an optional lua table contains below fields:
    - `level`: The `LogLevels`. By default it's `INFO` when debug mode is off, `DEBUG` when debug mode is on.
    - `console_log`: Whether prints logs to Neovim's message. By default it's `true`, all the hints and error messages are printed as Neovim's message.
    - `file_log`: Whether writes logs to local logging files. By default it's `false` when debug mode is off, `true` when debug mode is on.
- [`debug`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/log.lua?plain=1#L68)/[`info`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/log.lua?plain=1#L82)/[`warn`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/log.lua?plain=1#L96)/[`err`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/log.lua?plain=1#L110): Log the message.
- [`throw`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/log.lua?plain=1#L124): Logs the message and throw an error to Neovim, equivalent to Neovim's `error` API.
- [`ensure`](https://github.com/linrongbin16/fzfx.nvim/blob/6cde87c522460d4da2a9c657ce4615ce619cca45/lua/fzfx/lib/log.lua?plain=1#L140): Assert if the `condition` is true. When it's `false`, logs the message and throw an error to Neovim, equivalent to Neovim's `assert` API.

## [`fzfx.lib.lsp`](https://github.com/linrongbin16/fzfx.nvim/blob/e136dc76a691a5c6a79d25a8f87d677d41952ea1/lua/fzfx/lib/lsp.lua)

LSP compatible APIs, working across different Neovim versions.

- [`get_clients`](https://github.com/linrongbin16/fzfx.nvim/blob/e136dc76a691a5c6a79d25a8f87d677d41952ea1/lua/fzfx/lib/lsp.lua#L6): Get LSP clients. For Neovim &ge; 0.10 use `vim.lsp.get_clients`, for Neovim &lt; 0.10 use `vim.lsp.get_active_clients`.

## [`fzfx.lib.shells`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/lib/shells.lua)

Shell related APIs, working on cross-platform: Windows & \*NIX.

- [`shellescape`](https://github.com/linrongbin16/fzfx.nvim/blob/e136dc76a691a5c6a79d25a8f87d677d41952ea1/lua/fzfx/lib/shells.lua#L8): Escape shell parameters, on \*NIX it's simply wrapped around with single quotes `'`, on Windows it's wrapped around with double quotes `"`.
