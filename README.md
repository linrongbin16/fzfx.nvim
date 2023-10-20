<!-- markdownlint-disable MD013 MD034 MD033 -->

# fzfx.nvim

<p align="center">
<a href="https://github.com/neovim/neovim/releases/v0.6.0"><img alt="Neovim-v0.6.0" src="https://img.shields.io/badge/Neovim-v0.6.0-blueviolet.svg?logo=Neovim&logoColor=green" /></a>
<a href="https://github.com/linrongbin16/fzfx.nvim/search?l=lua"><img alt="Top Language" src="https://img.shields.io/github/languages/top/linrongbin16/fzfx.nvim?label=Lua&logo=lua&logoColor=darkblue" /></a>
<a href="https://github.com/linrongbin16/fzfx.nvim/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/linrongbin16/fzfx.nvim?logo=GNU&label=License" /></a>
<a href="https://github.com/linrongbin16/fzfx.nvim/actions/workflows/ci.yml"><img alt="ci.yml" src="https://img.shields.io/github/actions/workflow/status/linrongbin16/fzfx.nvim/ci.yml?logo=GitHub&label=Luacheck" /></a>
<a href="https://app.codecov.io/github/linrongbin16/fzfx.nvim"><img alt="codecov" src="https://img.shields.io/codecov/c/github/linrongbin16/fzfx.nvim?logo=codecov&logoColor=magenta&label=Codecov" /></a>
</p>

<p align="center"> E(x)tended commands missing in <a href="https://github.com/junegunn/fzf.vim">fzf.vim</a>. </p>

https://github.com/linrongbin16/fzfx.nvim/assets/6496887/aa5ef18c-26b4-4a93-bd0c-bfeba6f6caf1

> Search `fzfx` with rg's `-g *ch.lua` option.

## Table of contents

