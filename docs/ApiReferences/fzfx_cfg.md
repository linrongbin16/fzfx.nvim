# [`fzfx.cfg`](https://github.com/linrongbin16/fzfx.nvim/tree/main/lua/fzfx/cfg)

The `fzfx.cfg` package contains all top-level configurations that been directly registered to create a searching command, such as `FzfxFiles`, `FzfxLiveGrep`, etc. Each module is an independent configuration (sorted in alphabetical order):

- [`buf_live_grep.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/buf_live_grep.lua): `FzfxBufLiveGrep`.
- [`buffers.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/buffers.lua): `FzfxBuffers`.
- [`file_explorer.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/file_explorer.lua): `FzfxFileExplorer`.
- [`files.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/files.lua): `FzfxFiles`.
- [`git_blame.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_blame.lua): `FzfxGBlame`.
- [`git_branches.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_branches.lua): `FzfxGBranches`.
- [`git_commits.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_commits.lua): `FzfxGCommits`.
- [`git_files.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_files.lua): `FzfxGFiles`.
- [`git_live_grep.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_live_grep.lua): `FzfxGLiveGrep`.
- [`git_status.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_status.lua): `FzfxGStatus`.
- [`live_grep.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/live_grep.lua): `FzfxLiveGrep`.
- [`lsp_definitions.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_definitions.lua): `FzfxLspDefinitions`.
- [`lsp_diagnostics.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_diagnostics.lua): `FzfxLspDiagnostics`.
- [`lsp_implementations.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_implementations.lua): `FzfxLspImplementations`.
- [`lsp_incoming_calls.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_incoming_calls.lua): `FzfxLspIncomingCalls`.
- [`lsp_outgoing_calls.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_outgoing_calls.lua): `FzfxLspOutgoingCalls`.
- [`lsp_references.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_references.lua): `FzfxLspReferences`.
- [`lsp_type_definitations.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_type_definitations.lua): `FzfxLspTypeDefinitations`.
- [`vim_commands.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/vim_commands.lua): `FzfxCommands`.
- [`vim_keymaps.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/vim_keymaps.lua): `FzfxKeyMaps`.
- [`vim_marks.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/vim_marks.lua): `FzfxMarks`.

Each configuration is structured with:

- `command`: Registered user command configurations, i.e. command name and description.
- `variants`: User query input methods, i.e. basic arguments, visual selections, cursor word, yank text and resume last query contents.
- `providers`: Data sources that can generate query results for (the left side of) the fzf binary.
- `previewers`: Content previewer that can preview the current line for (the right side of) the fzf binary.
- `actions`: Actions that press and quit the popup window, and invoke binded lua function with selected lines.
- `fzf_opts`: Specific options for the fzf binary, such as `--prompt`, `--multi`, `--disabled` (this is most important to implement **reloading query** for `FzfxLiveGrep`).
- `interactions` (optional): Interactions that press and invoke binded lua function with current line, without quitting the popup window.
- `other_opts` (optional): Other specific options for some specific features, such as reloading query after interactions, customized contexts, etc.

> You may want to read [A General Schema for Creating FZF Command](https://linrongbin16.github.io/fzfx.nvim/#/GenericSchema.md) and [`schema.lua`](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/schema.lua) to understand why it's structured this way.
