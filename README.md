<!-- markdownlint-disable MD013 MD034 -->

# fzfx.nvim

[![Neovim-v0.8.0](https://img.shields.io/badge/Neovim-v0.8.0-blueviolet.svg?style=flat-square&logo=Neovim&logoColor=green)](https://github.com/neovim/neovim/releases/tag/v0.8.0)
[![License](https://img.shields.io/github/license/linrongbin16/lin.nvim?style=flat-square&logo=GNU)](https://github.com/linrongbin16/lin.nvim/blob/main/LICENSE)
![Linux](https://img.shields.io/badge/Linux-%23.svg?style=flat-square&logo=linux&color=FCC624&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-%23.svg?style=flat-square&logo=apple&color=000000&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-%23.svg?style=flat-square&logo=windows&color=0078D6&logoColor=white)

> E(x)tended commands missing in [fzf.vim](https://github.com/junegunn/fzf.vim).

This is the next generation of [fzfx.vim](https://github.com/linrongbin16/fzfx.vim). A brand new fzf plugin for Neovim, build from scratch, focused on user friendly, customization and performance.

- [Feature](#feature)
- [Requirement](#requirement)
- [Install](#install)
  - [vim-plug](#vim-plug)
  - [packer.nvim](#packernvim)
  - [lazy.nvim](#lazynvim)
- [Commands](#commands)
- [Configuration](#configuration)
  - [Path containing whitespace & Escaping issue](#path-containing-whitespace--escaping-issue)
- [Credit](#credit)
- [Contribute](#contribute)

## Feature

- Windows support.
- Icons.
- Multiple variants to avoid manual input:
  - Search by visual select.
  - Search by cursor word.
  - Search by yanked register (todo).
- (Un)restricted mode: easily switch whether to search hidden and ignored files.
- Lua support: preview lua function defined commands and key mappings (todo).
- ...

Here's a live grep demo that searching `fzfx` with rg's `-g *ch.lua` (`--glob`) option on specific filetypes.

https://github.com/linrongbin16/fzfx.nvim/assets/6496887/aa5ef18c-26b4-4a93-bd0c-bfeba6f6caf1

## Requirement

- Neovim &ge; 0.8.
- [rg](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd), [bat](https://github.com/sharkdp/bat), recommand to install them with [cargo](https://www.rust-lang.org/):

  ```bash
  cargo install ripgrep
  cargo install fd-find
  cargo install --locked bat
  ```

- [nerdfonts](https://www.nerdfonts.com/) (optional for icons).

<!-- ### For Windows -->
<!---->
<!-- Since fzf.vim rely on the `sh` shell on Windows, so you need either: -->
<!---->
<!-- 1. Automatically install `git` and `sh` via [scoop](https://scoop.sh) and run powershell commands: -->
<!---->
<!--    ```powershell -->
<!--    # scoop -->
<!--    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -->
<!--    irm get.scoop.sh | iex -->
<!---->
<!--    scoop install 7zip -->
<!--    scoop install git -->
<!--    scoop install coreutils -->
<!--    ``` -->
<!---->
<!-- 2. Or manually install [Git for Windows](https://git-scm.com/download/win), and explicitly add unix builtin commands (`sh.exe`, `cat.exe`, `mv.exe`, etc) to `%PATH%` environment: -->
<!---->
<!--    1. In **Adjusting your PATH environment**, select **Use Git and optional Unix tools from the Command Prompt**. -->
<!---->
<!--    <p align="center"> -->
<!--      <img alt="install-git-step1.png" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/32c20d74-be0b-438b-8de4-347a3c6e1066" width="70%" /> -->
<!--    </p> -->
<!---->
<!--    2. In **Configuring the terminal emulator to use with Git Bash**, select **Use Windows's default console window**. -->
<!---->
<!--    <p align="center"> -->
<!--      <img alt="install-git-step2.png" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/22a51d91-5f48-42a2-8a31-71584a52efe4" width="70%" /> -->
<!--    </p> -->
<!---->
<!-- <details> -->
<!-- <summary><b>WARNING: WSL2 can overwrite `bash.exe`</b></summary> -->
<!-- <br /> -->
<!---->
<!-- If you're using WSL2 (Windows Subsystem for Linux), the `bash.exe` will be overwrite by `%SystemRoot%\System32\bash.exe` so fzf preview cannot work properly. -->
<!---->
<!-- To fix this, please put `$env:USERPROFILE\scoop\shims` (step-1) on top of Windows system32 path. -->
<!---->
<!-- <p align="center"><img alt="scoop-path" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/77b156a9-57ce-4a75-a860-be813d51f909" width="70%" /></p> -->
<!---->
<!-- Or put `C:\Program Files\Git\cmd`, `C:\Program Files\Git\mingw64\bin` and `C:\Program Files\Git\usr\bin` (step-2) on top of Windows system32 path. -->
<!---->
<!-- <p align="center"><img alt="git-path" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/8e77e211-1993-4fbb-b845-37c4db883ac4" width="70%" /></p> -->
<!---->
<!-- </details> -->

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
        requires = { "junegunn/fzf" },
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

<table>
<thead>
  <tr>
    <th>Group</th>
    <th>Command</th>
    <th>Mode</th>
    <th>Description</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td rowspan="3">Files</td>
    <td>FzfxFiles(U)</td>
    <td>Normal</td>
    <td>Find files (unrestricted)</td>
  </tr>
  <tr>
    <td>FzfxFiles(U)V</td>
    <td>Visual</td>
    <td>Find files (unrestricted) by visual select</td>
  </tr>
  <tr>
    <td>FzfxFiles(U)W</td>
    <td>Normal</td>
    <td>Find files (unrestricted) by cursor word</td>
  </tr>
  <tr>
    <td rowspan="3">Live Grep</td>
    <td>FzfxLiveGrep(U)</td>
    <td>Normal</td>
    <td>Live grep (unrestricted)</td>
  </tr>
  <tr>
    <td>FzfxLiveGrep(U)V</td>
    <td>Visual</td>
    <td>Live grep (unrestricted) by visual select</td>
  </tr>
  <tr>
    <td>FzfxLiveGrep(U)W</td>
    <td>Normal</td>
    <td>Live grep (unrestricted) by cursor word</td>
  </tr>
</tbody>
</table>

## Recommended Key Mappings

### For Vim

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

" ======== live grep ========

" live grep
nnoremap <space>l :\<C-U>FzfxLiveGrep<CR>
" visual select
xnoremap <space>l :\<C-U>FzfxLiveGrepV<CR>
" unrestricted
nnoremap <space>ul :\<C-U>FzfxLiveGrepU<CR>
" unrestricted by visual select
xnoremap <space>ul :\<C-U>FzfxLiveGrepUV<CR>

" by cursor word
nnoremap <space>wl :\<C-U>FzfxLiveGrepW<CR>
" unrestrictly by cursor word
nnoremap <space>uwl :\<C-U>FzfxLiveGrepUW<CR>
```

### For Neovim

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
        {silent=true, noremap=true, desc="Live grep"})

-- cursor word
vim.keymap.set('n', '<space>wl',
        '<cmd>FzfxLiveGrepW<cr>',
        {silent=true, noremap=true, desc="Live grep under cursor word"})
-- unrestricted cursor word
vim.keymap.set('n', '<space>uwl',
        '<cmd>FzfxLiveGrepUW<cr>',
        {silent=true, noremap=true, desc="Unrestricted live grep under cursor word"})

```

## Configuration

For complete options and default configurations, please check [config.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/config.lua).

### Path containing whitespace & Escaping issue

fzfx.nvim internally use `nvim` and `fzf`, but when there're whitespaces on the path, launching correct shell command becomes quite difficult, since it will seriously affected shell escape characters. Here're some typical cases:

1. `C:\Program Files\Neovim\bin\nvim.exe`
2. `C:\Users\Lin Rongbin\opt\fzf\fzf.exe`

For such case, please add both of them to `%PATH%` (`$env:PATH` in PowerShell), and set the `env` configuration:

```lua
require("fzfx").setup({
    env = {
        nvim = 'nvim',
        fzf = 'fzf',
    }
})
```

This will help fzfx.nvim avoid the shell command issue.

## Credit

- [fzf.vim](https://github.com/junegunn/fzf.vim): Things you can do with [fzf](https://github.com/junegunn/fzf) and Vim.
- [fzf-lua](https://github.com/ibhagwan/fzf-lua): Improved fzf.vim written in lua.

## Contribute

Please open [issue](https://github.com/linrongbin16/fzfx.nvim/issues)/[PR](https://github.com/linrongbin16/fzfx.nvim/pulls) for anything about fzfx.nvim.

Like fzfx.nvim? Consider

[![Github Sponsor](https://img.shields.io/badge/-Sponsor%20Me%20on%20Github-magenta?logo=github&logoColor=white)](https://github.com/sponsors/linrongbin16)
[![Wechat Pay](https://img.shields.io/badge/-Tip%20Me%20on%20WeChat-brightgreen?logo=wechat&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
[![Alipay](https://img.shields.io/badge/-Tip%20Me%20on%20Alipay-blue?logo=alipay&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
