<!-- markdownlint-disable MD001 MD013 MD034 MD033 MD051 -->

# fzfx.nvim

<p align="center">
<a href="https://github.com/neovim/neovim/releases/v0.7.0"><img alt="Neovim" src="https://img.shields.io/badge/Neovim-v0.7+-57A143?logo=neovim&logoColor=57A143" /></a>
<a href="https://github.com/linrongbin16/commons.nvim"><img alt="commons.nvim" src="https://custom-icon-badges.demolab.com/badge/Powered_by-commons.nvim-teal?logo=heart&logoColor=fff&labelColor=deeppink" /></a>
<a href="https://luarocks.org/modules/linrongbin16/fzfx.nvim"><img alt="luarocks" src="https://custom-icon-badges.demolab.com/luarocks/v/linrongbin16/fzfx.nvim?label=LuaRocks&labelColor=2C2D72&logo=tag&logoColor=fff&color=blue" /></a>
<a href="https://github.com/linrongbin16/fzfx.nvim/actions/workflows/ci.yml"><img alt="ci.yml" src="https://img.shields.io/github/actions/workflow/status/linrongbin16/fzfx.nvim/ci.yml?label=GitHub%20CI&labelColor=181717&logo=github&logoColor=fff" /></a>
<a href="https://app.codecov.io/github/linrongbin16/fzfx.nvim"><img alt="codecov" src="https://img.shields.io/codecov/c/github/linrongbin16/fzfx.nvim?logo=codecov&logoColor=F01F7A&label=Codecov" /></a>
</p>

<p align="center"><i>
FZF-based fuzzy finder running on a dynamic engine that parsing user query and selection on every keystroke.
</i></p>

https://github.com/linrongbin16/fzfx.nvim/assets/6496887/47b03150-14e3-479a-b1af-1b2995659403

> Search `fzfx` with rg's `-g *spec.lua` option.

## 📖 Table of contents

