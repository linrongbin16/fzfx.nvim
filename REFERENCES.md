<!-- markdownlint-disable MD013 MD034 MD033 MD038 MD051 -->

# References

## Table of contents

- [fzfx.lib](#fzfxlib)
  - [fzfx.lib.colors](#fzfxlibcolors)
  - [fzfx.lib.commands](#fzfxlibcommands)
  - [fzfx.lib.constants](#fzfxlibconstants)
  - [fzfx.lib.env](#fzfxlibenv)
  - [fzfx.lib.files](#fzfxlibfiles)
  - [fzfx.lib.jsons](#fzfxlibjsons)
  - [fzfx.lib.numbers](#fzfxlibnumbers)
  - [fzfx.lib.nvims](#fzfxlibnvims)
  - [fzfx.lib.paths](#fzfxlibpaths)
  - [fzfx.lib.spawn](#fzfxlibspawn)
  - [fzfx.lib.strings](#fzfxlibstrings)
  - [fzfx.lib.tables](#fzfxlibtables)

## [fzfx.lib](/lua/fzfx/lib)

### [fzfx.lib.colors](/lua/fzfx/lib/colors.lua)

- `csi(code:string, fg:boolean):string`: convert ansi color codes (38, 42) or rgb/css color codes (`#FF3810`) into terminal escaped sequences (`\x1b[38m`, `\x1b[0m`). set `fg=true` for foreground, set `fg=false` for background.
  - for ansi color codes, please see: https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797#color-codes
  - for rgb/css color codes, please see: https://www.w3schools.com/tags/ref_colornames.asp
- `hlcode(attr:"fg"|"bg", hl:string):string?`: retrieve ansi color codes or rgb/css color codes from vim syntax highlighting group (e.g. `Special`, `Constants`, `Number`).
- `ansi(text:string, name:string, hl:string?):string?`: render `text` with specified color name `name` (e.g. `red`, `green`, `magenta`), if use vim syntax highlighting if `hl` is provided.
- `erase(text:string):string`: erase colors from terminal escaped contents.

builtin colors

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

- `render(renderer:fun(text:string, hl:stirng?):string, hl:string?, fmt:string, ...:any):string`: render parameters `...` with `renderer` and optional `hl`, and format with `fmt`.

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

### [fzfx.lib.env](/lua/fzfx/lib/env.lua)

- `debug_enabled():boolean`: detect whether environment variable `_FZFX_NVIM_DEBUG_ENABLE=1`.
- `icon_enabled():boolean`: detect whether environment variable `_FZFX_NVIM_DEVICONS_PATH=1`.

### [fzfx.lib.files](/lua/fzfx/lib/files.lua)

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

### [fzfx.lib.numbers](/lua/fzfx/lib/numbers.lua)

- `INT32_MIN`/`INT32_MAX`: `-2147483648`/`2147483647`.
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

#### List

- `list_empty(l:any):boolean`/`list_not_empty(l:any):boolean`: detect whether a list(table) is empty or not.
- `list_index(i:integer, n:integer):integer`: calculate list index for both positive or negative. `n` is the length of list.
  - if `i > 0`, `i` is in range `[1,n]`.
  - if `i < 0`, `i` is in range `[-1,-n]`, `-1` maps to last position (e.g. `n`), `-n` maps to first position (e.g. `1`).
