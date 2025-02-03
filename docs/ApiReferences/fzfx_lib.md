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
- [`run_async`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L74)/[`run_sync`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L115): Run shell command in either async or sync way, the API accepts a strings array as shell command. Note: The async-style API uses lua's `coroutine` to turn the original callback-style `vim.uv` APIs into async-style, it doesn't block Neovim UI, but needs to be called within the async context (i.e. the `fzfx.commons.async.void`, please refer to [commons.async](https://linrongbin16.github.io/commons.nvim/#/commons_async) for more details). On the other hand, the sync-style API will block Neovim UI.
- [`run_git_root_async`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L78)/[`run_git_root_sync`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L138): Run git command to find out the git repository's root directory in either async or sync way. This is super helpful to detect whether current working directory is in a git repository.
- [`run_git_branches_async`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L84)/[`run_git_branches_sync`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L145): Run git command to find out both local and remote branches in either async or sync way.
- [`run_git_current_branch_async`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L99)/[`run_git_current_branch_sync`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L155): Run git command to find out current branch name in either async or sync way.
- [`run_git_remotes_async`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L105)/[`run_git_remotes_sync`](https://github.com/linrongbin16/fzfx.nvim/blob/16d618df93a49f5bfc22c49cd67bc867ada818ec/lua/fzfx/lib/commands.lua?plain=1#L161): Run git command to find out the configured remotes in either async or sync way.

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
