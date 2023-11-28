<!-- markdownlint-disable MD013 MD034 MD033 MD038 -->

# References

## Table of contents

- [fzfx.lib](#fzfxlib)
  - [fzfx.lib.constants](#fzfxlibconstants)
  - [fzfx.lib.filesystems](#fzfxlibfilesystems)
  - [fzfx.lib.numbers](#fzfxlibnumbers)
  - [fzfx.lib.nvims](#fzfxlibnvims)
  - [fzfx.lib.strings](#fzfxlibstrings)
  - [fzfx.lib.tables](#fzfxlibtables)

## [fzfx.lib](/lua/fzfx/lib)

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

### [fzfx.lib.filesystems](/lua/fzfx/lib/filesystems.lua)

#### Read File

- `FileLineReader`: file line reader.
  - `open(filename:string, batchsize:integer?):FileLineReader`: open file to read, return the reader handle, by default `batchsize=4096`.
  - `has_next():boolean`: detect whether there are more lines to read.
  - `next():string?`: get next line.
  - `close():nil`: close the reader handle.
- `readlines(filename:string):string[]|nil`: open file and read line by line.
- `readfile(filename:string, opts:{trim:boolean?}?):string?`: open and read all contents from file, set `opts={trim=true}` to trim whitespaces, by default `opts={trim=true}`.
- `asyncreadfile(filename:string, on_complete:fun(data:string?):any, opts:{trim:boolean?}?):nil`: async read file, invoke callback `on_complete` when done.

#### Write File

- `writefile(filename:string, content:string):integer`: write content into file, return `-1` if fail, `0` if success.
- `writelines(filename:string, lines:string[]):integer`: write lines into file, return `-1` if fail, `0` if success.
- `asyncwritefile(filename:string, content:string, on_complete:fun(bytes:integer?):any):integer`: async write content into a file, invoke callback `on_complete` when done.

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

### [fzfx.lib.strings](/lua/fzfx/lib/strings.lua)

- `empty(s:string?):boolean`/`not_empty(s:string?):boolean`: detect whether a string is empty or not.
- `blank(s:string?):boolean`/`not_blank(s:string?):boolean`: detect whether a string is blank or not.
- `find(s:string, t:string, start:integer?):integer?`: find first `t` in `s` start from `start`, by default `start=1`.
- `rfind(s:string, t:string, rstart:integer?):integer?`: reversely find last `t` in `s` start from `rstart`, by default `rstart=#s`.
- `ltrim(s:string, t:string):string`/`rtrim(s:string, t:string):string`: trim left/right `t` from `s`, by default `t` is whitespaces (`\n\t\r `).
- `split(s:string, delimiter:string, opts:{plain:boolean?,trimempty:boolean?}?):string`: split `s` by `delimiter`, set `opts.plain=false` to use lua pattern matching, set `opts.trimempty=false` to not remove whitespaces from results. by default `opts={plain=true, trimempty=true}`.
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
