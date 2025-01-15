# API References

The modules in `fzfx.cfg` are recommended as a reference when you want to customize/implement your own search commands.

The APIs in `fzfx.helper` and `fzfx.lib` are recommended when you implement something in fzfx, they are supposed to be stable and tested.

> Except those APIs start with underline `_`, which are exposed for unit tests.

## [fzfx.cfg](https://github.com/linrongbin16/fzfx.nvim/lua/fzfx/cfg)

The `fzfx.cfg` module directly provide configurations for all search commands in this plugin.

> Before continue, you may need to read [A General Schema for Creating FZF Command](https://linrongbin16.github.io/fzfx.nvim/#/GenericSchema.md) to understand why it's structured this way.

A real-world search command, say `FzfxLiveGrep`, actually defined multiple user commands:

- `FzfxLiveGrep (unres_/buf_)args`
- `FzfxLiveGrep (unres_/buf_)visual`
- `FzfxLiveGrep (unres_/buf_)cword`
- `FzfxLiveGrep (unres_/buf_)put`
- `FzfxLiveGrep (unres_/buf_)resume`

They're all defined in the `fzfx.cfg.live_grep` module, it's called a group.

Each group contains below components:

- `command`: a [`fzfx.CommandConfig`](https://github.com/linrongbin16/fzfx.nvim/blob/53b8a79981c8aa5a5c8a15bea7efeb21d1ca6de7/lua/fzfx/schema.lua?plain=1#L116) that defines the command name and description.
- `variants`
  - For only 1 variant, it's a single [`fzfx.VariantConfig`](https://github.com/linrongbin16/fzfx.nvim/blob/53b8a79981c8aa5a5c8a15bea7efeb21d1ca6de7/lua/fzfx/schema.lua?plain=1#L114).
  - For multiple variants, it's a `fzfx.VariantConfig` list .
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

### [buffers](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/buffers.lua)

Defines the `FzfxBuffers` command.

> The data source use same style with `FzfxFiles` command, e.g. the `fd`/`find` result, see [fzfx.cfg.files](#files).

### [file_explorer](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/file_explorer.lua)

Defines the `FzfxFileExplorer` command. The search result from `ls`/`lsd`/`eza` looks like:

![FzfxFileExplorer](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/5e402a20-6c96-43a1-a463-345cd2bd86c7)

Each line is constructed with multiple file/directory attributes and **file name**, split by uncertained count of whitespaces `" "`.

It's implemented with `ls`/`lsd`/`eza` utilities:

- [fzfx.helper.parsers.parse_ls](#parse_ls)
- [fzfx.helper.parsers.parse_lsd](#parse_lsd)
- [fzfx.helper.parsers.parse_eza](#parse_eza)

### [files](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/files.lua)

Defines the `FzfxFiles` command. The search result from `fd`/`find` looks like:

![FzfxFiles](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/fa9649d4-4007-4e53-ad70-dcfb86612492)

Each line is a file name, prepend with a file type icon (only the the icon option is enabled).

It's implemented with `fd`/`find` utilities:

- [fzfx.helper.parsers.parse_find](#parse_find)
- [fzfx.helper.actions.edit_find](#edit_find)
- [fzfx.helper.actions.setqflist_find](#setqflist_find)

### [git_blame](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_blame.lua)

Defines the `FzfxGBlame` command.

> The data source use same style with `FzfxGCommits` commands, e.g. the `git log` result, see [fzfx.cfg.git_commits](#git_commits).

### [git_branches](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_branches.lua)

Defines the `FzfxGBranches` command. The search result from `git branch` looks like:

For local branches:

![FzfxGBranches-local](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/1619f4bc-eae5-4489-823b-43ede4890420)

For remote branches:

![FzfxGBranches-remote](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/440857b8-ad54-49bf-90bd-df68dde46f3d)

Each line is a git **branch name**.

It's implemented with `git_branch` utilities:

- [fzfx.helper.parsers.parse_git_branch](#parse_git_branch)
- [fzfx.helper.actions.git_checkout](#git_checkout)

### [git_commits](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_commits.lua)

Defines the `FzfxGCommits` command. The search result from `git log` looks like:

![FzfxGCommits](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/1cac26af-c94c-4606-806e-759ec33ceb9f)

Each line starts with a git **commit number**.

It's implemented with `git_commit` utilities:

- [fzfx.helper.parsers.parse_git_commit](#parse_git_commit)
- [fzfx.helper.actions.yank_git_commit](#yank_git_commit)

### [git_files](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_files.lua)

Defines the `FzfxGFiles` command.

> The data source use same style with `FzfxFiles` commands, e.g. the `fd`/`find` result, see [fzfx.cfg.files](#files).

### [git_live_grep](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_live_grep.lua)

Defines the `FzfxGLiveGrep` command. The search results from `git grep` looks like:

![FzfxGLiveGrep](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/55faae50-6266-479d-8a69-6462963d9558)

Each line is constructed with **file name** and **line number**, split by colon `":"`, and prepend with file type icon (only when icon is enabled).

> The `grep` result has no column number, e.g. the 3rd column in `rg` result.

It's implemented with `grep` utilities:

- [fzfx.helper.parsers.parse_grep](#parse_grep)

### [git_status](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/git_status.lua)

Defines the `FzfxGStatus` command. The search results from `git status` looks like:

![FzfxGStatus](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/31946271-e0f3-406f-af93-2ec88108e189)

Each line is constructed with changed **file name**, and prepend with git status symbol.

It's implemented with `git_status` utilities:

- [fzfx.helper.parsers.parse_git_status](#parse_git_status)

### [live_grep](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/live_grep.lua)

Defines the `FzfxLiveGrep` command. The search results from `rg` looks like:

![FzfxLiveGrep](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/170ad807-a0f3-4092-9555-13ae67f38560)

Each line is constructed with **file name**, **line number** and **column number**, split by colon `":"`, and prepend with file type icon (only when icon is enabled).

It's implemented with `rg` or `grep` (when `rg` not found) utilities:

- [fzfx.helper.parsers.parse_rg](#parse_rg)
- [fzfx.helper.parsers.parse_grep](#parse_grep)
- [fzfx.helper.actions.edit_rg](#edit_rg)

### [lsp_definitions](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_definitions.lua)

Defines the `FzfxLspDefinitions` command.

> The data source use same style with `FzfxLiveGrep` commands, e.g. the `rg`/`grep` result, see [fzfx.cfg.live_grep](#live_grep).

### [lsp_diagnostics](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_diagnostics.lua)

Defines the `FzfxLspDiagnostics` command.

> The data source use same style with `FzfxLiveGrep` commands, e.g. the `rg`/`grep` result, see [fzfx.cfg.live_grep](#live_grep).

### [lsp_implementations](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_implementations.lua)

Defines the `FzfxLspImplementations` command.

> The data source use same style with `FzfxLiveGrep` commands, e.g. the `rg`/`grep` result, see [fzfx.cfg.live_grep](#live_grep).

### [lsp_incoming_calls](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_incoming_calls.lua)

Defines the `FzfxLspIncomingCalls` command.

> The data source use same style with `FzfxLiveGrep` commands, e.g. the `rg`/`grep` result, see [fzfx.cfg.live_grep](#live_grep).

### [lsp_outgoing_calls](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_outgoing_calls.lua)

Defines the `FzfxLspOutgoingCalls` command.

> The data source use same style with `FzfxLiveGrep` commands, e.g. the `rg`/`grep` result, see [fzfx.cfg.live_grep](#live_grep).

### [lsp_references](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_references.lua)

Defines the `FzfxLspReferences` command.

> The data source use same style with `FzfxLiveGrep` commands, e.g. the `rg`/`grep` result, see [fzfx.cfg.live_grep](#live_grep).

### [lsp_type_definitions](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/lsp_type_definitions.lua)

Defines the `FzfxLspTypeDefinitions` command.

> The data source use same style with `FzfxLiveGrep` commands, e.g. the `rg`/`grep` result, see [fzfx.cfg.live_grep](#live_grep).

### [vim_commands](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/vim_commands.lua)

Defines the `FzfxCommands` command. The self-rendered search result looks like:

![FzfxCommands](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/5abe8ccd-e98f-4e15-b827-82d93491d0c0)

Each line is constructed with command **name**, **attributes** and **definition/location**, split by uncertained count of whitespaces `" "`.

It's implemented with `vim_command` utilities:

- [fzfx.helper.parsers.parse_vim_command](#parse_vim_command)
- [fzfx.helper.actions.feed_vim_command](#feed_vim_command)

### [vim_keymaps](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/cfg/vim_keymaps.lua)

Defines the `FzfxKeyMaps` command. The self-rendered search result looks like:

![FzfxKeyMaps](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/970bb0dd-e010-4f52-b972-970cf888be75)

Each line is constructed with key mapping **left hands**, **attributes** and **definition/location**, split by uncertained count of whitespaces `" "`.

It's implemented with `vim_keymap` utilities:

- [fzfx.helper.parsers.parse_vim_keymap](#parse_vim_keymap)
- [fzfx.helper.actions.feed_vim_key](#feed_vim_key)

## [fzfx.helper](https://github.com/linrongbin16/fzfx.nvim/lua/fzfx/helper)

The `fzfx.helper` module provide line-oriented helpers for parsing and rendering queries/lines required in all scenarios.

> Since a search command is actually all about the lines in (both left and right side of) the fzf binary: generate lines, preview lines, invoke callbacks on selected lines, etc.

### [parsers](https://github.com/linrongbin16/fzfx.nvim/lua/fzfx/helper/parsers.lua)

The `fzfx.helper.parsers` are lower-level components (compared with others in `fzfx.helper`) that help **previewer** and **action** understand the lines generated from **provider**, e.g. it's the bridge between data producers and consumers.

#### [`parse_find`](https://github.com/linrongbin16/fzfx.nvim/blob/e929c19fe5427e8eca41e4d108d7f1ab56adb845/lua/fzfx/helper/parsers.lua?plain=1#L25)

Parse the line generated by `fd`/`find` (or other sources follow the same style), remove the prepend icon if exists.

#### [`parse_rg`](https://github.com/linrongbin16/fzfx.nvim/blob/e929c19fe5427e8eca41e4d108d7f1ab56adb845/lua/fzfx/helper/parsers.lua?plain=1#L92)

Parse the line generated by `rg` (or other sources follow the same style), remove the prepend icon if exists.

#### [`parse_grep`](https://github.com/linrongbin16/fzfx.nvim/blob/e929c19fe5427e8eca41e4d108d7f1ab56adb845/lua/fzfx/helper/parsers.lua?plain=1#L47)

Parse the line generated by `grep`/`git grep` (or other sources follow the same style), remove the prepend icon if exists.

> The result from `grep` doesn't have column number (the 3rd column).

#### [`parse_git_status`](https://github.com/linrongbin16/fzfx.nvim/blob/549984fb1eae6251bb56a2d1e8b85ef8d7742bf5/lua/fzfx/helper/parsers.lua?plain=1#L146)

Parse the line generated by `git status` or other sources follow the same style, remove the prepend git symbol.

#### [`parse_git_branch`](https://github.com/linrongbin16/fzfx.nvim/blob/549984fb1eae6251bb56a2d1e8b85ef8d7742bf5/lua/fzfx/helper/parsers.lua?plain=1#L168)

Parse the line generated by `git branch (-r)` or other sources follow the same style.

#### [`parse_git_commit`](https://github.com/linrongbin16/fzfx.nvim/blob/549984fb1eae6251bb56a2d1e8b85ef8d7742bf5/lua/fzfx/helper/parsers.lua?plain=1#L288)

Parse the line generated by `git log`/`git blame` or other sources follow the same style.

#### [`parse_lsd`](https://github.com/linrongbin16/fzfx.nvim/blob/549984fb1eae6251bb56a2d1e8b85ef8d7742bf5/lua/fzfx/helper/parsers.lua?plain=1#L404)

Parse the line generated by `lsd` or other sources follow the same style.

#### [`parse_eza`](https://github.com/linrongbin16/fzfx.nvim/blob/549984fb1eae6251bb56a2d1e8b85ef8d7742bf5/lua/fzfx/helper/parsers.lua?plain=1#L403)

Parse the line generated by `eza`/`exa` or other sources follow the same style.

#### [`parse_ls`](https://github.com/linrongbin16/fzfx.nvim/blob/549984fb1eae6251bb56a2d1e8b85ef8d7742bf5/lua/fzfx/helper/parsers.lua?plain=1#L402)

Parse the line generated by `ls` or other sources follow the same style.

#### [`parse_vim_command`](https://github.com/linrongbin16/fzfx.nvim/blob/549984fb1eae6251bb56a2d1e8b85ef8d7742bf5/lua/fzfx/helper/parsers.lua?plain=1#L420)

Parse the line generated by builtin vim commands renderer or other sources follow the same style.

#### [`parse_vim_keymap`](https://github.com/linrongbin16/fzfx.nvim/blob/549984fb1eae6251bb56a2d1e8b85ef8d7742bf5/lua/fzfx/helper/parsers.lua?plain=1#L476)

Parse the line generated by builtin vim keymaps renderer or other sources follow the same style.

### [actions](https://github.com/linrongbin16/fzfx.nvim/lua/fzfx/helper/parsers.lua)

The `fzfx.helper.actions` are hook functions binding to the command, user can press the key and exit fzf, then invoke these hook functions with selected lines.

#### [`nop`](https://github.com/linrongbin16/fzfx.nvim/blob/1e81d0bf3385251107e02d14308896e970acc043/lua/fzfx/helper/actions.lua?plain=1#L14)

Do nothing.

#### [`edit_find`](https://github.com/linrongbin16/fzfx.nvim/blob/1e81d0bf3385251107e02d14308896e970acc043/lua/fzfx/helper/actions.lua?plain=1#L32)

Use `edit` command to open selected files on `fd`/`find` results, or other data sources in the same style.

#### [`setqflist_find`](https://github.com/linrongbin16/fzfx.nvim/blob/1e81d0bf3385251107e02d14308896e970acc043/lua/fzfx/helper/actions.lua?plain=1#L55)

Use `setqflist` command to send selected files to qflist.

#### [`edit_rg`](https://github.com/linrongbin16/fzfx.nvim/blob/1e81d0bf3385251107e02d14308896e970acc043/lua/fzfx/helper/actions.lua?plain=1#L88)

Use `edit` and `setpos` command to open selected locations on `rg` results.

#### [`setqflist_rg`](https://github.com/linrongbin16/fzfx.nvim/blob/1e81d0bf3385251107e02d14308896e970acc043/lua/fzfx/helper/actions.lua?plain=1#L116)

Use `setqflist` command to send selected locations to qflist.

#### [`edit_grep`](https://github.com/linrongbin16/fzfx.nvim/blob/1e81d0bf3385251107e02d14308896e970acc043/lua/fzfx/helper/actions.lua?plain=1#L149)

Use `edit` and `setpos` command to open selected locations on `grep`, `git grep` results.

#### [`setqflist_grep`](https://github.com/linrongbin16/fzfx.nvim/blob/cdb88202d551f3986f6b2240908b975697e0f511/lua/fzfx/helper/actions.lua?plain=1#L178)

Use `setqflist` command to send selected locations to qflist.

#### `git status`

The `git status` generated git status (changed file names), used by `FzfxGStatus`. they look like:

```
 D fzfx/constants.lua
 M fzfx/line_helpers.lua
 M ../test/line_helpers_spec.lua
?? ../hello
```

#### [`edit_git_status`](https://github.com/linrongbin16/fzfx.nvim/blob/cdb88202d551f3986f6b2240908b975697e0f511/lua/fzfx/helper/actions.lua?plain=1#L372)

Use `edit` command to open selected file names on `git status` results.

#### [`git_checkout`](https://github.com/linrongbin16/fzfx.nvim/blob/a8dff47d1c56385f4f2bb4c5f53e521fdbf3b2d7/lua/fzfx/helper/actions.lua?plain=1#L245)

Use `git checkout` shell command to checkout selected branch on `git branch` results.

#### [`yank_git_commit`](https://github.com/linrongbin16/fzfx.nvim/blob/a8dff47d1c56385f4f2bb4c5f53e521fdbf3b2d7/lua/fzfx/helper/actions.lua?plain=1#L265)

Yank selected git commits on `git log`, `git blame` results.

#### [`feed_vim_command`](https://github.com/linrongbin16/fzfx.nvim/blob/a8dff47d1c56385f4f2bb4c5f53e521fdbf3b2d7/lua/fzfx/helper/actions.lua?plain=1#L288)

Feed selected vim command to vim command line.

#### [`feed_vim_key`](https://github.com/linrongbin16/fzfx.nvim/blob/a8dff47d1c56385f4f2bb4c5f53e521fdbf3b2d7/lua/fzfx/helper/actions.lua?plain=1#L336)

Execute selected vim key mappings.

#### `eza`/`lsd`/`ls`

The `lsd`, `eza`, `ls` generated file names/directories, they look like:

```
-rw-r--r--   1 linrongbin  staff   1.0K Aug 28 12:39 LICENSE
-rw-r--r--   1 linrongbin  staff    27K Oct  8 11:37 README.md
drwxr-xr-x   3 linrongbin  staff    96B Aug 28 12:39 autoload
drwxr-xr-x   4 linrongbin  staff   128B Sep 22 10:11 bin
-rw-r--r--   1 linrongbin  staff   120B Sep  5 14:14 codecov.yml
```

#### [`edit_ls`](https://github.com/linrongbin16/fzfx.nvim/blob/a8dff47d1c56385f4f2bb4c5f53e521fdbf3b2d7/lua/fzfx/helper/actions.lua?plain=1#L215)

Use `edit` command to open selected file path on `ls`/`lsd`/`eza`/`exa` results.

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

### [fzfx.helper.provider_decorators](/lua/fzfx/helper/provider_decorators/)

- `prepend_icon_find.decorate(line:string?):string`: (in [prepend_icon_find](/lua/fzfx/helper/provider_decorators/prepend_icon_find.lua) module) prepend file type icon on `fd`/`find` results, or other sources following the same style, used by:

  - `FzfxFiles`

- `prepend_icon_grep.decorate(line:string?):string`: (in [prepend_icon_grep](/lua/fzfx/helper/provider_decorators/prepend_icon_grep.lua) module) prepend file type icon on `rg`/`grep` results, or other sources following the same style, used by:
  - `FzfxLiveGrep`

### [fzfx.helper.queries](/lua/fzfx/helper/queries.lua)

- `parse_flagged(query:string,flag:string?):{payload:string,option:string?}`: split user's input query with the `--` flag, returns query body `payload` and dynamically append `option`.

### [fzfx.helper.prompts](/lua/fzfx/helper/prompts.lua)

- `confirm_discard_modified(bufnr:integer, callback:fun():nil):nil`: popup a prompt to ask user confirm whether to discard current buffer's modifications (only if there's any), invoke `callback` if user confirm, do nothing if user cancel.

## [fzfx.lib](https://github.com/linrongbin16/fzfx.nvim/lua/fzfx/lib)

> Most of the `fzfx.lib` modules are extracted to the [commons](https://github.com/linrongbin16/commons.nvim) lua library, please also refer to [commons.nvim's documentation](https://linrongbin16.github.io/commons.nvim/#/).

### [fzfx.lib.commands](/lua/fzfx/lib/commands.lua)

#### [`CommandResult`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/commands.lua?plain=1#L14)

The command line result.

Contains below fields:

- `stdout:string[]|nil`: stdout lines.
- `stderr:string[]|nil`: stderr lines.
- `code:integer?`: exit code.
- `signal:integer?`: signal.

Contains below methods:

- `failed():boolean`: exit code `code ~= 0` and `stderr` not empty.

#### [`Command`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/commands.lua?plain=1#L50)

The command line (sync/blocking mode spawn.run).

Contains below methods:

- `run(cmds:string[]):Command`: run command line, return handle.
- `failed():boolean`: same with `CommandResult`, use `Command.result` to get command line result.

#### [`GitRootCommand`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/commands.lua?plain=1#L98)

Find git repository root directory.

Contains below methods:

- `run():GitRootCommand`: run `git rev-parse --show-toplevel`, return handle.
- `failed():boolean`: same with `Command`, use `GitRootCommand.result` to get command line result.
- `output():string?`: get the command output.

#### [`GitBranchesCommand`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/commands.lua?plain=1#L134)

Find git repository local or remote branches.

Contains below methods:

- `run(remotes:boolean?):GitBranchesCommand`: run `git branch` or `git branch --remotes`, return handle.
- `failed():boolean`: same with `Command`, use `GitBranchesCommand.result` to get command line result.
- `output():string[]|nil`: get the command output.

#### [`GitCurrentBranchCommand`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/commands.lua?plain=1#L171)

Find git repository current branch name.

Contains below methods:

- `run():GitCurrentBranchCommand`: run `git rev-parse --abbrev-ref HEAD`, return handle.
- `failed():boolean`: same with `Command`, use `GitCurrentBranchCommand.result` to get command line result.
- `output():string?`: get the command output.

### [fzfx.lib.constants](/lua/fzfx/lib/constants.lua)

#### OS

##### `IS_WINDOWS`

Whether is Windows.

##### `IS_MACOS`

Whether is macOS.

##### `IS_BSD`

Whether is BSD.

##### `IS_LINUX`

Whether is UNIX or Linux.

#### Executables

##### `HAS_BAT`

Whether has `bat` command.

##### `BAT`

`bat` or `batcat` command.

##### `HAS_CAT`

Whether has `cat` command.

##### `CAT`

`cat` command.

##### `HAS_RG`

Whether has `rg` command.

##### `RG`

`rg` command.

##### `HAS_GNU_GREP`

Whether has gnu `grep`/`ggrep` command.

##### `GNU_GREP`

`grep`/`ggrep` command.

Whether `HAS_GREP`

Whether has `grep`/`ggrep` command.

##### `GREP`

`grep`/`ggrep` command.

##### `HAS_FD`

Whether has `fd` command.

##### `FD`

`fd` or `fdfind` command.

##### `HAS_FIND`

Whether has `find`/`gfind` command.

##### `FIND`

`find` or `gfind` command.

##### `HAS_LS`

Whether has `ls` command.

##### `LS`

`ls` command.

##### `HAS_LSD`

Whether has `lsd` command.

##### `LSD`

`lsd` command.

##### `HAS_EZA`

Whether has `eza`/`exa` command.

##### `EZA`

`eza`/`exa` command.

##### `HAS_GIT`

Whether has `git` command.

##### `GIT`

`git` command.

##### `HAS_DELTA`

Whether has `delta` command.

##### `DELTA`

`delta` command.

##### `HAS_ECHO`

Whether has `echo` command.

##### `ECHO`

`echo` command.

##### `HAS_CURL`

Whether has `curl` command.

##### `CURL`

`curl` command.

### [fzfx.lib.deprecations](/lua/fzfx/lib/deprecations.lua)

#### [`notify`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/deprecations.lua?plain=1#L7)

Print deprecation notifications.

### [fzfx.lib.env](/lua/fzfx/lib/env.lua)

- `debug_enabled():boolean`: detect whether environment variable `_FZFX_NVIM_DEBUG_ENABLE=1`.
- `icon_enabled():boolean`: detect whether environment variable `_FZFX_NVIM_DEVICONS_PATH=1`.

### [fzfx.lib.log](/lua/fzfx/lib/log.lua)

> This module requires initialize before using its APIs, except the [echo](#echo) API.

#### [`LogLevels`/`LogLevelNames`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/log.lua?plain=1#L5-L7)

The logging level integer values and names.

#### [`echo`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/log.lua?plain=1#L21)

Echo message in log `level`. this API doesn't require initialize `fzfx.lib.log` (e.g. `setup`).

#### [`debug`/`info`/`warn`/`err`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/log.lua?plain=1#L70-L134)

Log debug, the message format placeholder `fmt` support lua string format, e.g. `%d`, `%s` placeholders.

#### [`throw`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/log.lua?plain=1#L139)

Same with `err`, additionally it throws an error to user via lua `error()`.

#### [`ensure`](https://github.com/linrongbin16/fzfx.nvim/blob/b9e31389cfc9ba816efa6603b96eabc5a2320ce1/lua/fzfx/lib/log.lua?plain=1#L158)

Write error logs and throw error to user only if `condition` is false.

### [fzfx.lib.bufs](https://github.com/linrongbin16/fzfx.nvim/lua/fzfx/lib/bufs.lua)

#### [`buf_is_valid`](https://github.com/linrongbin16/fzfx.nvim/blob/3ad43c8657d4dc0759a90035dbafa401b2905384/lua/fzfx/lib/bufs.lua?plain=1#L5)

Whether buffer is valid.

### [fzfx.lib.shells](https://github.com/linrongbin16/fzfx.nvim/lua/fzfx/lib/shells.lua)

#### [`shellescape`](https://github.com/linrongbin16/fzfx.nvim/blob/4a0fd372be81a5aa506c32c2cacb78a279b460e5/lua/fzfx/lib/shells.lua?plain=1#L71)

Cross-platform escape shell strings.
