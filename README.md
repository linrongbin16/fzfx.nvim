<!-- markdownlint-disable MD013 MD034 MD033 -->

# fzfx.nvim

<p align="center">
<a href="https://github.com/neovim/neovim/releases/v0.7.0"><img alt="Neovim-v0.7.0" src="https://img.shields.io/badge/Neovim-v0.7.0-blueviolet.svg?logo=Neovim&logoColor=green" /></a>
<a href="https://github.com/linrongbin16/fzfx.nvim/search?l=lua"><img alt="Top Language" src="https://img.shields.io/github/languages/top/linrongbin16/fzfx.nvim?label=Lua&logo=lua&logoColor=darkblue" /></a>
<a href="https://github.com/linrongbin16/fzfx.nvim/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/linrongbin16/fzfx.nvim?logo=GNU&label=License" /></a>
<a href="https://github.com/linrongbin16/fzfx.nvim/actions/workflows/ci.yml"><img alt="ci.yml" src="https://img.shields.io/github/actions/workflow/status/linrongbin16/fzfx.nvim/ci.yml?logo=GitHub&label=Luacheck" /></a>
<a href="https://app.codecov.io/github/linrongbin16/fzfx.nvim"><img alt="codecov" src="https://img.shields.io/codecov/c/github/linrongbin16/fzfx.nvim?logo=codecov&logoColor=magenta&label=Codecov" /></a>
</p>

<p align="center"> E(x)tended commands missing in <a href="https://github.com/junegunn/fzf.vim">fzf.vim</a>. </p>

https://github.com/linrongbin16/fzfx.nvim/assets/6496887/47b03150-14e3-479a-b1af-1b2995659403

> Search `fzfx` with rg's `-g *spec.lua` option.

## Table of contents

