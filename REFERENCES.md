<!-- markdownlint-disable MD013 MD034 MD033 -->

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

#### Buffers

- `get_buf_option(bufnr:integer, name:string):any`: get buffer option.
- `set_buf_option(bufnr:integer, name:string, value:any):nil`: set buffer option.
- `buf_is_valid(bufnr:integer):boolean`: check if buffer is valid.

#### Windows

- `get_win_option(winnr:integer, name:string):any`: get window option.
- `set_win_option(winnr:integer, name:string, value:any):nil`: set window option.
- `WindowOptsContext`: window options context.
  - `save():WindowOptsContext`: save current windows & tabs and return context.
  - `restore():nil`: restore previously saved windows & tabs.

### [fzfx.lib.strings](/lua/fzfx/lib/strings.lua)

### [fzfx.lib.tables](/lua/fzfx/lib/tables.lua)

#### Table

- `tbl_empty(t:any):boolean`/`tbl_not_empty(t:any):boolean`: detect whether a table is empty or not.

#### List

- `list_empty(l:any):boolean`/`list_not_empty(l:any):boolean`: detect whether a list(table) is empty or not.
- `list_index(i:integer, n:integer):integer`: calculate list index for both positive or negative. `n` is the length of list.
  - if `i > 0`, `i` is in range `[1,n]`.
  - if `i < 0`, `i` is in range `[-1,-n]`, `-1` maps to last position (e.g. `n`), `-n` maps to first position (e.g. `1`).
