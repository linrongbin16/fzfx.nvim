<!-- markdownlint-disable MD013 MD034 MD033 -->

# References

## Table of contents

- [fzfx.lib](#fzfxlib)
  - [fzfx.lib.constants](#fzfxlibconstants)
  - [fzfx.lib.filesystems](#fzfxlibfilesystems)

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

- `FileLineReader`:
  - `open(filename:string, batchsize:integer?):FileLineReader`: open a file to read, return the reader handle, by default `batchsize=4096`.
  - `has_next():boolean`: detect whether there are more lines to read.
  - `next():string?`: get next line.
  - `close():nil`: close the reader handle.