- [Feature](#-feature)
- [Requirement](#-requirement)
  - [Windows](#windows)
  - [Path containing whitespace & Escaping issue](#path-containing-whitespace--escaping-issue)
- [Install](#-install)
  - [vim-plug](#vim-plug)
  - [packer.nvim](#packernvim)
  - [lazy.nvim](#lazynvim)
- [Commands](#-commands)
  - [Files](#files)
  - [Live Grep](#live-grep)
  - [Buffers](#buffers)
  - [Git Files](#git-files)
  - [Git Branches](#git-branches)
  - [Git Commits](#git-commits)
  - [Git Blame](#git-blame)
  - [(Vim) Commands](#vim-commands)
  - [Lsp Diagnostics](#lsp-diagnostics)
  - [Lsp Symbols](#lsp-symbols)
  - [File Explorer](#file-explorer)
- [Recommended Key Mappings](#-recommended-key-mappings)
  - [Vimscript](#vimscript)
  - [Lua](#lua)
- [Configuration](#-configuration)
  - [Create your own commands](#create-your-own-commands)
- [Credit](#-credit)
- [Development](#-development)
- [Contribute](#-contribute)

## ✨ Feature

- Icons & colors.
- Windows support.
- Lua support: preview lua function defined commands and key mappings (todo).
- Fully dynamic parsing user query and selection, a typical use case is passing raw rg options via `--` flag (see [Demo](https://github.com/linrongbin16/fzfx.nvim/wiki/Demo)).
- Multiple variants to avoid manual input:
  - Search by visual select.
  - Search by cursor word.
  - Search by yank text.
- Easily switch on multiple data sources:
  - Whether to filter hidden/ignored files or include them (unrestricted) when searching files.
  - Local branches or remote branches when searching git branches.
  - All diagnostics in workspace or only in current buffer when searching diagnostics.
  - ...
- Maximized configuration.
- ...

> All above features are built on a fully dynamic engine, which allows you to do almost anything you want, please see [Configuration](#-configuration) and [Wiki](https://github.com/linrongbin16/fzfx.nvim/wiki).
>
> Please see [Demo](https://github.com/linrongbin16/fzfx.nvim/wiki/Demo) for more features & use cases.

## ✅ Requirement

- Neovim &ge; v0.6.0.
- [Nerd fonts](https://www.nerdfonts.com/) (optional for icons).
- [rg](https://github.com/BurntSushi/ripgrep) (optional for **live grep**, by default use [grep](https://man7.org/linux/man-pages/man1/grep.1.html)).
- [fd](https://github.com/sharkdp/fd) (optional for **files**, by default use [find](https://man7.org/linux/man-pages/man1/find.1.html)).
- [bat](https://github.com/sharkdp/bat) (optional for preview files, e.g. the right side of **live grep**, **files**, by default use [cat](https://man7.org/linux/man-pages/man1/cat.1.html)).
- [git](https://git-scm.com/) (optional for **git** commands).
- [eza](https://github.com/eza-community/eza) (optional for **file explorer** commands, by default use [ls](https://man7.org/linux/man-pages/man1/ls.1.html)), [echo](https://man7.org/linux/man-pages/man1/echo.1p.html) (optional for **file explorer** commands, print current directory path).

> Note: `grep`, `find`, `cat`, etc are unix/linux builtin commands, while on Windows we don't have a builtin shell environment, so install rust commands such as `rg`, `fd`, `bat`, etc should be a better choice. Also see [Windows](#windows) for how to install linux commands on Windows.

### Windows

<details>
<summary><b>Click here to see how to install linux commands on Windows</b></summary>
<br/>

There're many ways to install portable linux shell and builtin commands on Windows, but personally I would recommend below two methods.

#### [Git for Windows](https://git-scm.com/download/win)

Install with the below 3 options:

- In **Select Components**, select **Associate .sh files to be run with Bash**.

  <img alt="install-windows-git1.png" src="https://raw.githubusercontent.com/linrongbin16/lin.nvim.dev/main/assets/installations/install-windows-git1.png" width="70%" />

- In **Adjusting your PATH environment**, select **Use Git and optional Unix tools from the Command Prompt**.

  <img alt="install-windows-git2.png" src="https://raw.githubusercontent.com/linrongbin16/lin.nvim.dev/main/assets/installations/install-windows-git2.png" width="70%" />

- In **Configuring the terminal emulator to use with Git Bash**, select **Use Windows's default console window**.

  <img alt="install-windows-git3.png" src="https://raw.githubusercontent.com/linrongbin16/lin.nvim.dev/main/assets/installations/install-windows-git3.png" width="70%" />

After this step, **git.exe** and builtin linux commands(such as **sh.exe**, **grep.exe**, **find.exe**, **sleep.exe**, **cd.exe**, **ls.exe**) will be available in `%PATH%`.

#### [scoop](https://scoop.sh/)

Run below powershell commands:

```powershell
# scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

scoop bucket add extras
scoop install git
scoop install mingw
scoop install coreutils
scoop install sleep
scoop install grep
scoop install findutils
```

#### Fix conflicts between embeded commands in `C:\Windows\System32` and portable linux commands

Windows actually already provide some commands (`find.exe`, `bash.exe`) in `C:\Windows\System32` (or `%SystemRoot%\system32`), which could override our installations. To fix this issue, we could prioritize the git or scoop environment variables in `%PATH%`.

<img alt="windows-path" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/5296429b-daae-40f6-be16-6c065ef7bf05" width="70%" />

</details>

### Path containing whitespace & Escaping issue

<details>
<summary><b>Click here to see how whitespace affect escaping characters on path</b></summary>
<br/>

This plugin internally extends `nvim`, `fzf` and lua scripts to full path when launching command.

But when there're whitespaces on the path, launching correct shell command becomes quite difficult, since it will seriously affected escaping characters. Here're two typical cases:

1. `C:\Program Files\Neovim\bin\nvim.exe` - `nvim.exe` installed in `C:\Program Files` directory.

   Please add executables (`nvim.exe`, `fzf.exe`) to `%PATH%` (`$env:PATH` in PowerShell), and set the `env` configuration:

   ```lua
   require("fzfx").setup({
       env = {
           nvim = 'nvim',
           fzf = 'fzf',
       }
   })
   ```

   This will help fzfx.nvim avoid the shell command issue.

2. `C:\Users\Lin Rongbin\opt\Neovim\bin\nvim.exe` or `/Users/linrongbin/Library/Application\ Support/Neovim/bin/nvim` - `Lin Rongbin` (user name) or `Application Support` (macOS application) contains whitespace.

   We still cannot handle the 2nd case for now, please always try to avoid whitespaces in path.

   Here's an example of searching files command (macOS):

   - `/opt/homebrew/bin/nvim -n --clean --headless -l /Users/linrongbin/.local/share/nvim/lazy/fzfx.nvim/bin/files/provider.lua  /tmp/nvim.linrongbin/3NXwys/0`

   Here's an example of launching fzf command (Windows 10):

   - `C:/Users/linrongbin/github/junegunn/fzf/bin/fzf --query "" --header ":: Press \27[38;2;255;121;198mCTRL-U\27[0m to unrestricted mode" --prompt "~/g/l/fzfx.nvim > " --bind "start:unbind(ctrl-r)" --bind "ctrl-u:unbind(ctrl-u)+execute-silent(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\rpc\\client.lua 1)+change-header(:: Press \27[38;2;255;121;198mCTRL-R\27[0m to restricted mode)+rebind(ctrl-r)+reload(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\files\\provider.lua C:\\Users\\linrongbin\\AppData\\Local\\nvim-data\\fzfx.nvim\\switch_files_provider)" --bind "ctrl-r:unbind(ctrl-r)+execute-silent(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\rpc\\client.lua 1)+change-header(:: Press \27[38;2;255;121;198mCTRL-U\27[0m to unrestricted mode)+rebind(ctrl-u)+reload(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\files\\provider.lua C:\\Users\\linrongbin\\AppData\\Local\\nvim-data\\fzfx.nvim\\switch_files_provider)" --preview "C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\files\\previewer.lua {}" --bind "ctrl-l:toggle-preview" --expect "enter" --expect "double-click" >C:\\Users\\LINRON~1\\AppData\\Local\\Temp\\nvim.0\\JSmP06\\2`

   If the path contains whitespace, that will make all lua scripts contains whitespace, thus the shell command cannot being correctly evaluated.

</details>

## 📦 Install

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
call plug#begin()

" optional for icons
Plug 'nvim-tree/nvim-web-devicons'

" mandatory
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'linrongbin16/fzfx.nvim'

call plug#end()

lua require('fzfx').setup()
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
return require('packer').startup(function(use)
    -- optional for icons
    use { "nvim-tree/nvim-web-devicons" }

    -- mandatory
    use { "junegunn/fzf", run = ":call fzf#install()" }
    use {
        "linrongbin16/fzfx.nvim",
        config = function()
            require("fzfx").setup()
        end
    }
end)
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
require("lazy").setup({
    -- optional for icons
    { "nvim-tree/nvim-web-devicons" },

    -- mandatory
    { "junegunn/fzf", build = ":call fzf#install()" },
    {
        "linrongbin16/fzfx.nvim",
        dependencies = { "junegunn/fzf", "nvim-tree/nvim-web-devicons" },
        config = function()
            require("fzfx").setup()
        end
    },

})
```

## 🚀 Commands

### Naming Rules

Commands are named following below rules:

- All commands are named with prefix `Fzfx`.
- The main command name has no suffix.
- The unrestricted variant is named with `U` suffix.
- The visual select variant is named with `V` suffix.
- The cursor word variant is named with `W` suffix.
- The yank text variant is named with `P` suffix (just like press the `p` key).
- The only current buffer variant is named with `B` suffix.

> Note: command names can be configured, see [Configuration](#-configuration).

### Bind Keys

- Exit keys (fzf `--expect` option)
  - `esc`: quit.
  - `double-click`/`enter`: open/jump to file (behave different on some specific commands).
- Preview keys
  - `alt-p`: toggle preview.
  - `ctrl-f`: preview half page down.
  - `ctrl-b`: preview half page up.
- Multi keys
  - `ctrl-e`: toggle select.
  - `ctrl-a`: toggle select all.

> Note: builtin keys can be configured, see [Configuration](#-configuration).

### Files

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxFiles(U)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `ctrl-q` to send selected lines to quickfix window and quit.</td>
  </tr>
  <tr>
    <td>FzfxFiles(U)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxFiles(U)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxFiles(U)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Live Grep

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxLiveGrep(U)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `ctrl-q` to send selected lines to quickfix window and quit.<br></td>
  </tr>
  <tr>
    <td>FzfxLiveGrep(U)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxLiveGrep(U)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxLiveGrep(U)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

- Use `--` to pass raw options to search command (grep/rg).

### Buffers

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxBuffers</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `ctrl-q` to send selected lines to quickfix window and quit.</td>
  </tr>
  <tr>
    <td>FzfxBuffersV</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxBuffersW</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxBuffersP</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Git Files

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxGFiles(C)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `ctrl-q` to send selected lines to quickfix window and quit.</td>
  </tr>
  <tr>
    <td>FzfxGFiles(C)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxGFiles(C)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxGFiles(C)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

- Git files in current directory variant is named with `C` suffix.

### Git Branches

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxGBranches(R)</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `enter` to checkout branch.</td>
  </tr>
  <tr>
    <td>FzfxGBranches(R)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxGBranches(R)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxGBranches(R)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

- Remote git branch variant is named with `R` suffix.

### Git Commits

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxGCommits(B)</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `enter` to copy git commit SHA.</td>
  </tr>
  <tr>
    <td>FzfxGCommits(B)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxGCommits(B)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxGCommits(B)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Git Blame

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxGBlame</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `enter` to copy commit SHA.</td>
  </tr>
  <tr>
    <td>FzfxGBlameV</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxGBlameW</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxGBlameP</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### (Vim) Commands

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxCommands(E/U)</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `enter` to input vim command.</td>
  </tr>
  <tr>
    <td>FzfxCommands(E/U)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxCommands(E/U)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxCommands(E/U)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

- Vim ex(builtin) commands variant is named with 'E' suffix.
- Vim user commands variant is named with 'U' suffix.

### Lsp Diagnostics

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxLspDiagnostics(B)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `ctrl-q` to send selected lines to quickfix window and quit.</td>
  </tr>
  <tr>
    <td>FzfxLspDiagnostics(B)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxLspDiagnostics(B)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxLspDiagnostics(B)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Lsp Symbols

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxLspDefinitions</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4"></td>
  </tr>
  <tr>
    <td>FzfxLspTypeDefinitions</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxLspReferences</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxLspImplementations</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### File Explorer

<table style="width: 100%">
<thead>
  <tr>
    <th style="width: 25%">Command</th>
    <th style="width: 8%">Mode</th>
    <th style="width: 8%">Multi Keys</th>
    <th style="width: 8%">Preview Keys</th>
    <th style="width: 51%">Exit Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxFileExplorer(U)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4"></td>
  </tr>
  <tr>
    <td>FzfxFileExplorer(U)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxFileExplorer(U)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxFileExplorer(U)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

## 📌 Recommended Key Mappings

### Vimscript

<details>
<summary><b>Click here to see vimscripts</b></summary>
<br/>

```vim

" ======== files ========

" find files
nnoremap <space>f :\<C-U>FzfxFiles<CR>
" by visual select
xnoremap <space>f :\<C-U>FzfxFilesV<CR>
" by cursor word
nnoremap <space>wf :\<C-U>FzfxFilesW<CR>
" by yank text
nnoremap <space>pf :\<C-U>FzfxFilesP<CR>

" ======== live grep ========

" live grep
nnoremap <space>l :\<C-U>FzfxLiveGrep<CR>
" by visual select
xnoremap <space>l :\<C-U>FzfxLiveGrepV<CR>
" by cursor word
nnoremap <space>wl :\<C-U>FzfxLiveGrepW<CR>
" by yank text
nnoremap <space>pl :\<C-U>FzfxLiveGrepP<CR>

" ======== buffers ========

" buffers
nnoremap <space>bf :\<C-U>FzfxBuffers<CR>
" by visual select
xnoremap <space>bf :\<C-U>FzfxBuffersV<CR>
" by cursor word
nnoremap <space>wbf :\<C-U>FzfxBuffersW<CR>
" by yank text
nnoremap <space>pbf :\<C-U>FzfxBuffersP<CR>

" ======== git files ========

" git files
nnoremap <space>gf :\<C-U>FzfxGFiles<CR>
" by visual select
xnoremap <space>gf :\<C-U>FzfxGFilesV<CR>
" by cursor word
nnoremap <space>wgf :\<C-U>FzfxGFilesW<CR>
" by yank text
nnoremap <space>pgf :\<C-U>FzfxGFilesP<CR>

" ======== git branches ========

" git branches
nnoremap <space>br :\<C-U>FzfxGBranches<CR>
" by visual select
xnoremap <space>br :\<C-U>FzfxGBranchesV<CR>
" by cursor word
nnoremap <space>wbr :\<C-U>FzfxGBranchesW<CR>
" by yank text
nnoremap <space>pbr :\<C-U>FzfxGBranchesP<CR>

" ======== git commits ========

" git commits
nnoremap <space>gc :\<C-U>FzfxGCommits<CR>
" by visual select
xnoremap <space>gc :\<C-U>FzfxGCommitsV<CR>
" by cursor word
nnoremap <space>wgc :\<C-U>FzfxGCommitsW<CR>
" by yank text
nnoremap <space>pgc :\<C-U>FzfxGCommitsP<CR>

" ======== git blame ========

" git blame
nnoremap <space>gb :\<C-U>FzfxGBlame<CR>
" by visual select
xnoremap <space>gb :\<C-U>FzfxGBlameV<CR>
" by cursor word
nnoremap <space>wgb :\<C-U>FzfxGBlameW<CR>
" by yank text
nnoremap <space>pgb :\<C-U>FzfxGBlameP<CR>

" ======== vim commands ========

" vim commands
nnoremap <space>cm :\<C-U>FzfxCommands<CR>

" ======== lsp diagnostics ========

" lsp diagnostics
nnoremap <space>dg :\<C-U>FzfxLspDiagnostics<CR>
" by visual select
xnoremap <space>dg :\<C-U>FzfxLspDiagnosticsV<CR>
" by cursor word
nnoremap <space>wdg :\<C-U>FzfxLspDiagnosticsW<CR>
" by yank text
nnoremap <space>pdg :\<C-U>FzfxLspDiagnosticsP<CR>

" ======== lsp symbols ========

" lsp definitions
nnoremap gd :\<C-U>FzfxLspDefinitions<CR>

" lsp type definitions
nnoremap gt :\<C-U>FzfxLspTypeDefinitions<CR>

" lsp references
nnoremap gr :\<C-U>FzfxLspReferences<CR>

" lsp implementations
nnoremap gi :\<C-U>FzfxLspImplementations<CR>

" ======== file explorer ========

" file explorer
nnoremap <space>xp :\<C-U>FzfxFileExplorer<CR>
```

</details>

### Lua

<details>
<summary><b>Click here to see lua scripts</b></summary>
<br/>

```lua

-- ======== files ========

-- find files
vim.keymap.set('n', '<space>f', '<cmd>FzfxFiles<cr>',
        {silent=true, noremap=true, desc="Find files"})
-- by visual select
vim.keymap.set('x', '<space>f', '<cmd>FzfxFilesV<CR>',
        {silent=true, noremap=true, desc="Find files"})
-- by cursor word
vim.keymap.set('n', '<space>wf', '<cmd>FzfxFilesW<cr>',
        {silent=true, noremap=true, desc="Find files by cursor word"})
-- by yank text
vim.keymap.set('n', '<space>pf', '<cmd>FzfxFilesP<cr>',
        {silent=true, noremap=true, desc="Find files by yank text"})

-- ======== live grep ========

-- live grep
vim.keymap.set('n', '<space>l',
        '<cmd>FzfxLiveGrep<cr>',
        {silent=true, noremap=true, desc="Live grep"})
-- by visual select
vim.keymap.set('x', '<space>l',
        "<cmd>FzfxLiveGrepV<cr>",
        {silent=true, noremap=true, desc="Live grep"})
-- by cursor word
vim.keymap.set('n', '<space>wl',
        '<cmd>FzfxLiveGrepW<cr>',
        {silent=true, noremap=true, desc="Live grep by cursor word"})
-- by yank text
vim.keymap.set('n', '<space>pl',
        '<cmd>FzfxLiveGrepP<cr>',
        {silent=true, noremap=true, desc="Live grep by cursor word"})

-- ======== buffers ========

-- buffers
vim.keymap.set('n', '<space>bf',
        '<cmd>FzfxBuffers<cr>',
        {silent=true, noremap=true, desc="Find buffers"})
-- by visual select
vim.keymap.set('x', '<space>bf',
        "<cmd>FzfxBuffersV<cr>",
        {silent=true, noremap=true, desc="Find buffers"})
-- by cursor word
vim.keymap.set('n', '<space>wbf',
        '<cmd>FzfxBuffersW<cr>',
        {silent=true, noremap=true, desc="Find buffers by cursor word"})
-- by yank text
vim.keymap.set('n', '<space>pbf',
        '<cmd>FzfxBuffersP<cr>',
        {silent=true, noremap=true, desc="Find buffers by yank text"})

-- ======== git files ========

-- git files
vim.keymap.set('n', '<space>gf',
        '<cmd>FzfxGFiles<cr>',
        {silent=true, noremap=true, desc="Find git files"})
-- by visual select
vim.keymap.set('x', '<space>gf',
        "<cmd>FzfxGFilesV<cr>",
        {silent=true, noremap=true, desc="Find git files"})
-- by cursor word
vim.keymap.set('n', '<space>wgf',
        '<cmd>FzfxGFilesW<cr>',
        {silent=true, noremap=true, desc="Find git files by cursor word"})
-- by yank text
vim.keymap.set('n', '<space>pgf',
        '<cmd>FzfxGFilesP<cr>',
        {silent=true, noremap=true, desc="Find git files by yank text"})

-- ======== git branches ========

-- git branches
vim.keymap.set('n', '<space>br', '<cmd>FzfxGBranches<cr>',
        {silent=true, noremap=true, desc="Search git branches"})
-- by visual select
vim.keymap.set('x', '<space>br', '<cmd>FzfxGBranchesV<CR>',
        {silent=true, noremap=true, desc="Search git branches"})
-- by cursor word
vim.keymap.set('n', '<space>wbr', '<cmd>FzfxGBranchesW<cr>',
        {silent=true, noremap=true, desc="Search git branches by cursor word"})
-- by yank text
vim.keymap.set('n', '<space>pbr', '<cmd>FzfxGBranchesP<cr>',
        {silent=true, noremap=true, desc="Search git branches by yank text"})

-- ======== git commits ========

-- git commits
vim.keymap.set('n', '<space>gc', '<cmd>FzfxGCommits<cr>',
        {silent=true, noremap=true, desc="Search git commits"})
-- by visual select
vim.keymap.set('x', '<space>gc', '<cmd>FzfxGCommitsV<CR>',
        {silent=true, noremap=true, desc="Search git commits"})
-- by cursor word
vim.keymap.set('n', '<space>wgc', '<cmd>FzfxGCommitsW<cr>',
        {silent=true, noremap=true, desc="Search git commits by cursor word"})
-- by yank text
vim.keymap.set('n', '<space>pgc', '<cmd>FzfxGCommitsP<cr>',
        {silent=true, noremap=true, desc="Search git commits by yank text"})

-- ======== git blame ========

-- git blame
vim.keymap.set('n', '<space>gb',
        '<cmd>FzfxGBlame<cr>',
        {silent=true, noremap=true, desc="Search git blame"})
-- by visual select
vim.keymap.set('x', '<space>gb',
        "<cmd>FzfxGBlameV<cr>",
        {silent=true, noremap=true, desc="Search git blame"})
-- by cursor word
vim.keymap.set('n', '<space>wgb',
        '<cmd>FzfxGBlameW<cr>',
        {silent=true, noremap=true, desc="Search git blame by cursor word"})
-- by yank text
vim.keymap.set('n', '<space>pgb',
        '<cmd>FzfxGBlameP<cr>',
        {silent=true, noremap=true, desc="Search git blame by yank text"})

-- ======== vim commands ========

-- vim commands
vim.keymap.set('n', '<space>cm', '<cmd>FzfxCommands<cr>',
        {silent=true, noremap=true, desc="Search vim commands"})

-- ======== lsp diagnostics ========

-- lsp diagnostics
vim.keymap.set('n', '<space>dg', '<cmd>FzfxLspDiagnostics<cr>',
        {silent=true, noremap=true, desc="Search lsp diagnostics"})
-- by visual select
vim.keymap.set('x', '<space>dg', '<cmd>FzfxLspDiagnosticsV<CR>',
        {silent=true, noremap=true, desc="Search lsp diagnostics"})
-- by cursor word
vim.keymap.set('n', '<space>wdg', '<cmd>FzfxLspDiagnosticsW<cr>',
        {silent=true, noremap=true, desc="Search lsp diagnostics by cursor word"})
-- by yank text
vim.keymap.set('n', '<space>pdg', '<cmd>FzfxLspDiagnosticsP<cr>',
        {silent=true, noremap=true, desc="Search lsp diagnostics by yank text"})

-- ======== lsp symbols ========

-- lsp definitions
vim.keymap.set('n', 'gd', '<cmd>FzfxLspDefinitions<cr>',
        {silent=true, noremap=true, desc="Goto lsp definitions"})

-- lsp type definitions
vim.keymap.set('n', 'gt', '<cmd>FzfxLspTypeDefinitions<cr>',
        {silent=true, noremap=true, desc="Goto lsp type definitions"})

-- lsp references
vim.keymap.set('n', 'gr', '<cmd>FzfxLspReferences<cr>',
        {silent=true, noremap=true, desc="Goto lsp references"})

-- lsp implementations
vim.keymap.set('n', 'gi', '<cmd>FzfxLspImplementations<cr>',
        {silent=true, noremap=true, desc="Goto lsp implementations"})

-- ======== file explorer ========

-- file explorer
vim.keymap.set('n', '<space>xp', '<cmd>FzfxFileExplorer<cr>',
        {silent=true, noremap=true, desc="File explorer"})
```

</details>

## 🔧 Configuration

To configure options, please use:

```lua
require('fzfx').setup(option)
```

The `option` is an optional lua table that override the default options.

For complete options and defaults, please check [config.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/config.lua).

For advanced configurations, please check [Advanced Configuration](https://github.com/linrongbin16/fzfx.nvim/wiki/Advanced-Configuration).

If you have encounter some breaks on configuration, please see [CHANGELOG](https://github.com/linrongbin16/fzfx.nvim/blob/main/CHANGELOG.md).

### Create your own commands

To create your own commands, please see [A General Schema for Creating FZF Command](https://github.com/linrongbin16/fzfx.nvim/wiki/A-General-Schema-for-Creating-FZF-Command) and [schema.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/schema.lua).

## 🍀 Credit

- [fzf.vim](https://github.com/junegunn/fzf.vim): Things you can do with [fzf](https://github.com/junegunn/fzf) and Vim.
- [fzf-lua](https://github.com/ibhagwan/fzf-lua): Improved fzf.vim written in lua.

## ✏️ Development

To develop the project and make PR, please setup with:

- [lua_ls](https://github.com/LuaLS/lua-language-server).
- [stylua](https://github.com/JohnnyMorganz/StyLua).
- [luarocks](https://luarocks.org/).
- [luacheck](https://github.com/mpeterv/luacheck).

To run unit tests, please install below dependencies:

- [vusted](https://github.com/notomo/vusted).

Then test with `vusted ./test`.

## 🎁 Contribute

Please open [issue](https://github.com/linrongbin16/fzfx.nvim/issues)/[PR](https://github.com/linrongbin16/fzfx.nvim/pulls) for anything about fzfx.nvim.

Like fzfx.nvim? Consider

[![Github Sponsor](https://img.shields.io/badge/-Sponsor%20Me%20on%20Github-magenta?logo=github&logoColor=white)](https://github.com/sponsors/linrongbin16)
[![Wechat Pay](https://img.shields.io/badge/-Tip%20Me%20on%20WeChat-brightgreen?logo=wechat&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
[![Alipay](https://img.shields.io/badge/-Tip%20Me%20on%20Alipay-blue?logo=alipay&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
