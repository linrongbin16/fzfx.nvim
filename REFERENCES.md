<!-- markdownlint-disable MD013 MD034 MD033 MD038 MD051 MD040 -->

# API References

The modules in `fzfx.cfg` are recommended as a reference when you want to customize/implement your own search commands.

The APIs in `fzfx.helper` and `fzfx.lib` are recommended when you implement something in fzfx, they are supposed to be stable and tested.

!> Except those APIs start with underline `_`, which are exposed for unit tests.

## Module [`fzfx.cfg`](https://github.com/linrongbin16/fzfx.nvim/lua/fzfx/cfg)

The `fzfx.cfg` module directly provide configurations for all search commands in this plugin.

!> Before continue, you may need to read [A General Schema for Creating FZF Command](https://github.com/linrongbin16/fzfx.nvim/wiki/A-General-Schema-for-Creating-FZF-Command) to understand why it's structured like this.

A real-world search command, say `FzfxLiveGrep`, actually defined multiple user commands:

- `FzfxLiveGrep(B/U)`
- `FzfxLiveGrep(B/U)V`
- `FzfxLiveGrep(B/U)W`
- `FzfxLiveGrep(B/U)R`
- `FzfxLiveGrep(B/U)P`

They're all defined in the `fzfx.cfg.live_grep` module, it's called a commands group.

Each commands group contains below components:

- `commands`
  - For only 1 command, it's a single [`fzfx.CommandConfig`](https://github.com/linrongbin16/fzfx.nvim/blob/aa5eac85d5e9dcb020cd4237814ec0b305945193/lua/fzfx/schema.lua?plain=1#L133).
  - For multiple commands, it's a `fzfx.CommandConfig` list .
- `providers`
  - For only 1 provider(data source), it's a single [`fzfx.ProviderConfig`](https://github.com/linrongbin16/fzfx.nvim/blob/aa5eac85d5e9dcb020cd4237814ec0b305945193/lua/fzfx/schema.lua?plain=1#L119).
  - For multiple providers(data sources), it's a `fzfx.ProviderConfig` map.
- `previewers`
  - For only 1 previewer, it's a single [`fzfx.PreviewerConfig`](https://github.com/linrongbin16/fzfx.nvim/blob/835b216c36a94e289c166c0f8790e0f56f7a77bb/lua/fzfx/schema.lua?plain=1#L126).
  - For multiple previewers, it's a `fzfx.PreviewerConfig` map.
- `actions`: a [`fzfx.Action`](https://github.com/linrongbin16/fzfx.nvim/blob/835b216c36a94e289c166c0f8790e0f56f7a77bb/lua/fzfx/schema.lua?plain=1#L151) map.
- (Optional) `interactions`: a [`fzfx.InterAction`](https://github.com/linrongbin16/fzfx.nvim/blob/835b216c36a94e289c166c0f8790e0f56f7a77bb/lua/fzfx/schema.lua?plain=1#L150) map.
- (Optional) `fzf_opts`: a [`fzfx.FzfOpt`](https://github.com/linrongbin16/fzfx.nvim/blob/835b216c36a94e289c166c0f8790e0f56f7a77bb/lua/fzfx/schema.lua?plain=1#L152) list.
- (Optional) `other_opts`: other special options.

Here are all the builtin search command configurations:

- [buffers](/lua/fzfx/cfg/buffers.lua): implements `FzfxBuffers`, it's a single data source pipeline (has only 1 provider/previewer), and has a **delete buffer** interaction.
- [file_explorer](/lua/fzfx/cfg/file_explorer.lua): implements `FzfxFileExplorer`, it has two interactions **cd** and **go upper**.
- [files](/lua/fzfx/cfg/files.lua): implements `FzfxFiles`.
- [git_blame](/lua/fzfx/cfg/git_blame.lua): implements `FzfxGBlame`, it's also a single data source pipeline (has only 1 provider/previewer).
- [git_branches](/lua/fzfx/cfg/git_branches.lua): implements `FzfxGBranches`, it has a special context `fzfx.GitBranchesPipelineContext` that provides all **remotes** in git repo (via `git remote`), which is used by downstream `git_checkout` action.
- [git_commits](/lua/fzfx/cfg/git_commits.lua): implements `FzfxGCommits`.
- [git_files](/lua/fzfx/cfg/git_files.lua): implements `FzfxGFiles`.
- [git_live_grep](/lua/fzfx/cfg/git_live_grep.lua): implements `FzfxGLiveGrep`, it enables a special `reload_on_change` (in `other_opts`) option to reload grep on fzf's [change event](https://man.archlinux.org/man/fzf.1.en#AVAILABLE_EVENTS:).
- [git_status](/lua/fzfx/cfg/git_status.lua): implements `FzfxGStatus`.
- [live_grep](/lua/fzfx/cfg/live_grep.lua): implements `FzfxLiveGrep`, it also enables the `reload_on_change`.
- [lsp_definitions](/lua/fzfx/cfg/lsp_definitions.lua): implements `FzfxLspDefinitions`.
- [lsp_diagnostics](/lua/fzfx/cfg/lsp_diagnostics.lua): implements `FzfxLspDiagnostics`.
- [lsp_implementations](/lua/fzfx/cfg/lsp_implementations.lua): implements `FzfxLspImplementations`.
- [lsp_incoming_calls](/lua/fzfx/cfg/lsp_incoming_calls.lua): implements `FzfxLspIncomingCalls`.
- [lsp_outgoing_calls](/lua/fzfx/cfg/lsp_outgoing_calls.lua): implements `FzfxLspOutgoingCalls`.
- [lsp_references](/lua/fzfx/cfg/lsp_references.lua): implements `FzfxLspReferences`.
- [lsp_type_definitions](/lua/fzfx/cfg/lsp_type_definitions.lua): implements `FzfxLspTypeDefinitions`.
- [vim_commands](/lua/fzfx/cfg/vim_commands.lua): implements `FzfxCommands`, it implements the self-rendering form to directly generate lines for (the left side of) the fzf binary, which is a lot of engineering effort for the providers.
- [vim_keymaps](/lua/fzfx/cfg/vim_keymaps.lua): implements `FzfxKeyMaps`, it also implements the self-rendering form to directly generate lines for fzf.

## Module [`fzfx.helper`](/lua/fzfx/helper ":ignore")

The `fzfx.helper` provide line-oriented helpers for parsing and rendering queries/lines required in all scenarios. Since a search command is actually all about the lines in (both left and right side of) fzf binary: generate lines, preview lines, invoke callbacks on selected lines, etc.

### [fzfx.helper.parsers](/lua/fzfx/helper/parsers.lua)

The `fzfx.helper.parsers` are lower-level (compared with others in `fzfx.helper`) components that help **_previewers_**, **_previewer_labels_**, **_actions_**, etc to understand the lines generated from **_providers_**, e.g. it's the bridge between data producers and consumers.

- `parse_find(line:string):{filename:string}`: parse the line generated by `fd`/`find` or other sources (buffers) follow the same style, remove the prepend icon if it's enabled. used by:
  - `FzfxFiles`
  - `FzfxBuffers`
  - `FzfxGFiles`
- `parse_rg(line:string):{filename:string,lineno:integer,column:integer?,text:string}`: parse the line generated by `rg` or other sources (lsp, diagnostics) follow the same style, remove the prepend icon if it's enabled. used by:
  - `FzfxLiveGrep`
  - `FzfxLspDefinitions`
  - `FzfxLspTypeDefinitions`
  - `FzfxLspImplementations`
  - `FzfxLspReferences`
  - `FzfxLspDiagnostics`
  - `FzfxLspIncomingCalls`
  - `FzfxLspOutgoingCalls`
- `parse_grep(line:string):{filename:string,lineno:integer,text:string}`: parse the line generated by `grep`/`git grep` or other sources follow the same style, remove the prepend icon if it's enabled. The difference between `parse_grep` and `parse_rg` is grep doesn't have the column number. used by:
  - `FzfxLiveGrep` (when `rg` not found)
  - `FzfxGLiveGrep`
- `parse_git_status(line:string):{filename:string}`: parse the line generated by `git status` or other sources follow the same style, remove the prepend git symbol. used by:
  - `FzfxGStatus`
- `parse_git_branch(line:string, context:fzfx.GitBranchesPipelineContext):{local_branch:string,remote_branch:string}`: parse the line generated by `git branch (-r)` or other sources follow the same style. used by:
  - `FzfxGBranches`
- `parse_git_commit(line:string):{commit:string}`: parse the line generated by `git log`/`git blame` or other sources follow the same style. used by:
  - `FzfxGCommits`
  - `FzfxGBlame`
- `parse_lsd(line:string,context:fzfx.FileExplorerPipelineContext):{filename:string}`: parse the line generated by `lsd` or other sources follow the same style. used by:
  - `FzfxFileExplorer` (when `lsd` is found)
- `parse_eza(line:string,context:fzfx.FileExplorerPipelineContext):{filename:string}`: parse the line generated by `eza`/`exa` or other sources follow the same style. used by:
  - `FzfxFileExplorer` (when `eza`/`exa` is found)
- `parse_ls(line:string,context:fzfx.FileExplorerPipelineContext):{filename:string}`: parse the line generated by `ls` or other sources follow the same style. used by:
  - `FzfxFileExplorer` (when `lsd`/`eza`/`exa` not found)
- `parse_vim_command(line:string,context:fzfx.VimCommandsPipelineContext):{command:string,filename:string,lineno:integer?}|{command:string,definition:string}`: parse the line generated by builtin vim commands renderer or other sources follow the same style. used by:
  - `FzfxCommands`
- `parse_vim_keymap(line:string,context:fzfx.VimKeyMapsPipelineContext):{lhs:string,mode:string,filename:string,lineno:integer?}|{lhs:string,definition:string}`: parse the line generated by builtin vim keymaps renderer or other sources follow the same style. used by:
  - `FzfxKeyMaps`

### [fzfx.helper.actions](/lua/fzfx/helper/actions.lua)

The **_actions_** are hook functions binding to fzf, user press the key and fzf binary will quit, then invoke these hook functions on the selected lines.

- `nop():nil`: do nothing.

#### `fd`/`find`

The `fd`, `find`, `git ls-files` generated file names, or other sources (buffers) follow the same style, used by `FzfxFiles`, `FzfxBuffers`, `FzfxGFiles`. they look like:

```
 README.md
󰢱 lua/fzfx.lua/test/hello world.txt
```

- `edit_find(lines:string[], context:fzfx.PipelineContext):nil`: use `edit` command to open selected files on `fd`, `find`, `git ls-files` results.
- `setqflist_find(lines:string[], context:fzfx.PipelineContext):nil`: use `setqflist` command to send selected lines (files) to qflist.

#### `rg`, `grep`

The `rg`, `grep`, `git grep` generated locations (file name with line/column number), or other sources (lsp, diagnostics) follow the same style, used by `FzfxLiveGrep`, `FzfxGLiveGrep`, `FzfxLspDiagnostics`, `FzfxLspDefinitions`, `FzfxLspTypeDefinitions`, `FzfxLspReferences`, `FzfxLspImplementations`, `FzfxLspIncomingCalls`, `FzfxLspOutgoingCalls`. they look like:

```
󰢱 lua/fzfx.lua:15:82: local strs = require("fzfx.lib.strings")
󰢱 lua/fzfx/config.lua:1:70: local line = parsers.parse_find(lines, context)
```

> Note: the `rg` (lsp, diagnostics) have column number, while `grep`, `git grep` don't have column number.

- `edit_rg(lines:string[], context:fzfx.PipelineContext):nil`: use `edit` and `setpos` command to open selected locations on `rg` results.
- `setqflist_rg(lines:string[], context:fzfx.PipelineContext):nil`: use `setqflist` command to send selected locations to qflist.
- `edit_grep(lines:string[], context:fzfx.PipelineContext):nil`: use `edit` and `setpos` command to open selected locations on `grep`, `git grep` results.
- `setqflist_grep(lines:string[], context:fzfx.PipelineContext):nil`: use `setqflist` command to send selected locations to qflist.

#### `git status`

The `git status` generated git status (changed file names), used by `FzfxGStatus`. they look like:

```
 D fzfx/constants.lua
 M fzfx/line_helpers.lua
 M ../test/line_helpers_spec.lua
?? ../hello
```

- `edit_git_status(lines:string[]):nil`: use `edit` command to open selected file names on `git status` results.

#### `git branch`

The `git branch (-r/-a)` generated git branches, used by `FzfxGBranches`. they look like:

```
* chore-lint
  main
  remotes/origin/HEAD -> origin/main
  remotes/origin/chore-lint
  remotes/origin/main
```

- `git_checkout(lines:string[], fzfx.GitBranchesPipelineContext):nil`: use `git checkout` shell command to checkout selected branch on `git branch` results.

#### `git log`, `git blame`

The `git log --short`, `git blame` generated git commits, used by `FzfxGCommits`, `FzfxGBlame`, they look like:

```
c2e32c 2023-11-30 linrongbin16 (HEAD -> chore-lint)
5fe6ad 2023-11-29 linrongbin16 chore
```

- `yank_git_commit(lines:string[]):nil`: yank selected git commits on `git log`, `git blame` results.

#### Builtin Vim Commands Renderer

The builtin renderer generated vim commands, used by `FzfxCommands`. they look like:

```
Name              Bang|Bar|Nargs|Range|Complete         Desc/Location
:!                N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1122
:Next             N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1124
:bdelete          N   |Y  |N/A  |N/A  |N/A              "delete buffer"
```

- `feed_vim_command(lines:string[], context:fzfx.VimCommandsPipelineContext):nil`: input selected command in vim command line.

#### Builtin Vim Key Mappings Renderer

The builtin renderer generated vim key mappings, used by `FzfxKeyMaps`. they look like:

```
Lhs                                          Mode|Noremap|Nowait|Silent Rhs/Location
<C-F>                                            |N      |N     |N      ~/.config/nvim/lazy/nvim-cmp/lua/cmp/utils/keymap.lua:127
<CR>                                             |N      |N     |N      ~/.config/nvim/lazy/nvim-cmp/lua/cmp/utils/keymap.lua:127
<Plug>(YankyGPutAfterShiftRight)             n   |Y      |N     |Y      ~/.config/nvim/lazy/yanky.nvim/lua/yanky.lua:369
%                                            n   |N      |N     |Y      "<Plug>(matchup-%)"
&                                            n   |Y      |N     |N      ":&&<CR>"
<2-LeftMouse>                                n   |N      |N     |Y      "<Plug>(matchup-double-click)"
```

- `feed_vim_key(lines:string[], context:fzfx.VimKeyMapsPipelineContext):nil`: execute selected keys.

#### `eza`, `lsd`, `ls`

The `lsd`, `eza`, `ls` generated file names/directories, they look like:

```
-rw-r--r--   1 linrongbin  staff   1.0K Aug 28 12:39 LICENSE
-rw-r--r--   1 linrongbin  staff    27K Oct  8 11:37 README.md
drwxr-xr-x   3 linrongbin  staff    96B Aug 28 12:39 autoload
drwxr-xr-x   4 linrongbin  staff   128B Sep 22 10:11 bin
-rw-r--r--   1 linrongbin  staff   120B Sep  5 14:14 codecov.yml
```

- `edit_ls(lines:string[], context:fzfx.FileExplorerPipelineContext):nil`: use `edit` command to open selected file path on `lsd`, `eza`, `ls` results.

### [fzfx.helper.previewer_labels](/lua/fzfx/helper/previewer_labels.lua)

- `label_find(lines:string):string`: label files on `fd`, `find`, `git ls-files` results, and other sources following the same style, used by:
  - `FzfxFiles`
  - `FzfxBuffers`
  - `FzfxGFiles`
- `label_rg(line:string):string`: label locations on `rg` results, and other sources following the same style, used by:
  - `FzfxLiveGrep`
  - `FzfxLspDiagnostics`
  - `FzfxLspDefinitions`
  - `FzfxLspTypeDefinitions`
  - `FzfxLspImplementations`
  - `FzfxLspReferences`
  - `FzfxLspIncomingCalls`
  - `FzfxLspOutgoingCalls`
- `label_grep(line:string):string`: label locations on `grep` results, and other sources following the same style, used by:
  - `FzfxLiveGrep` (when `rg` not found)
  - `FzfxGLiveGrep`
- `label_lsd(line:string,context:fzfx.FileExplorerPipelineContext):string`: label file name/directory on `lsd` results, and other sources follow the same style. used by:
  - `FzfxFileExplorer` (when `lsd` is found)
- `label_eza(line:string,context:fzfx.FileExplorerPipelineContext):string`: label file name/directory on `eza`, `exa` results, and other sources follow the same style. used by:
  - `FzfxFileExplorer` (when `eza`, `exa` is found)
- `label_ls(line:string,context:fzfx.FileExplorerPipelineContext):string`: label file name/directory on `ls` results, and other sources follow the same style. used by:
  - `FzfxFileExplorer` (when `lsd`, `eza`, `exa` not found)
- `label_vim_command(line:string,context:fzfx.VimCommandsPipelineContext):string`: label the builtin vim commands renderer results, and other sources follow the same style. used by:
  - `FzfxCommands`
- `label_vim_keymap(line:string,context:fzfx.VimKeyMapsPipelineContext):string`: label the builtin vim keymaps renderer results, and other sources follow the same style. used by:
  - `FzfxKeyMaps`

### [fzfx.helper.previewers](/lua/fzfx/helper/previewers.lua)

- `preview_files(filename:string, lineno:integer?):string[]`: preview files with `filename` and optional `lineno` on `fd`/`find` and `rg`/`grep` results, internal API used by `preview_files_find` and `preview_files_grep`.

  > For rg/grep, the line number is always the 2nd column split by colon ':'.
  > so we use fzf's option '--preview-window=+{2}-/2', '--delimiter=:' with live grep configs.
  > the `+{2}-/2` indicates:
  >
  > 1. the 2nd column (split by colon ':') is the line number
  > 2. set it as the highlight line
  > 3. place it in the center (1/2) of the whole preview window

- `preview_files_find(line:string):string[]`: preview files on `fd`, `find`, `git ls-files` results, and other sources following the same style, used by:
  - `FzfxFiles`
  - `FzfxBuffers`
  - `FzfxGFiles`
- `preview_files_grep(line:string):string[]`: preview locations on `rg`, `grep`, `git grep` results, and other sources following the same style, used by:
  - `FzfxLiveGrep`
  - `FzfxGLiveGrep`
  - `FzfxLspDiagnostics`
  - `FzfxLspDefinitions`
  - `FzfxLspTypeDefinitions`
  - `FzfxLspImplementations`
  - `FzfxLspReferences`
  - `FzfxLspIncomingCalls`
  - `FzfxLspOutgoingCalls`
- `preview_git_commit(line:string):string`: preview git commits on `git blame`, `git log --short` results, and other sources following the same style, used by:
  - `FzfxGCommits`
  - `FzfxGBlame`
- `preview_files_with_line_range(filename:string, lineno:integer):string[]`: preview files with `filename` and mandatory `lineno` on self-rendered results.

  > For self-rendered lines (unlike rg/grep), we don't have the line number split by colon ':'.
  > thus we cannot set fzf's option '--preview-window=+{2}-/2' or '--delimiter=:' (also see `preview_files`).
  > so we set `--line-range={lstart}:` (in bat) to try to place the highlight line in the center of the preview window.

  Used by:

  - `FzfxCommands`
  - `FzfxKeyMaps`

### [fzfx.helper.providers](/lua/fzfx/helper/providers.lua)

### [fzfx.helper.provider_decorators](/lua/fzfx/helper/provider_decorators/)

- `prepend_icon_find.decorate(line:string?):string`: (in [prepend_icon_find](/lua/fzfx/helper/provider_decorators/prepend_icon_find.lua) module) prepend file type icon on `fd`/`find` results, or other sources following the same style, used by:

  - `FzfxFiles`

- `prepend_icon_grep.decorate(line:string?):string`: (in [prepend_icon_grep](/lua/fzfx/helper/provider_decorators/prepend_icon_grep.lua) module) prepend file type icon on `rg`/`grep` results, or other sources following the same style, used by:
  - `FzfxLiveGrep`

### [fzfx.helper.queries](/lua/fzfx/helper/queries.lua)

- `parse_flagged(query:string,flag:string?):{payload:string,option:string?}`: split user's input query with the `--` flag, returns query body `payload` and dynamically append `option`.

### [fzfx.helper.prompts](/lua/fzfx/helper/prompts.lua)

- `confirm_discard_modified(bufnr:integer, callback:fun():nil):nil`: popup a prompt to ask user confirm whether to discard current buffer's modifications (only if there's any), invoke `callback` if user confirm, do nothing if user cancel.

## [`fzfx.lib`](/lua/fzfx/lib) Module

> [!NOTE]
>
> Most of the `fzfx.lib` is migrate to the [commons](https://github.com/linrongbin16/commons.nvim) lua library.
>
> Please also refer to [commons.nvim's documentation](https://linrongbin16.github.io/commons.nvim/#/) for better API references.

### [fzfx.lib.colors](/lua/fzfx/lib/colors.lua)

- `csi(code:string, fg:boolean):string`: convert ansi color codes (`38`, `42`) or rgb/css color codes (`#FF3810`) into terminal escaped sequences (`\x1b[38m`, `\x1b[0m`). set `fg=true` for foreground, set `fg=false` for background.
  - for ansi color codes, please see: https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797#color-codes
  - for rgb/css color codes, please see: https://www.w3schools.com/tags/ref_colornames.asp
- `hlcode(attr:"fg"|"bg", hl:string):string?`: retrieve ansi color codes or rgb/css color codes from vim syntax highlighting group (e.g. `Special`, `Constants`, `Number`).
- `ansi(text:string, name:string, hl:string?):string?`: render `text` with specified color name `name` (e.g. `red`, `green`, `magenta`), if use vim syntax highlighting if `hl` is provided.
- `erase(text:string):string`: erase colors from terminal escaped contents.

Here are the builtin colors:

- `black(text:string, hl:string?):string`: render `text` with `black`, use vim syntax highlighting if `hl` provided
- `grey(text:string, hl:string?):string`: same.
- `silver(text:string, hl:string?):string`: same.
- `white(text:string, hl:string?):string`: same.
- `violet(text:string, hl:string?):string`: same.
- `magenta(text:string, hl:string?):string`: same, or `fuchsia`.
- `red(text:string, hl:string?):string`: same.
- `purple(text:string, hl:string?):string`: same.
- `indigo(text:string, hl:string?):string`: same.
- `yellow(text:string, hl:string?):string`: same.
- `gold(text:string, hl:string?):string`: same.
- `orange(text:string, hl:string?):string`: same.
- `chocolate(text:string, hl:string?):string`: same.
- `olive(text:string, hl:string?):string`: same.
- `green(text:string, hl:string?):string`: same.
- `lime(text:string, hl:string?):string`: same.
- `teal(text:string, hl:string?):string`: same.
- `cyan(text:string, hl:string?):string`: same, or `aqua`.
- `blue(text:string, hl:string?):string`: same.
- `navy(text:string, hl:string?):string`: same.
- `slateblue(text:string, hl:string?):string`: same.
- `steelblue(text:string, hl:string?):string`: same.

- `render(renderer:fun(text:string, hl:string?):string, hl:string?, fmt:string, ...:any):string`: render parameters `...` with `renderer` and optional `hl`, and format with `fmt`.

### [fzfx.lib.commands](/lua/fzfx/lib/commands.lua)

- `CommandResult`: command line result

  - fields:
    - `stdout:string[]|nil`: stdout lines.
    - `stderr:string[]|nil`: stderr lines.
    - `code:integer?`: exit code.
    - `signal:integer?`: signal.
  - `failed():boolean`: exit code `code ~= 0` and `stderr` not empty.

- `Command`: command line (blocking mode spawn).

  - `run(cmds:string[]):Command`: run command line, return handle.
  - `failed():boolean`: same with `CommandResult`, use `Command.result` to get command line result.

- `GitRootCommand`

  - `run():GitRootCommand`: run `git rev-parse --show-toplevel`, return handle.
  - `failed():boolean`: same with `Command`, use `GitRootCommand.result` to get command line result.
  - `output():string?`: get the command output.

- `GitBranchesCommand`

  - `run(remotes:boolean?):GitBranchesCommand`: run `git branch` or `git branch --remotes`, return handle.
  - `failed():boolean`: same with `Command`, use `GitBranchesCommand.result` to get command line result.
  - `output():string[]|nil`: get the command output.

- `GitCurrentBranchCommand`
  - `run():GitCurrentBranchCommand`: run `git rev-parse --abbrev-ref HEAD`, return handle.
  - `failed():boolean`: same with `Command`, use `GitCurrentBranchCommand.result` to get command line result.
  - `output():string?`: get the command output.

### [fzfx.lib.constants](/lua/fzfx/lib/constants.lua)

#### OS

- `IS_WINDOWS`: is Windows.
- `IS_MACOS`: is macOS.
- `IS_BSD`: is BSD.
- `IS_LINUX`: is UNIX or Linux.

#### Command Line

bat/cat

- `HAS_BAT`: has `bat` command.
- `BAT`: `bat` command.
- `HAS_CAT`: has `cat` command.
- `CAT`: `cat` command.

rg/grep

- `HAS_RG`: has `rg` command.
- `RG`: `rg` command.
- `HAS_GNU_GREP`: has gnu `grep`/`ggrep` command.
- `GNU_GREP`: `grep`/`ggrep` command.
- `HAS_GREP`: has `grep`/`ggrep` command.
- `GREP`: `grep`/`ggrep` command.

fd/find

- `HAS_FD`: has `fd` command.
- `FD`: `fd` command.
- `HAS_FIND`: has `find`/`gfind` command.
- `FIND`: `find`/`gfind` command.

ls/lsd/eza

- `HAS_LS`: has `ls` command.
- `LS`: `ls` command.
- `HAS_LSD`: has `lsd` command.
- `LSD`: `lsd` command.
- `HAS_EZA`: has `eza`/`exa` command.
- `EZA`: `eza`/`exa` command.

git/delta

- `HAS_GIT`: has `git` command.
- `GIT`: `git` command.
- `HAS_DELTA`: has `delta` command.
- `DELTA`: `delta` command.

echo

- `HAS_ECHO`: has `echo` command.
- `ECHO`: `echo` command.

curl

- `HAS_CURL`: has `curl` command.
- `CURL`: `curl` command.

### [fzfx.lib.deprecations](/lua/fzfx/lib/deprecations.lua)

- `notify(fmt:string, ...:any):nil`: print deprecation notifications to command line.

### [fzfx.lib.env](/lua/fzfx/lib/env.lua)

- `debug_enabled():boolean`: detect whether environment variable `_FZFX_NVIM_DEBUG_ENABLE=1`.
- `icon_enabled():boolean`: detect whether environment variable `_FZFX_NVIM_DEVICONS_PATH=1`.

### [fzfx.lib.filesystems](/lua/fzfx/lib/filesystems.lua)

#### Read File

- `FileLineReader`: file line reader.
  - `open(filename:string, batchsize:integer?):FileLineReader`: open file to read, return the reader handle, by default `batchsize=4096`.
  - `has_next():boolean`: detect whether there are more lines to read.
  - `next():string?`: get next line.
  - `close():nil`: close the reader handle.
- `readlines(filename:string):string[]|nil`: open file and read line by line.
- `readfile(filename:string, opts:{trim:boolean?}?):string?`: open and read all contents from file.
  - set `opts={trim=true}` to trim whitespaces, by default `opts={trim=true}`.
- `asyncreadfile(filename:string, on_complete:fun(data:string?):any, opts:{trim:boolean?}?):nil`: async read file, invoke callback `on_complete` when done.

#### Write File

- `writefile(filename:string, content:string):integer`: write content into file, return `-1` if fail, `0` if success.
- `writelines(filename:string, lines:string[]):integer`: write lines into file, return `-1` if fail, `0` if success.
- `asyncwritefile(filename:string, content:string, on_complete:fun(bytes:integer?):any):integer`: async write content into a file, invoke callback `on_complete` when done.

### [fzfx.lib.jsons](#/lua/fzfx/lib/jsons.lua)

- `encode(t:table?):string?`: convert lua table/list to json string.
- `decode(s:string?):table?`: convert json string to lua table/list.

### [fzfx.lib.log](/lua/fzfx/lib/log.lua)

- `debug(fmt:string, ...)`: debug, the `fmt` is formatting messages in C style formatters, e.g. `%d`, `%s`.
- `info(fmt:string, ...)`: info.
- `warn(fmt:string, ...)`: warning.
- `err(fmt:string, ...)`: error
- `echo(level:LogLevels, fmt:string, ...)`: echo message in log `level`. this API will not been affected by log configs.
  - `LogLevels.DEBUG`.
  - `LogLevels.INFO`.
  - `LogLevels.WARN`.
  - `LogLevels.ERROR`.
- `throw(fmt:string, ...)`: same with `err`, additionally it invokes `error()` API, which throw an error to user command line, requires user to press `ENTER` to continue.
- `ensure(condition:boolean, fmt:string, ...)`: throw error to user if `condition` is false.

### [fzfx.lib.numbers](/lua/fzfx/lib/numbers.lua)

- `INT32_MIN`/`INT32_MAX`: `-2147483648`/`2147483647`.
- `positive(n:number?):boolean`/`negative(n:number?):boolean`: is positive/negative number, e.g. `n > 0`/`n < 0`.
- `non_positive(n:number?):boolean`/`non_negative(n:number?):boolean`: is non-positive/non-negative number, e.g. `n <= 0`/`n >= 0`.
- `bound(value:integer, left:integer, right:integer):integer`: returned value is bounded in range `[left, right]`.
- `inc_id():integer`: returned incremental ID.

### [fzfx.lib.nvims](/lua/fzfx/lib/nvims.lua)

#### Buffer

- `get_buf_option(bufnr:integer, name:string):any`: get buffer option.
- `set_buf_option(bufnr:integer, name:string, value:any):nil`: set buffer option.
- `buf_is_valid(bufnr:integer):boolean`: check if buffer is valid.

#### Window

- `get_win_option(winnr:integer, name:string):any`: get window option.
- `set_win_option(winnr:integer, name:string, value:any):nil`: set window option.
- `WindowOptsContext`: window options context.
  - `save():WindowOptsContext`: save current windows & tabs and return context.
  - `restore():nil`: restore previously saved windows & tabs.

#### Shell

- `shellescape(s:string, special:string?):string`: escape shell strings, especially single(`''`)/double(`""`) quotes.
- `ShellOptsContext`: shell options context.
  - `save():ShellOptsContext`: save current shell options and return context.
  - `restore():nil`: restore previously saved shell options.

### [fzfx.lib.paths](/lua/fzfx/lib/paths.lua)

- `SEPARATOR`: `\\` for Windows, `/` for Unix/Linux.
- `normalize(p:string, opts:{backslash:boolean?,expand:boolean?}?)`: normalize path string, replace `\\\\` to `\\`.
  - set `opts.backslash=true` to replace `\\` to `/`, set `opts.expand=true` to expand path to full path, by default `opts={backslash=false, expand=false}`.
- `join(...):string`: join multiple parts into path string with `SEPARATOR`.
- `reduce2home(p:string):string`: reduce path string relative to `$HOME` directory.
- `reduce(p:string):string`: reduce path string relative to `$HOME` directory or `$PWD` directory.
- `shorten(p:string):string`: shorten path string to use single char to replace each level directories, e.g. `~/g/l/fzfx.nvim`.

### [fzfx.lib.spawn](/lua/fzfx/lib/spawn.lua)

- `Spawn`: run child process and process stdout/stderr line by line.
  - `make(cmds:string[], opts:{on_stdout:fun(line:string):any, on_stderr:fun(line:string):any|nil, blocking:boolean}):Spawn`: prepare child process, return `Spawn` handle.
    - `on_stdout(line:string):any`: invoke callback when there's a new line ready to process on `stdout` fd.
    - `on_stderr(line:string):any`: invoke callback when there's a new line ready to process on `stderr` fd.
    - `blocking`: set `blocking=true` if need to wait for child process finish, set `blocking=false` if no need to wait.
  - `run():nil`: run child process, wait child process done for blocking mode, use `Spawn.result` to get the child process result.

### [fzfx.lib.strings](/lua/fzfx/lib/strings.lua)

- `empty(s:string?):boolean`/`not_empty(s:string?):boolean`: detect whether a string is empty or not.
- `blank(s:string?):boolean`/`not_blank(s:string?):boolean`: detect whether a string is blank or not.
- `find(s:string, t:string, start:integer?):integer?`: find first `t` in `s` start from `start`, by default `start=1`.
- `rfind(s:string, t:string, rstart:integer?):integer?`: reversely find last `t` in `s` start from `rstart`, by default `rstart=#s`.
- `ltrim(s:string, t:string):string`/`rtrim(s:string, t:string):string`: trim left/right `t` from `s`, by default `t` is whitespaces (`\n\t\r `).
- `split(s:string, delimiter:string, opts:{plain:boolean?,trimempty:boolean?}?):string`: split `s` by `delimiter`.
  - set `opts.plain=false` to use lua pattern matching, set `opts.trimempty=false` to not remove whitespaces from results. by default `opts={plain=true, trimempty=true}`.
- `startswith(s:string, t:string):boolean`/`endswith(s:string, t:string):boolean`: detect whether `s` is start/end with `t`.
- `isspace(c:string):boolean`: detect whether character `c` is whitespace (`\n\t\r `), `c` length must be 1.
- `isalnum(c:string):boolean`: detect whether character `c` is letter or number (`a-zA-Z0-9`), `c` length must be 1.
- `isdigit(c:string):boolean`: detect whether character `c` is number (`0-9`), `c` length must be 1.
- `ishex(c:string):boolean`: detect whether character `c` is hex number (`a-eA-E0-9`), `c` length must be 1.
- `isalpha(c:string):boolean`: detect whether character `c` is letter (`a-zA-Z`), `c` length must be 1.
- `islower(c:string):boolean`/`isupper(c:string):boolean`: detect whether character `c` is lower letter (`a-z`) or upper letter (`A-Z`), `c` length must be 1.
- `uuid(delimiter:string?):string`: make uuid, by default `delimiter='-'`.

### [fzfx.lib.tables](/lua/fzfx/lib/tables.lua)

#### Table

- `tbl_empty(t:any):boolean`/`tbl_not_empty(t:any):boolean`: detect whether a table is empty or not.
- `tbl_get(t:any, field:string):any`: retrieve value from table, with json-like field indexing via dot `.` delimiter, for example when parameter `t = {a = { b = 1 }}`, `field = 'a.b'`, this function will return `1`. When `field = ''` returns `t` itself, when field not exist returns `nil`.

#### List

- `list_empty(l:any):boolean`/`list_not_empty(l:any):boolean`: detect whether a list(table) is empty or not.
- `list_index(i:integer, n:integer):integer`: calculate list index for both positive or negative. `n` is the length of list.
  - if `i > 0`, `i` is in range `[1,n]`.
  - if `i < 0`, `i` is in range `[-1,-n]`, `-1` maps to last position (e.g. `n`), `-n` maps to first position (e.g. `1`).
