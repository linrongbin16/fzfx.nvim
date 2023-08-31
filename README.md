<!-- markdownlint-disable MD013 MD034 MD033 -->

# fzfx.nvim

[![Neovim-v0.5](https://img.shields.io/badge/Neovim-v0.5-blueviolet.svg?style=flat-square&logo=Neovim&logoColor=green)](https://github.com/neovim/neovim/releases/tag/v0.5.0)
[![License](https://img.shields.io/github/license/linrongbin16/lin.nvim?style=flat-square&logo=GNU)](https://github.com/linrongbin16/lin.nvim/blob/main/LICENSE)
![Linux](https://img.shields.io/badge/Linux-%23.svg?style=flat-square&logo=linux&color=FCC624&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-%23.svg?style=flat-square&logo=apple&color=000000&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-%23.svg?style=flat-square&logo=windows&color=0078D6&logoColor=white)

> E(x)tended commands missing in [fzf.vim](https://github.com/junegunn/fzf.vim).

This is the next generation of [fzfx.vim](https://github.com/linrongbin16/fzfx.vim). A brand new fzf plugin for Neovim, build from scratch, focused on user friendly, customization and performance.

- [Feature](#feature)
- [Requirement](#requirement)
  - [Windows](#windows)
  - [Path containing whitespace & Escaping issue](#path-containing-whitespace--escaping-issue)
- [Install](#install)
  - [vim-plug](#vim-plug)
  - [packer.nvim](#packernvim)
  - [lazy.nvim](#lazynvim)
- [Commands](#commands)
  - [Bind Keys](#bind-keys)
- [Recommended Key Mappings](#recommended-key-mappings)
  - [Vimscript](#vimscript)
  - [Lua](#lua)
- [Configuration](#configuration)
  - [Create your own commands](#create-your-own-commands)
- [Break Changes](#break-changes)
- [Credit](#credit)
- [Contribute](#contribute)

## Feature

- Icons & colors.
- Windows support.
- Lua support: preview lua function defined commands and key mappings (todo).
- Multiple variants to avoid manual input:
  - Search by visual select.
  - Search by cursor word.
  - Search by yank text.
- Easily switch on data sources:
  - Whether to search hidden and ignored files when searching files and text.
  - Local or remote branches when searching git branches.
  - All diagnostics on workspace or only on current buffer when searching lsp diagnostics (todo).
- Maximized control on configuration.
- ...

> The real power comes from the the fully dynamic runtime & pipeline control, it allows you to do almost anything you want, please see [Configuration](#configuration).

<details>
<summary><b>Click here to see some demo</b></summary>
<br/>

- Search `fzfx` with rg's `-g *ch.lua` option on specific filetypes:

  https://github.com/linrongbin16/fzfx.nvim/assets/6496887/aa5ef18c-26b4-4a93-bd0c-bfeba6f6caf1

</details>

## Requirement

- Neovim &ge; 0.5.
- [Nerd fonts](https://www.nerdfonts.com/) (optional for icons).
- [rg](https://github.com/BurntSushi/ripgrep) (optional for **live grep** commands, by default use [grep](https://man7.org/linux/man-pages/man1/grep.1.html)).
- [fd](https://github.com/sharkdp/fd) (optional for **files** commands, by default use [find](https://man7.org/linux/man-pages/man1/find.1.html)).
- [bat](https://github.com/sharkdp/bat) (optional for preview files, e.g. the right side of **live grep**, **files**, etc, by default use [cat](https://man7.org/linux/man-pages/man1/cat.1.html)).
- [git](https://git-scm.com/) (optional for **git files**, **git branches**, **git commits**, etc commands).

> Note: `grep`, `find` and `cat` are unix/linux builtin commands, while on Windows we don't have a builtin shell environment, so install `rg`, `fd` and `bat` should be a better choice. Also see [Windows](#windows) for how to install linux commands on Windows.

### Windows

<details>
<summary><b>Click here to see how to install linux commands on Windows</b></summary>
<br/>

There're many ways to install portable linux shell and builtin commands on Windows, but personally I would recommend below two methods.

#### [Git for Windows](https://git-scm.com/download/win)

Install with the below 3 options:

- In **Select Components**, select **Associate .sh files to be run with Bash**.

  <img alt="install-windows-git1.png" src="https://raw.githubusercontent.com/linrongbin16/lin.nvim.dev/main/assets/installations/install-windows-git1.png" width="70%" />

- In **Adjusting your PATH environment**, select **Use Git and optional Unix tools
  from the Command Prompt**.

  <img alt="install-windows-git2.png" src="https://raw.githubusercontent.com/linrongbin16/lin.nvim.dev/main/assets/installations/install-windows-git2.png" width="70%" />

- In **Configuring the terminal emulator to use with Git Bash**, select **Use Windows's
  default console window**.

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
<summary><b>Click here to how whitespaces affected escaping characters on path</b></summary>
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

## Install

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
        dependencies = { "junegunn/fzf" },
        config = function()
            require("fzfx").setup()
        end
    },

})
```

## Commands

Commands are named following below rules:

- All commands are named with prefix `Fzfx`.
- The main command name has no suffix.
- The unrestricted variant is named with `U` suffix.
- The visual select variant is named with `V` suffix.
- The cursor word variant is named with `W` suffix.
- The yank text variant is named with `P` suffix (just like press the `p` key).
- The current buffer only variant is named with `B` suffix.

Especially for git commands:

- The remote git branch variant is named with `R` suffix.

> Note: command names can be configured, see [Configuration](#configuration).

### Bind Keys

- Preview keys
  - `alt-p`: toggle preview.
- Multi keys
  - `ctrl-e`: toggle select.
  - `ctrl-a`: toggle select all.

> Note: builtin keys can be configured, see [Configuration](#configuration).

<table>
<thead>
  <tr>
    <th>Group</th>
    <th>Command</th>
    <th>Mode</th>
    <th>Multi Key?</th>
    <th>Preview Key?</th>
    <th>Special Feature</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td rowspan="4">Files</td>
    <td>FzfxFiles(U)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4"></td>
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
  <tr>
    <td rowspan="4">Live Grep</td>
    <td>FzfxLiveGrep(U)</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `--` to pass raw options to search command (grep, rg)</td>
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
  <tr>
    <td rowspan="4">Buffers</td>
    <td>FzfxBuffers</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4"></td>
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
  <tr>
    <td rowspan="4">Git Files</td>
    <td>FzfxGFiles</td>
    <td>N</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4"></td>
  </tr>
  <tr>
    <td>FzfxGFilesV</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxGFilesW</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxGFilesP</td>
    <td>N</td>
  </tr>
  <tr>
    <td rowspan="4">Git Branches</td>
    <td>FzfxGBranches(R)</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `enter` to checkout branch</td>
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
  <tr>
    <td rowspan="4">Git Commits</td>
    <td>FzfxGCommits(B)</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `enter` to copy commit SHA</td>
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
  <tr>
    <td rowspan="4">Git Blame</td>
    <td>FzfxGBlame</td>
    <td>N</td>
    <td rowspan="4">No</td>
    <td rowspan="4">Yes</td>
    <td rowspan="4">1. Use `enter` to copy commit SHA</td>
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

## Recommended Key Mappings

### Vimscript

```vim

" ======== files ========

" find files
nnoremap <space>f :\<C-U>FzfxFiles<CR>
" visual select
xnoremap <space>f :\<C-U>FzfxFilesV<CR>
" unrestricted
nnoremap <space>uf :\<C-U>FzfxFilesU<CR>
" unrestricted visual select
xnoremap <space>uf :\<C-U>FzfxFilesUV<CR>

" cursor word
nnoremap <space>wf :\<C-U>FzfxFilesW<CR>
" unrestricted cursor word
nnoremap <space>uwf :\<C-U>FzfxFilesUW<CR>
" yank text
nnoremap <space>pf :\<C-U>FzfxFilesP<CR>
" unrestricted yank text
nnoremap <space>upf :\<C-U>FzfxFilesUP<CR>

" ======== live grep ========

" live grep
nnoremap <space>l :\<C-U>FzfxLiveGrep<CR>
" visual select
xnoremap <space>l :\<C-U>FzfxLiveGrepV<CR>
" unrestricted
nnoremap <space>ul :\<C-U>FzfxLiveGrepU<CR>
" unrestricted visual select
xnoremap <space>ul :\<C-U>FzfxLiveGrepUV<CR>

" by cursor word
nnoremap <space>wl :\<C-U>FzfxLiveGrepW<CR>
" unrestrictly cursor word
nnoremap <space>uwl :\<C-U>FzfxLiveGrepUW<CR>
" by yank text
nnoremap <space>pl :\<C-U>FzfxLiveGrepP<CR>
" unrestrictly yank text
nnoremap <space>upl :\<C-U>FzfxLiveGrepUP<CR>

" ======== buffers ========

" buffers
nnoremap <space>bf :\<C-U>FzfxBuffers<CR>
" visual select
xnoremap <space>bf :\<C-U>FzfxBuffersV<CR>
" by cursor word
nnoremap <space>wbf :\<C-U>FzfxBuffersW<CR>
" by yank text
nnoremap <space>pbf :\<C-U>FzfxBuffersP<CR>

" ======== git files ========

" git files
nnoremap <space>gf :\<C-U>FzfxGFiles<CR>
" visual select
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
" remote branches
nnoremap <space>rbr :\<C-U>FzfxGBranchesR<CR>
" remote branches by visual select
xnoremap <space>rbr :\<C-U>FzfxGBranchesRV<CR>

" by cursor word
nnoremap <space>wbr :\<C-U>FzfxGBranchesW<CR>
" remote branches by cursor word
nnoremap <space>rwbr :\<C-U>FzfxGBranchesRW<CR>
" by yank text
nnoremap <space>pbr :\<C-U>FzfxGBranchesP<CR>
" remote branches by yank text
nnoremap <space>rpbr :\<C-U>FzfxGBranchesRP<CR>

" ======== git commits ========

" git commits
nnoremap <space>gc :\<C-U>FzfxGCommits<CR>
" by visual select
xnoremap <space>gc :\<C-U>FzfxGCommitsV<CR>
" only current buffer
nnoremap <space>bgc :\<C-U>FzfxGCommitsB<CR>
" only current buffer by visual select
xnoremap <space>bgc :\<C-U>FzfxGCommitsBV<CR>

" by cursor word
nnoremap <space>wgc :\<C-U>FzfxGCommitsW<CR>
" only current buffer by cursor word
nnoremap <space>bwgc :\<C-U>FzfxGCommitsBW<CR>
" by yank text
nnoremap <space>pgc :\<C-U>FzfxGCommitsP<CR>
" only current buffer by yank text
nnoremap <space>bpgc :\<C-U>FzfxGCommitsBP<CR>

" ======== git blame ========

" git blame
nnoremap <space>gb :\<C-U>FzfxGBlame<CR>
" visual select
xnoremap <space>gb :\<C-U>FzfxGBlameV<CR>
" by cursor word
nnoremap <space>wgb :\<C-U>FzfxGBlameW<CR>
" by yank text
nnoremap <space>pgb :\<C-U>FzfxGBlameP<CR>
```

### Lua

```lua

-- ======== files ========

-- find files
vim.keymap.set('n', '<space>f', '<cmd>FzfxFiles<cr>',
        {silent=true, noremap=true, desc="Find files"})
-- visual select
vim.keymap.set('x', '<space>f', '<cmd>FzfxFilesV<CR>',
        {silent=true, noremap=true, desc="Find files"})
-- unrestricted
vim.keymap.set('n', '<space>uf',
        '<cmd>FzfxFilesU<cr>',
        {silent=true, noremap=true, desc="Unrestricted find files"})
-- unrestricted visual select
vim.keymap.set('x', '<space>uf',
        '<cmd>FzfxFilesUV<CR>',
        {silent=true, noremap=true, desc="Unrestricted find files"})

-- cursor word
vim.keymap.set('n', '<space>wf', '<cmd>FzfxFilesW<cr>',
        {silent=true, noremap=true, desc="Find files by cursor word"})
-- unrestricted cursor word
vim.keymap.set('n', '<space>uwf', '<cmd>FzfxFilesUW<cr>',
        {silent=true, noremap=true, desc="Unrestricted find files by cursor word"})
-- yank text
vim.keymap.set('n', '<space>pf', '<cmd>FzfxFilesP<cr>',
        {silent=true, noremap=true, desc="Find files by yank text"})
-- unrestricted yank text
vim.keymap.set('n', '<space>uwf', '<cmd>FzfxFilesUP<cr>',
        {silent=true, noremap=true, desc="Unrestricted find files by yank text"})

-- ======== live grep ========

-- live grep
vim.keymap.set('n', '<space>l',
        '<cmd>FzfxLiveGrep<cr>',
        {silent=true, noremap=true, desc="Live grep"})
-- visual select
vim.keymap.set('x', '<space>l',
        "<cmd>FzfxLiveGrepV<cr>",
        {silent=true, noremap=true, desc="Live grep"})
-- unrestricted live grep
vim.keymap.set('n', '<space>ul',
        '<cmd>FzfxLiveGrepU<cr>',
        {silent=true, noremap=true, desc="Unrestricted live grep"})
-- unrestricted visual select
vim.keymap.set('x', '<space>ul',
        "<cmd>FzfxLiveGrepUV<cr>",
        {silent=true, noremap=true, desc="Unrestricted live grep"})

-- cursor word
vim.keymap.set('n', '<space>wl',
        '<cmd>FzfxLiveGrepW<cr>',
        {silent=true, noremap=true, desc="Live grep by cursor word"})
-- unrestricted cursor word
vim.keymap.set('n', '<space>uwl',
        '<cmd>FzfxLiveGrepUW<cr>',
        {silent=true, noremap=true, desc="Unrestricted live grep by cursor word"})
-- yank text
vim.keymap.set('n', '<space>pl',
        '<cmd>FzfxLiveGrepP<cr>',
        {silent=true, noremap=true, desc="Live grep by cursor word"})
-- unrestricted yank text
vim.keymap.set('n', '<space>upl',
        '<cmd>FzfxLiveGrepUP<cr>',
        {silent=true, noremap=true, desc="Unrestricted live grep by yank text"})

-- ======== buffers ========

-- buffers
vim.keymap.set('n', '<space>bf',
        '<cmd>FzfxBuffers<cr>',
        {silent=true, noremap=true, desc="Find buffers"})
-- visual select
vim.keymap.set('x', '<space>bf',
        "<cmd>FzfxBuffersV<cr>",
        {silent=true, noremap=true, desc="Find buffers"})
-- cursor word
vim.keymap.set('n', '<space>wbf',
        '<cmd>FzfxBuffersW<cr>',
        {silent=true, noremap=true, desc="Find buffers by cursor word"})
-- yank text
vim.keymap.set('n', '<space>pbf',
        '<cmd>FzfxBuffersP<cr>',
        {silent=true, noremap=true, desc="Find buffers by yank text"})

-- ======== git files ========

-- git files
vim.keymap.set('n', '<space>gf',
        '<cmd>FzfxGFiles<cr>',
        {silent=true, noremap=true, desc="Find git files"})
-- visual select
vim.keymap.set('x', '<space>gf',
        "<cmd>FzfxGFilesV<cr>",
        {silent=true, noremap=true, desc="Find git files"})
-- cursor word
vim.keymap.set('n', '<space>wgf',
        '<cmd>FzfxGFilesW<cr>',
        {silent=true, noremap=true, desc="Find git files by cursor word"})
-- yank text
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
-- remote git branches
vim.keymap.set('n', '<space>rbr',
        '<cmd>FzfxGBranchesR<cr>',
        {silent=true, noremap=true, desc="Search remote git branches"})
-- remote branches by visual select
vim.keymap.set('x', '<space>ubr',
        '<cmd>FzfxGBranchesRV<CR>',
        {silent=true, noremap=true, desc="Search remote git branches"})

-- cursor word
vim.keymap.set('n', '<space>wbr', '<cmd>FzfxGBranchesW<cr>',
        {silent=true, noremap=true, desc="Search git branches by cursor word"})
-- remote branches by cursor word
vim.keymap.set('n', '<space>rwbr', '<cmd>FzfxGBranchesRW<cr>',
        {silent=true, noremap=true, desc="Search remote git branches by cursor word"})
-- yank text
vim.keymap.set('n', '<space>pbr', '<cmd>FzfxGBranchesP<cr>',
        {silent=true, noremap=true, desc="Search git branches by yank text"})
-- remote branches by yank text
vim.keymap.set('n', '<space>rwbr', '<cmd>FzfxGBranchesRP<cr>',
        {silent=true, noremap=true, desc="Search remote git branches by yank text"})

-- ======== git commits ========

-- git commits
vim.keymap.set('n', '<space>gc', '<cmd>FzfxGCommits<cr>',
        {silent=true, noremap=true, desc="Search git commits"})
-- by visual select
vim.keymap.set('x', '<space>gc', '<cmd>FzfxGCommitsV<CR>',
        {silent=true, noremap=true, desc="Search git commits"})
-- only current buffer
vim.keymap.set('n', '<space>bgc',
        '<cmd>FzfxGCommitsB<cr>',
        {silent=true, noremap=true, desc="Search git commits only on current buffer"})
-- only current buffer by visual select
vim.keymap.set('x', '<space>bgc',
        '<cmd>FzfxGCommitsBV<CR>',
        {silent=true, noremap=true, desc="Search git commits only on current buffer"})

-- cursor word
vim.keymap.set('n', '<space>wgc', '<cmd>FzfxGCommitsW<cr>',
        {silent=true, noremap=true, desc="Search git commits by cursor word"})
-- only current buffer by cursor word
vim.keymap.set('n', '<space>bwgc', '<cmd>FzfxGCommitsBW<cr>',
        {silent=true, noremap=true, desc="Search git commits only on current buffer by cursor word"})
-- yank text
vim.keymap.set('n', '<space>pgc', '<cmd>FzfxGCommitsP<cr>',
        {silent=true, noremap=true, desc="Search git commits by yank text"})
-- only current buffer by yank text
vim.keymap.set('n', '<space>bpgc', '<cmd>FzfxGCommitsBP<cr>',
        {silent=true, noremap=true, desc="Search git commits only on current buffer by yank text"})

-- ======== git blame ========

-- git blame
vim.keymap.set('n', '<space>gb',
        '<cmd>FzfxGBlame<cr>',
        {silent=true, noremap=true, desc="Search git blame"})
-- visual select
vim.keymap.set('x', '<space>gb',
        "<cmd>FzfxGBlameV<cr>",
        {silent=true, noremap=true, desc="Search git blame"})
-- cursor word
vim.keymap.set('n', '<space>wgb',
        '<cmd>FzfxGBlameW<cr>',
        {silent=true, noremap=true, desc="Search git blame by cursor word"})
-- yank text
vim.keymap.set('n', '<space>pgb',
        '<cmd>FzfxGBlameP<cr>',
        {silent=true, noremap=true, desc="Search git blame by yank text"})
```

## Configuration

For complete options and default configurations, please check [config.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/config.lua).

If you have encounter some breaks on configuration, please see [Break Changes](#break-changes).

### Create your own commands

To create your own commands, please see [A General Schema for Creating FZF Command](https://github.com/linrongbin16/fzfx.nvim/wiki/A-General-Schema-for-Creating-FZF-Command) and [schema.lua](https://github.com/linrongbin16/fzfx.nvim/blob/c521e3027b26b4ffe1a49a5b1ceba6669ae62b6c/lua/fzfx/schema.lua#L1).

## Break Changes

- 2023-08-17
  - Re-bind keys 'ctrl-e'(select), 'ctrl-a'(select-all) to 'toggle', 'toggle-all'.
  - Remove default bind keys 'ctrl-d'(deselect), 'alt-a'(deselect-all).
  - Re-bind key 'ctrl-x' (delete buffer on `FzfxBuffers`) to 'ctrl-d'.
  - Re-bind key 'ctrl-l' (toggle-preview) to 'alt-p'.
- 2023-08-19
  - Refactor configs schema for better structure.
- 2023-08-28
  - Deprecate 'git_commits' ('FzfxGCommits') configs to new schema.
- 2023-08-30
  - Deprecate 'buffers' ('FzfxBuffers') configs to new schema.

## Credit

- [fzf.vim](https://github.com/junegunn/fzf.vim): Things you can do with [fzf](https://github.com/junegunn/fzf) and Vim.
- [fzf-lua](https://github.com/ibhagwan/fzf-lua): Improved fzf.vim written in lua.

## Contribute

Please open [issue](https://github.com/linrongbin16/fzfx.nvim/issues)/[PR](https://github.com/linrongbin16/fzfx.nvim/pulls) for anything about fzfx.nvim.

Like fzfx.nvim? Consider

[![Github Sponsor](https://img.shields.io/badge/-Sponsor%20Me%20on%20Github-magenta?logo=github&logoColor=white)](https://github.com/sponsors/linrongbin16)
[![Wechat Pay](https://img.shields.io/badge/-Tip%20Me%20on%20WeChat-brightgreen?logo=wechat&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
[![Alipay](https://img.shields.io/badge/-Tip%20Me%20on%20Alipay-blue?logo=alipay&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