- [Features](#-features)
- [Requirements](#-requirements)
  - [Windows](#windows)
  - [Whitespace Escaping Issue](#whitespace-escaping-issue)
- [Install](#-install)
- [Commands](#-commands)
  - [Files & Buffers](#files--buffers)
  - [Grep](#grep)
  - [Git](#git)
  - [Lsp & Diagnostics](#lsp--diagnostics)
  - [Vim](#vim)
  - [Misc](#misc)
- [Recommended Key Mappings](#-recommended-key-mappings)
- [Configuration](#-configuration)
  - [Create Your Own Command](#create-your-own-command)
  - [API References](#api-references)
- [Credit](#-credit)
- [Development](#-development)
- [Contribute](#-contribute)

## ✨ Features

- Icons & colors.
- Windows support.
- Lua support: preview lua defined vim commands and key mappings.
- Parsing user query and selection on every keystroke, a typical use case is passing raw rg options via `--` flag (see [Demo](https://github.com/linrongbin16/fzfx.nvim/wiki/Demo)).
- Multiple variants to avoid manual input:
  - Search by visual select.
  - Search by cursor word.
  - Search by yank text.
  - Search by resume last search.
- Multiple data sources to avoid restart search flow:
  - Exclude or include the hidden/ignored files when searching files.
  - Local or remote branches when searching git branches.
  - Workspace or only current buffer diagnostics when searching diagnostics.
  - ...
- Maximized configuration.
- And a lot more.

> Please see [Demo](https://github.com/linrongbin16/fzfx.nvim/wiki/Demo) for more features & use cases.

## ✅ Requirements

- Neovim &ge; v0.7.0.
- [fzf](https://github.com/junegunn/fzf).
- [Nerd fonts](https://www.nerdfonts.com/) (optional for icons).
- [rg](https://github.com/BurntSushi/ripgrep) (optional for **live grep**, by default use [grep](https://man7.org/linux/man-pages/man1/grep.1.html)).
- [fd](https://github.com/sharkdp/fd) (optional for **files**, by default use [find](https://man7.org/linux/man-pages/man1/find.1.html)).
- [bat](https://github.com/sharkdp/bat) (optional for preview files, by default use [cat](https://man7.org/linux/man-pages/man1/cat.1.html)), [curl](https://man7.org/linux/man-pages/man1/curl.1.html) (optional for preview window labels).
- [delta](https://github.com/dandavison/delta) (optional for preview git **diff, show, blame**).
- [lsd](https://github.com/lsd-rs/lsd)/[eza](https://github.com/eza-community/eza) (optional for **file explorer** commands, by default use [ls](https://man7.org/linux/man-pages/man1/ls.1.html)).

### Windows

`grep`, `find`, `cat`, etc are unix/linux builtin commands, while on Windows we don't have a builtin shell environment, so install rust commands such as `rg`, `fd`, `bat`, etc should be better choice.

While still recommend Windows users install linux shell commands, since utils like `echo`, `curl` are internally used by somewhere.

<details>
<summary><i>Click here to see how to install linux commands on Windows</i></summary>
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

After this step, **git.exe** and builtin linux commands(such as **echo.exe**, **ls.exe**, **curl.exe**) will be available in `%PATH%`.

#### [scoop](https://scoop.sh/)

Run below powershell commands:

```powershell
# scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

scoop bucket add extras
scoop install git           # git, bash, sh
scoop install uutils-coreutils     # echo, ls, cat
scoop install curl          # curl
scoop install grep          # grep
```

> Note: install the rust-reimplementation [uutils-coreutils](https://github.com/uutils/coreutils) instead of GNU [coreutils](https://www.gnu.org/software/coreutils/), since some (for example `ls`) GNU commands is actually broken on Windows 10 x86_64 PC.

#### Fix conflicts between embedded commands in `C:\Windows\System32` and portable linux commands

Windows actually already provide some commands (`find.exe`, `bash.exe`) in `C:\Windows\System32` (or `%SystemRoot%\system32`), while they are not the linux commands they are named after, but could override our installations. To fix this issue, we could prioritize the git or scoop environment variables in `%PATH%`.

<img alt="windows-path" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/5296429b-daae-40f6-be16-6c065ef7bf05" width="70%" />

</details>

### Whitespace Escaping Issue

<details>
<summary><i>Click here to see how whitespace affect escaping characters on path</i></summary>
<br/>

This plugin internally extends `nvim`, `fzf` and lua scripts to full path when launching command.

1. Example on macOS:

   `/Users/rlin/.config/nvim/lazy/fzf/bin/fzf --print-query --listen --query '' --preview 'nvim -n -u NONE --clean --headless -l /Users/rlin/.local/share/nvim/site/pack/test/start/fzfx.nvim/bin/general/previewer.lua 2 /Users/rlin/.local/share/nvim/fzfx.nvim/previewer_metafile /Users/rlin/.local/share/nvim/fzfx.nvim/previewer_resultfile {}' --bind 'start:execute-silent(echo $FZF_PORT>/Users/rlin/.local/share/nvim/fzfx.nvim/fzf_port_file)' --multi --preview-window 'left,65%,+{2}-/2' --border=none --delimiter ':' --prompt 'Incoming Calls > ' --expect 'esc' --expect 'double-click' --expect 'enter' >/var/folders/5p/j4q6bz395fbbxdf_6b95_nz80000gp/T/nvim.rlin/fIj5xA/2`

2. Example on Windows 10:

   `C:/Users/linrongbin/github/junegunn/fzf/bin/fzf --query "" --header ":: Press \27[38;2;255;121;198mCTRL-U\27[0m to unrestricted mode" --prompt "~/g/l/fzfx.nvim > " --bind "start:unbind(ctrl-r)" --bind "ctrl-u:unbind(ctrl-u)+execute-silent(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\rpc\\client.lua 1)+change-header(:: Press \27[38;2;255;121;198mCTRL-R\27[0m to restricted mode)+rebind(ctrl-r)+reload(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\files\\provider.lua C:\\Users\\linrongbin\\AppData\\Local\\nvim-data\\fzfx.nvim\\switch_files_provider)" --bind "ctrl-r:unbind(ctrl-r)+execute-silent(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\rpc\\client.lua 1)+change-header(:: Press \27[38;2;255;121;198mCTRL-U\27[0m to unrestricted mode)+rebind(ctrl-u)+reload(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\files\\provider.lua C:\\Users\\linrongbin\\AppData\\Local\\nvim-data\\fzfx.nvim\\switch_files_provider)" --preview "C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\files\\previewer.lua {}" --bind "ctrl-l:toggle-preview" --expect "enter" --expect "double-click" >C:\\Users\\LINRON~1\\AppData\\Local\\Temp\\nvim.0\\JSmP06\\2`

But when there're whitespaces on the path, launching correct shell command becomes quite difficult, since it will seriously affected escaping characters. Here're two typical cases:

1. `C:\Program Files\Neovim\bin\nvim.exe`: nvim installed in `C:\Program Files` directory.

   Please add executables (`nvim.exe`, `fzf.exe`) to `%PATH%` (`$env:PATH` in PowerShell), and set the `env` configuration:

   ```lua
   require("fzfx").setup({
     env = {
       nvim = 'nvim',
       fzf = 'fzf',
     }
   })
   ```

   This will help avoid the shell command issue.

2. `C:\Users\Lin Rongbin\opt\Neovim\bin\nvim.exe`: user name (`Lin Rongbin`) contains whitespace.

   We still cannot handle the 2nd case because all lua scripts in this plugin will thus always contain whitespaces in their path.

Please always avoid whitespaces in directories and file names.

</details>

## 📦 Install

> [!IMPORTANT]
>
> The upgrade of major version means there's a break change, please specify a version/tag to avoid!

<details>
<summary><b>With <a href="https://github.com/folke/lazy.nvim">lazy.nvim</a></b></summary>

```lua
require("lazy").setup({
  -- optional for icons
  { "nvim-tree/nvim-web-devicons" },

  -- optional for the `fzf` command
  {
    "junegunn/fzf",
    build = function()
      vim.fn["fzf#install"]()
    end,
  },

  {
    "linrongbin16/fzfx.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    -- specify version to avoid break changes
    version = 'v5.*',

    config = function()
      require("fzfx").setup()
    end,
  },
})
```

</details>

<details>
<summary><b>With <a href="https://github.com/wbthomason/packer.nvim">packer.nvim</a></b></summary>

```lua
return require("packer").startup(function(use)
  -- optional for icons
  use({ "nvim-tree/nvim-web-devicons" })

  -- optional for the `fzf` command
  use({
    "junegunn/fzf",
    run = function()
      vim.fn["fzf#install"]()
    end,
  })

  use({
    "linrongbin16/fzfx.nvim",

    -- specify version to avoid break changes
    version = 'v5.0.0',

    config = function()
      require("fzfx").setup()
    end,
  })
end)
```

</details>

<details>
<summary><b>With <a href="https://github.com/junegunn/vim-plug">vim-plug</a></b></summary>

```vim
call plug#begin()

" optional for icons
Plug 'nvim-tree/nvim-web-devicons'

" optional for the `fzf` command
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

" specify version to avoid break changes
Plug 'linrongbin16/fzfx.nvim', { 'tag': 'v5.0.0' }

call plug#end()

lua require('fzfx').setup()
```

</details>

## 🚀 Commands

All commands are named with prefix `Fzfx`, the sub commands e.g. the variants are usually named with below rules:

- **Basic** variant is named with `args`, accepts the following arguments as query content.
- **Visual select** variant is named with `visual`, uses visual selection as query content.
- **Cursor word** variant is named with `cword`, uses the word text under cursor as query content.
- **Put** (e.g. yank text) variant is named with `put` (just like press the `p` key), uses the yank text as query content.
- **Resume last search** variant is named with `resume`, uses the last search content as query content.

> [!NOTE]
>
> Command and sub command names can be configured, see [Configuration](#-configuration).

Below keys are binded by default:

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

> [!NOTE]
>
> Builtin keys can be configured, see [Configuration](#-configuration).

### Files & Buffers

#### `FzfxFiles` (Find Files)

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. **Unrestricted** variant is named with `unres_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(unres_)args</td>
    <td>N</td>
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(unres_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(unres_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(unres_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(unres_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### `FzfxBuffers` (Find Buffers)

1. Use `ctrl-q` to send selected lines to quickfix window and quit.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>args</td>
    <td>N</td>
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Grep

#### `FzfxLiveGrep` (Live Grep)

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. Use `--` flag to pass raw options to search command (`rg`/`grep`).
3. **Unrestricted** variant is named with `unres_` suffix.
4. **Current buffer (only)** variant is named with `buf_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(unres_/buf_)args</td>
    <td>N</td>
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(unres_/buf_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(unres_/buf_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(unres_/buf_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(unres_/buf_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### `FzfxGLiveGrep` (Live Git Grep)

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. Use `--` flag to pass raw options to search command (`git grep`).

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>args</td>
    <td>N</td>
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Git

#### `FzfxGFiles` (Find Git Files)

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. **Current directory (only)** variant is named with `cwd_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(cwd_)args</td>
    <td>N</td>
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(cwd_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(cwd_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(cwd_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(cwd_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### `FzfxGStatus` (Search Git Status, e.g. Git Changed Files)

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. **Current directory (only)** variant is named with `cwd_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(cwd_)args</td>
    <td>N</td>
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(cwd_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(cwd_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(cwd_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(cwd_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### `FzfxGBranches` (Find Git Branches)

1. Use `enter` to checkout branch.
2. **Remote branch** variant is named with `remote_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(remote_)args</td>
    <td>N</td>
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(remote_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(remote_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(remote_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(remote_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### `FzfxGCommits` (Search Git Commits)

1. Use `enter` to copy git commit SHA.
2. **Current buffer (only)** variant is named with `buf_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(buf_)args</td>
    <td>N</td>
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(buf_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(buf_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(buf_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(buf_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### `FzfxGBlame` (Search Git Blame)

1. Use `enter` to copy git commit SHA.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>args</td>
    <td>N</td>
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Lsp & Diagnostics

#### `FzfxLsp{Locations}` (Search Lsp Locations)

There're several commands (and relate LSP protocol methods):

- `FzfxLspDefinitions` ([textDocument/definition](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition)).
- `FzfxLspTypeDefinitions` ([textDocument/typeDefinition](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_typeDefinition)).
- `FzfxLspReferences` ([textDocument/references](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references)).
- `FzfxLspImplementations` ([textDocument/implementation](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_implementation)).
- `FzfxLspIncomingCalls` ([callHierarchy/incomingCalls](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#callHierarchy_incomingCalls)).
- `FzfxLspOutgoingCalls` ([callHierarchy/outgoingCalls](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#callHierarchy_outgoingCalls)).

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>args</td>
    <td>N</td>
    <td rowspan="6">Yes</td>
    <td rowspan="6">Yes</td>
  </tr>
</tbody>
</table>

#### `FzfxLspDiagnostics` (Search Diagnostics)

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. **Current buffer (only)** variant is named with `buf_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(buf_)args</td>
    <td>N</td>
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(buf_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(buf_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(buf_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(buf_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Vim

#### `FzfxCommands` (Search Vim Commands)

1. Use `enter` to input vim command.
2. **Ex(builtin) commands** variant is named with `ex_` suffix.
3. **User commands** variant is named with `user_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(ex_/user_)args</td>
    <td>N</td>
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(ex_/user_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(ex_/user_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(ex_/user_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(ex_/user_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### `FzfxKeyMaps` (Search Vim Key Mappings)

1. Use `enter` to execute vim key.
2. **Normal mode** variant is named with `n_mode_` suffix.
3. **Insert mode** variant is named with `i_mode_` suffix.
4. **Visual/select mode** variant is named with `v_mode_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(n_mode_/i_mode_/v_mode_)args</td>
    <td>N</td>
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(n_mode_/i_mode_/v_mode_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(n_mode_/i_mode_/v_mode_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(n_mode_/i_mode_/v_mode_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(n_mode_/i_mode_/v_mode_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

### Misc

#### `FzfxFileExplorer` (Search File Explorer)

> 1. **Include hidden** variant is named with `hidden_` suffix.

<table>
<thead>
  <tr>
    <th>Variant</th>
    <th>Mode</th>
    <th>Select Keys</th>
    <th>Preview Keys</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>(hidden_)args</td>
    <td>N</td>
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>(hidden_)visual</td>
    <td>V</td>
  </tr>
  <tr>
    <td>(hidden_)cword</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(hidden_)put</td>
    <td>N</td>
  </tr>
  <tr>
    <td>(hidden_)resume</td>
    <td>N</td>
  </tr>
</tbody>
</table>

## 📌 Recommended Key Mappings

<details>
<summary><i>Click here to see vim scripts</i></summary>
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
" by resume
nnoremap <space>rf :\<C-U>FzfxFilesR<CR>

" ======== live grep ========

" live grep
nnoremap <space>l :\<C-U>FzfxLiveGrep<CR>
" by visual select
xnoremap <space>l :\<C-U>FzfxLiveGrepV<CR>
" by cursor word
nnoremap <space>wl :\<C-U>FzfxLiveGrepW<CR>
" by yank text
nnoremap <space>pl :\<C-U>FzfxLiveGrepP<CR>
" by resume
nnoremap <space>rl :\<C-U>FzfxLiveGrepR<CR>

" ======== buffers ========

" buffers
nnoremap <space>bf :\<C-U>FzfxBuffers<CR>

" ======== git files ========

" git files
nnoremap <space>gf :\<C-U>FzfxGFiles<CR>

" ======== git live grep ========

" git live grep
nnoremap <space>gl :\<C-U>FzfxGLiveGrep<CR>
" by visual select
xnoremap <space>gl :\<C-U>FzfxGLiveGrepV<CR>
" by cursor word
nnoremap <space>wgl :\<C-U>FzfxGLiveGrepW<CR>
" by yank text
nnoremap <space>pgl :\<C-U>FzfxGLiveGrepP<CR>
" by resume
nnoremap <space>rgl :\<C-U>FzfxGLiveGrepR<CR>

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

" ======== lsp symbols ========

" lsp definitions
nnoremap gd :\<C-U>FzfxLspDefinitions<CR>

" lsp type definitions
nnoremap gt :\<C-U>FzfxLspTypeDefinitions<CR>

" lsp references
nnoremap gr :\<C-U>FzfxLspReferences<CR>

" lsp implementations
nnoremap gi :\<C-U>FzfxLspImplementations<CR>

" lsp incoming calls
nnoremap gI :\<C-U>FzfxLspIncomingCalls<CR>

" lsp outgoing calls
nnoremap gO :\<C-U>FzfxLspOutgoingCalls<CR>

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

<details>
<summary><i>Click here to see lua scripts</i></summary>
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
-- by resume
vim.keymap.set(
  "n",
  "<space>rf",
  "<cmd>FzfxFilesR<cr>",
  { silent = true, noremap = true, desc = "Find files by resume last" }
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
  { silent = true, noremap = true, desc = "Live grep by yank text" }
)
-- by resume
vim.keymap.set(
  "n",
  "<space>rl",
  "<cmd>FzfxLiveGrepR<cr>",
  { silent = true, noremap = true, desc = "Live grep by resume last" }
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

-- ======== git live grep ========

-- git live grep
vim.keymap.set(
  "n",
  "<space>gl",
  "<cmd>FzfxGLiveGrep<cr>",
  { silent = true, noremap = true, desc = "Git live grep" }
)
-- by visual select
vim.keymap.set(
  "x",
  "<space>gl",
  "<cmd>FzfxGLiveGrepV<cr>",
  { silent = true, noremap = true, desc = "Git live grep" }
)
-- by cursor word
vim.keymap.set(
  "n",
  "<space>wgl",
  "<cmd>FzfxGLiveGrepW<cr>",
  { silent = true, noremap = true, desc = "Git live grep by cursor word" }
)
-- by yank text
vim.keymap.set(
  "n",
  "<space>pgl",
  "<cmd>FzfxGLiveGrepP<cr>",
  { silent = true, noremap = true, desc = "Git live grep by yank text" }
)
-- by resume
vim.keymap.set(
  "n",
  "<space>rgl",
  "<cmd>FzfxGLiveGrepR<cr>",
  { silent = true, noremap = true, desc = "Git live grep by resume last" }
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

-- lsp incoming calls
vim.keymap.set(
  "n",
  "gI",
  "<cmd>FzfxLspIncomingCalls<cr>",
  { silent = true, noremap = true, desc = "Goto lsp incoming calls" }
)

-- lsp outgoing calls
vim.keymap.set(
  "n",
  "gO",
  "<cmd>FzfxLspOutgoingCalls<cr>",
  { silent = true, noremap = true, desc = "Goto lsp outgoing calls" }
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

For complete default options, please see [config.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/config.lua).

For advanced configurations, please check [Advanced Configuration](https://github.com/linrongbin16/fzfx.nvim/wiki/Advanced-Configuration).

### Create Your Own Command

Here's a minimal commands group example that implement the `ls -1` like command `FzfxLs`:

https://github.com/linrongbin16/fzfx.nvim/assets/6496887/c704e5b2-d82a-45f2-8920-adeec5d3e7c2

<details>
<summary><i>Click here to see how to configure</i></summary>

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
          provider = { "ls", "--color=always", "-1" },
        },
        include_hiddens = {
          key = "ctrl-u",
          provider = { "ls", "--color=always", "-1a" },
        },
      },
      --- @type table<string, PreviewerConfig>
      previewers = {
        filter_hiddens = {
          previewer = function(line)
            -- each line is either a folder or a file
            return vim.fn.isdirectory(line) > 0 and { "ls", "--color=always", "-lha", line }
              or { "cat", line }
          end,
          previewer_type = "command_list",
        },
        include_hiddens = {
          previewer = function(line)
            return vim.fn.isdirectory(line) > 0 and { "ls", "--color=always", "-lha", line }
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

</details>

You can also use the `require("fzfx").register("ls", {...})` api to do that.

For detailed explanation of each components, please see [A General Schema for Creating FZF Command](https://linrongbin16.github.io/fzfx.nvim/#/GenericSchema.md) and [schema.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/schema.lua).

### API References

To help easier customizing/integrating, fzfx provides below builtin modules and APIs:

- `fzfx.cfg`: Top-level configurations, e.g. directly create the `FzfxFiles`, `FzfxLiveGrep`, etc search commands. Easy to read and learn all the components used in those commands, as well as easy to copy and paste.
- `fzfx.helper`: Line-oriented helper utilities for parsing and rendering user queries and lines, since a search command is actually all about the lines in (both left and right side of) the fzf binary: generate lines, preview lines, invoke callbacks on selected lines, etc.
- `fzfx.lib`: Low-level fundamental infrastructures, fzfx use the [commons](https://github.com/linrongbin16/commons.nvim) lua library for most of the common utilities, please also refer to [commons.nvim's documentation](https://linrongbin16.github.io/commons.nvim/).

  > The **commons** lua library was originally part of the **fzfx.lib** modules, since I found they're so commonly useful that I need them for most of my Neovim plugins, I extracted them from **fzfx.lib** and come up with this **commons** lua library.

Please see [API References](https://linrongbin16.github.io/fzfx.nvim) for more details.

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