- [Feature](#-feature)
- [Requirement](#-requirement)
  - [Windows](#windows)
  - [Whitespace escaping issue](#whitespace-escaping-issue)
- [Install](#-install)
  - [vim-plug](#vim-plug)
  - [packer.nvim](#packernvim)
  - [lazy.nvim](#lazynvim)
- [Commands](#-commands)
  - [Files & Buffers](#files--buffers)
  - [Grep](#grep)
  - [Git](#git)
  - [Lsp & Diagnostics](#lsp--diagnostics)
  - [Vim](#vim)
  - [Misc](#misc)
- [Recommended Key Mappings](#-recommended-key-mappings)
  - [Vimscript](#vimscript)
  - [Lua](#lua)
- [Configuration](#-configuration)
  - [Defaults](#defaults)
  - [Commands Group](#commands-group)
  - [The `ls -1` Example](#the-ls--1-example)
- [Credit](#-credit)
- [Development](#-development)
- [Contribute](#-contribute)

## ✨ Feature

- Icons & colors.
- Windows support.
- Lua support: preview lua function defined commands and key mappings.
- Fully dynamic parsing user query and selection, a typical use case is passing raw rg options via `--` flag (see [Demo](https://github.com/linrongbin16/fzfx.nvim/wiki/Demo)).
- Multiple variants to avoid manual input:
  - Search by visual select.
  - Search by cursor word.
  - Search by yank text.
  - Search by previous search, e.g. resume last search.
- Easily switch on multiple data sources:
  - Whether to filter hidden/ignored files or include them (unrestricted) when searching files.
  - Local branches or remote branches when searching git branches.
  - All diagnostics in workspace or only in current buffer when searching diagnostics.
  - ...
- Maximized configuration.
- ...

> Please see [Demo](https://github.com/linrongbin16/fzfx.nvim/wiki/Demo) for more features & use cases.

## ✅ Requirement

- Neovim &ge; v0.7.0.
- [Nerd fonts](https://www.nerdfonts.com/) (optional for icons).
- [rg](https://github.com/BurntSushi/ripgrep) (optional for **live grep**, by default use [grep](https://man7.org/linux/man-pages/man1/grep.1.html)).
- [fd](https://github.com/sharkdp/fd) (optional for **files**, by default use [find](https://man7.org/linux/man-pages/man1/find.1.html)).
- [bat](https://github.com/sharkdp/bat) (optional for preview files, by default use [cat](https://man7.org/linux/man-pages/man1/cat.1.html)), [curl](https://man7.org/linux/man-pages/man1/curl.1.html) (optional for preview window labels).
- [echo](https://man7.org/linux/man-pages/man1/echo.1p.html) (mandatory for vim **commands**, **keymaps** commands).
- [git](https://git-scm.com/) (mandatory for **git** commands), [delta](https://github.com/dandavison/delta) (optional for preview git **diff, show, blame**).
- [lsd](https://github.com/lsd-rs/lsd)/[eza](https://github.com/eza-community/eza) (optional for **file explorer** commands, by default use [ls](https://man7.org/linux/man-pages/man1/ls.1.html)).

> Note: `grep`, `find`, `cat` are unix/linux builtin commands, while on Windows we don't have a builtin shell environment, so install rust commands such as `rg`, `fd`, `bat` should be better choice. While still recommend Windows users [install linux shell commands](#windows) since utils like `echo`, `curl` are internally used by somewhere.

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

After this step, **git.exe** and builtin linux commands(such as **echo.exe**, **grep.exe**, **find.exe**, **curl.exe**) will be available in `%PATH%`.

#### [scoop](https://scoop.sh/)

Run below powershell commands:

```powershell
# scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

scoop bucket add extras
scoop install git           # git, bash, sh
scoop install coreutils     # echo, ls, cat
scoop install curl          # curl
scoop install grep          # grep
scoop install findutils     # find
```

#### Fix conflicts between embeded commands in `C:\Windows\System32` and portable linux commands

Windows actually already provide some commands (`find.exe`, `bash.exe`) in `C:\Windows\System32` (or `%SystemRoot%\system32`), while they are not the linux commands they are named after, but could override our installations. To fix this issue, we could prioritize the git or scoop environment variables in `%PATH%`.

<img alt="windows-path" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/5296429b-daae-40f6-be16-6c065ef7bf05" width="70%" />

</details>

### Whitespace escaping issue

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
return require("packer").startup(function(use)
  -- optional for icons
  use({ "nvim-tree/nvim-web-devicons" })

  -- mandatory
  use({
    "junegunn/fzf",
    run = function()
      vim.fn["fzf#install"]()
    end,
  })
  use({
    "linrongbin16/fzfx.nvim",
    config = function()
      require("fzfx").setup()
    end,
  })
end)
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
require("lazy").setup({

  -- optional for icons
  { "nvim-tree/nvim-web-devicons" },

  -- mandatory
  {
    "junegunn/fzf",
    build = function()
      vim.fn["fzf#install"]()
    end,
  },
  {
    "linrongbin16/fzfx.nvim",
    dependencies = { "junegunn/fzf", "nvim-tree/nvim-web-devicons" },
    config = function()
      require("fzfx").setup()
    end,
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
- The resume variant is named with `R` suffix.
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
- Select keys
  - `ctrl-e`: toggle select.
  - `ctrl-a`: toggle select all.

> Note: builtin keys can be configured, see [Configuration](#-configuration).

### Files & Buffers

- Files

> 1. Use `ctrl-q` to send selected lines to quickfix window and quit.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxFiles(U)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
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

- Buffers

> 1. Use `ctrl-q` to send selected lines to quickfix window and quit.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxBuffers</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
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

### Grep

- Live Grep

> 1. Use `ctrl-q` to send selected lines to quickfix window and quit.
> 2. Use `--` to pass raw options to search command (grep/rg).

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxLiveGrep(B/U)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
  </tr>
  <tr>
    <td>FzfxLiveGrep(B/U)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxLiveGrep(B/U)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxLiveGrep(B/U)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Git

- Git Files

> 1. Use `ctrl-q` to send selected lines to quickfix window and quit.
> 2. Current directory variant is named with `C` suffix.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxGFiles(C)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
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

- Git Status (Changed Files)

> 1. Use `ctrl-q` to send selected lines to quickfix window and quit.
> 2. Current directory variant is named with `C` suffix.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxGStatus(C)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
  </tr>
  <tr>
    <td>FzfxGStatus(C)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxGStatus(C)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxGStatus(C)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

- Git Branches

> 1. Use `enter` to checkout branch.
> 2. Remote branch variant is named with `R` suffix.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxGBranches(R)</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
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

- Git Commits

> 1. Use `enter` to copy git commit SHA.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxGCommits(B)</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
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

- Git Blame

> 1. Use `enter` to copy git commit SHA.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxGBlame</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
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

### Lsp & Diagnostics

- Lsp

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxLspDefinitions</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
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

- Diagnostics

> 1. Use `ctrl-q` to send selected lines to quickfix window and quit.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxLspDiagnostics(B)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
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

### Vim

- Commands

> 1. Use `enter` to input vim command.
> 2. Ex(builtin) commands variant is named with 'E' suffix.
> 3. User commands variant is named with 'U' suffix.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxCommands(E/U)</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
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

- Key Maps

> 1. Use `enter` to execute vim key.
> 2. Normal mode variant is named with `N` suffix.
> 3. Insert mode variant is named with `I` suffix.
> 4. Visual(select) mode variant is named with `V` suffix.

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxKeMaps(N/I/V)</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
  </tr>
  <tr>
    <td>FzfxKeyMaps(N/I/V)V</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxKeyMaps(N/I/V)W</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxKeyMaps(N/I/V)P</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Misc

- File Explorer

<table>
<thead>
  <tr>
    <th>Command</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>FzfxFileExplorer(U)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
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

" ======== git files ========

" git files
nnoremap <space>gf :\<C-U>FzfxGFiles<CR>

" ======== git changed files (status) ========

" git files
nnoremap <space>gs :\<C-U>FzfxGStatus<CR>

" ======== git branches ========

" git branches
nnoremap <space>br :\<C-U>FzfxGBranches<CR>

" ======== git commits ========

" git commits
nnoremap <space>gc :\<C-U>FzfxGCommits<CR>

" ======== git blame ========

" git blame
nnoremap <space>gb :\<C-U>FzfxGBlame<CR>

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

" ======== vim commands ========

" vim commands
nnoremap <space>cm :\<C-U>FzfxCommands<CR>

" ======== vim key maps ========

" vim key maps
nnoremap <space>km :\<C-U>FzfxKeyMaps<CR>

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
vim.keymap.set(
  "n",
  "<space>f",
  "<cmd>FzfxFiles<cr>",
  { silent = true, noremap = true, desc = "Find files" }
)
-- by visual select
vim.keymap.set(
  "x",
  "<space>f",
  "<cmd>FzfxFilesV<CR>",
  { silent = true, noremap = true, desc = "Find files" }
)
-- by cursor word
vim.keymap.set(
  "n",
  "<space>wf",
  "<cmd>FzfxFilesW<cr>",
  { silent = true, noremap = true, desc = "Find files by cursor word" }
)
-- by yank text
vim.keymap.set(
  "n",
  "<space>pf",
  "<cmd>FzfxFilesP<cr>",
  { silent = true, noremap = true, desc = "Find files by yank text" }
)

-- ======== live grep ========

-- live grep
vim.keymap.set(
  "n",
  "<space>l",
  "<cmd>FzfxLiveGrep<cr>",
  { silent = true, noremap = true, desc = "Live grep" }
)
-- by visual select
vim.keymap.set(
  "x",
  "<space>l",
  "<cmd>FzfxLiveGrepV<cr>",
  { silent = true, noremap = true, desc = "Live grep" }
)
-- by cursor word
vim.keymap.set(
  "n",
  "<space>wl",
  "<cmd>FzfxLiveGrepW<cr>",
  { silent = true, noremap = true, desc = "Live grep by cursor word" }
)
-- by yank text
vim.keymap.set(
  "n",
  "<space>pl",
  "<cmd>FzfxLiveGrepP<cr>",
  { silent = true, noremap = true, desc = "Live grep by cursor word" }
)

-- ======== buffers ========

-- buffers
vim.keymap.set(
  "n",
  "<space>bf",
  "<cmd>FzfxBuffers<cr>",
  { silent = true, noremap = true, desc = "Find buffers" }
)

-- ======== git files ========

-- git files
vim.keymap.set(
  "n",
  "<space>gf",
  "<cmd>FzfxGFiles<cr>",
  { silent = true, noremap = true, desc = "Find git files" }
)

-- ======== git changed files (status) ========

-- git status
vim.keymap.set(
  "n",
  "<space>gs",
  "<cmd>FzfxGStatus<cr>",
  { silent = true, noremap = true, desc = "Find git changed files (status)" }
)

-- ======== git branches ========

-- git branches
vim.keymap.set(
  "n",
  "<space>br",
  "<cmd>FzfxGBranches<cr>",
  { silent = true, noremap = true, desc = "Search git branches" }
)

-- ======== git commits ========

-- git commits
vim.keymap.set(
  "n",
  "<space>gc",
  "<cmd>FzfxGCommits<cr>",
  { silent = true, noremap = true, desc = "Search git commits" }
)

-- ======== git blame ========

-- git blame
vim.keymap.set(
  "n",
  "<space>gb",
  "<cmd>FzfxGBlame<cr>",
  { silent = true, noremap = true, desc = "Search git blame" }
)

-- ======== lsp diagnostics ========

-- lsp diagnostics
vim.keymap.set(
  "n",
  "<space>dg",
  "<cmd>FzfxLspDiagnostics<cr>",
  { silent = true, noremap = true, desc = "Search lsp diagnostics" }
)
-- by visual select
vim.keymap.set(
  "x",
  "<space>dg",
  "<cmd>FzfxLspDiagnosticsV<CR>",
  { silent = true, noremap = true, desc = "Search lsp diagnostics" }
)
-- by cursor word
vim.keymap.set("n", "<space>wdg", "<cmd>FzfxLspDiagnosticsW<cr>", {
  silent = true,
  noremap = true,
  desc = "Search lsp diagnostics by cursor word",
})
-- by yank text
vim.keymap.set("n", "<space>pdg", "<cmd>FzfxLspDiagnosticsP<cr>", {
  silent = true,
  noremap = true,
  desc = "Search lsp diagnostics by yank text",
})

-- ======== lsp symbols ========

-- lsp definitions
vim.keymap.set(
  "n",
  "gd",
  "<cmd>FzfxLspDefinitions<cr>",
  { silent = true, noremap = true, desc = "Goto lsp definitions" }
)

-- lsp type definitions
vim.keymap.set(
  "n",
  "gt",
  "<cmd>FzfxLspTypeDefinitions<cr>",
  { silent = true, noremap = true, desc = "Goto lsp type definitions" }
)

-- lsp references
vim.keymap.set(
  "n",
  "gr",
  "<cmd>FzfxLspReferences<cr>",
  { silent = true, noremap = true, desc = "Goto lsp references" }
)

-- lsp implementations
vim.keymap.set(
  "n",
  "gi",
  "<cmd>FzfxLspImplementations<cr>",
  { silent = true, noremap = true, desc = "Goto lsp implementations" }
)

-- ======== vim commands ========

-- vim commands
vim.keymap.set(
  "n",
  "<space>cm",
  "<cmd>FzfxCommands<cr>",
  { silent = true, noremap = true, desc = "Search vim commands" }
)

-- ======== vim key maps ========

-- vim key maps
vim.keymap.set(
  "n",
  "<space>km",
  "<cmd>FzfxKeyMaps<cr>",
  { silent = true, noremap = true, desc = "Search vim keymaps" }
)

-- ======== file explorer ========

-- file explorer
vim.keymap.set(
  "n",
  "<space>xp",
  "<cmd>FzfxFileExplorer<cr>",
  { silent = true, noremap = true, desc = "File explorer" }
)
```

</details>

## 🔧 Configuration

To configure options, please use:

```lua
require('fzfx').setup(option)
```

The `option` is an optional lua table that override the default options.

### Defaults

```lua
local Defaults = {
  --- @type GroupConfig
  files = ...,
  --- @type GroupConfig
  live_grep = ...,
  --- @type GroupConfig
  buffers = ...,
  --- @type GroupConfig
  lsp_diagnostics = ...,
  ... -- the other commands groups, please see [Commands Group](#commands-group).

  yank_history = {
    other_opts = {
      -- max size of saved yank history.
      -- yank history internally is saved in a ring buffer, which can not grow indefinitely
      maxsize = 100,
    },
  },

  -- define your own commands group here,
  -- please check [Create your own command](#create-your-own-command).
  users = nil,

  -- fzf options for all commands.
  -- each commands group also has a 'fzf_opts' field that can overwrite this.
  fzf_opts = {
    "--ansi",
    "--info=inline",
    "--layout=reverse",
    "--border=rounded",
    "--height=100%",
    "--bind=ctrl-e:toggle",
    "--bind=ctrl-a:toggle-all",
    "--bind=alt-p:toggle-preview",
    "--bind=ctrl-f:preview-half-page-down",
    "--bind=ctrl-b:preview-half-page-up",
  },

  -- fzf colors extract from vim colorscheme's syntax to RGB color code (e.g., #728174),
  -- and pass to fzf '--color' option.
  -- see: https://github.com/junegunn/fzf/blob/master/README-VIM.md#explanation-of-gfzf_colors
  fzf_color_opts = {
    fg = { "fg", "Normal" },
    bg = { "bg", "Normal" },
    hl = { "fg", "Comment" },
    ["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
    ["bg+"] = { "bg", "CursorLine", "CursorColumn" },
    ["hl+"] = { "fg", "Statement" },
    info = { "fg", "PreProc" },
    border = { "fg", "Ignore" },
    prompt = { "fg", "Conditional" },
    pointer = { "fg", "Exception" },
    marker = { "fg", "Keyword" },
    spinner = { "fg", "Label" },
    header = { "fg", "Comment" },
    preview_label = { "fg", "Label" },
  },

  -- icons
  -- nerd fonts: https://www.nerdfonts.com/cheat-sheet
  -- unicode: https://symbl.cc/en/
  icons = {
    unknown_file = ""
    folder = "",
    folder_open = "",

    fzf_pointer = "",
    fzf_marker = "✓",
  },

  -- popup window options for all commands.
  -- each commands group also has a 'win_opts' field that can overwrite this.
  popup = {
    -- float window options pass to 'vim.api.nvim_open_win()' API.
    win_opts = {
      -- by default popup window is in the centor of editor.
      -- you can also place it relative to
      -- 1. editor: whole vim.
      -- 2. win: current window.
      -- 3. cursor: cursor in current window.
      relative = 'editor',

      -- height/width.
      --
      -- 1. if 0 <= h/w <= 1, evaluate proportionally according to editor's lines and columns,
      --    or window's height and width, e.g. popup height = h * lines, width = w * columns.
      --
      -- 2. if h/w > 1, evaluate as absolute height and width,
      --    directly pass to `vim.api.nvim_open_win` api.
      --
      height = 0.85,
      width = 0.85,

      -- when relative is 'editor' or 'win', the anchor is the center position,
      -- not default 'NW' (north west).
      -- because 'NW' is a little bit complicated for users to calculate the position,
      -- usually we just put the popup window in the center of editor.
      --
      -- 1. if -0.5 <= r/c <= 0.5, evaluate proportionally according to editor's lines and columns.
      --    e.g. shift rows = r * lines, shift columns = c * columns.
      --
      -- 2. if r/c <= -1 or r/c >= 1, evaluate as absolute rows/columns to be shift.
      --    e.g. you can easily set 'row = -vim.o.cmdheight' to move popup window up 1~2 lines
      --    (based on your 'cmdheight' option).
      --    this is especially useful when popup window is too big and conflicts with status line at bottom.
      --
      -- 3. r/c cannot be in range (-1, -0.5) or (0.5, 1), it makes no sense.
      --
      -- when relative is 'cursor', the anchor is 'NW' (north west).
      -- because we just want to put the popup window relative to the cursor.
      -- so 'row' and 'col' will be directly passed to `vim.api.nvim_open_win` API without any pre-processing.
      --
      row = 0,
      col = 0,

      border = "none",
      zindex = 51,
    },
  },

  -- environment variables
  env = {
    -- by default use `vim.env.VIM` (e.g., `/usr/local/bin/nvim`) as the lua script interpreter,
    -- you can overwrite by set this option.
    nvim = nil,

    -- by default use `vim.fn['fzf#exec']` function as the fzf binary,
    -- you can overwrite by set this option.
    fzf = nil,
  },

  -- cache
  cache = {
    -- for macOS/linux: ~/.local/share/nvim/fzfx.nvim
    -- for Windows: ~/AppData/Local/nvim-data/fzfx.nvim
    dir = require("fzfx.path").join(vim.fn.stdpath("data"), "fzfx.nvim"),
  },

  -- debug
  debug = {
    -- enable debug
    enable = false,

    -- print logs to console (command line).
    console_log = true,

    -- write logs to file.
    -- for macOS/linux: ~/.local/share/nvim/fzfx.log
    -- for Windows: ~/AppData/Local/nvim-data/fzfx.log
    file_log = false,
  },
}
```

### Commands Group

Each commands group (e.g., `files`, `live_grep`, `git_files`, `lsp_diagnostics`, etc) share the same schema:

1. `commands`: a user command, or more variants feed with different types of input queries, each command is binding with a provider.
2. `providers`: one or more data sources, that provide lines for fzf binary (e.g., on the left side). A provider can be:
   1. A plain shell command, e.g., `fd . -cnever -tf`.
   2. A lua function that returns shell command, e.g., `rg --column -n --no-heading -H 'fzfx'` (here user's input `'fzfx'` is dynamically passing to the provider on every keystroke).
   3. A lua function that directly returns the lines for fzf binary. Some data sources are not from shell commands, for example buffers, lsp diagnostics, thus we need to directly generate the lines.
3. `previewers`: one or more lua function that can generate the preview content for the fzf binary (e.g., on the right side). A previewer can be:
   1. A lua function that returns shell command, e.g., `bat --color=always --highlight-line=17 lua/fzfx/config.lua`.
   2. A lua function that directly returns the preview contents for fzf binary.
   3. A nvim buffer that shows the preview content (todo).
4. `actions`: allow user press key and exit fzf popup, and invoke callback function with selected lines.
5. (Optional) `interactions`: allow user press key and invoke callback function on current line, without exiting fzf popup.
6. (Optional) `fzf_opts`, `win_opts` and `other_opts`: specific options overwrite the common defaults, or provide other abilities.

### The `ls -1` Example

Here's a minimal commands group example that implement the `ls -1` like command `FzfxLs`:

```lua
require("fzfx").setup({
  users = {
    ls = {
      --- @type CommandConfig[]
      commands = {
        {
          name = "FzfxLs",
          feed = "args",
          opts = {
            bang = true,
            desc = "ls -1",
          },
          default_provider = "filter_hiddens",
        },
        {
          name = "FzfxLsU",
          feed = "args",
          opts = {
            bang = true,
            desc = "ls -1a",
          },
          default_provider = "include_hiddens",
        },
      },
      --- @type table<string, ProviderConfig>
      providers = {
        filter_hiddens = {
          key = "ctrl-h",
          provider = { "ls", "-1" },
        },
        include_hiddens = {
          key = "ctrl-u",
          provider = { "ls", "-1a" },
        },
      },
      --- @type table<string, PreviewerConfig>
      previewers = {
        filter_hiddens = {
          previewer = function(line)
            -- each line is either a folder or a file
            return vim.fn.isdirectory(line) > 0 and { "ls", "-lha", line }
              or { "cat", line }
          end,
          previewer_type = "command_list",
        },
        include_hiddens = {
          previewer = function(line)
            return vim.fn.isdirectory(line) > 0 and { "ls", "-lha", line }
              or { "cat", line }
          end,
          previewer_type = "command_list",
        },
      },
      actions = {
        ["esc"] = function(lines)
          -- do nothing
        end,
        ["enter"] = function(lines)
          for _, line in ipairs(lines) do
            vim.cmd(string.format([[edit %s]], line))
          end
        end,
      },
      fzf_opts = {
        "--multi",
        { "--prompt", "Ls > " },
      },
    },
  },
})
```

And you will got:

https://github.com/linrongbin16/fzfx.nvim/assets/6496887/e60b69ab-3a29-4acc-8e48-cb9ab1b22b24

You can also use the `require("fzfx").register("ls", {...})` api to do that.

For complete options and defaults, please check [config.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/config.lua).

For advanced configurations, please check [Advanced Configuration](https://github.com/linrongbin16/fzfx.nvim/wiki/Advanced-Configuration).

To create your own commands, please see [A General Schema for Creating FZF Command](https://github.com/linrongbin16/fzfx.nvim/wiki/A-General-Schema-for-Creating-FZF-Command) and [schema.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/schema.lua).

If you have encounter some breaks on configuration, please see [CHANGELOG.md](https://github.com/linrongbin16/fzfx.nvim/blob/main/CHANGELOG.md).

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
