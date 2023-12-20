<!-- markdownlint-disable MD001 MD013 MD034 MD033 MD051 -->

# fzfx.nvim

<p align="center">
<a href="https://github.com/neovim/neovim/releases/v0.7.0"><img alt="Neovim" src="https://img.shields.io/badge/Neovim-v0.7+-57A143?logo=neovim&logoColor=57A143" /></a>
<a href="https://github.com/linrongbin16/commons.nvim"><img alt="commons.nvim" src="https://custom-icon-badges.demolab.com/badge/Powered_by-commons.nvim-teal?logo=heart&logoColor=fff&labelColor=deeppink" /></a>
<a href="https://luarocks.org/modules/linrongbin16/fzfx.nvim"><img alt="luarocks" src="https://custom-icon-badges.demolab.com/luarocks/v/linrongbin16/fzfx.nvim?label=LuaRocks&labelColor=063B70&logo=tag&logoColor=fff&color=008B8B" /></a>
<a href="https://github.com/linrongbin16/fzfx.nvim/actions/workflows/ci.yml"><img alt="ci.yml" src="https://img.shields.io/github/actions/workflow/status/linrongbin16/fzfx.nvim/ci.yml?label=GitHub%20CI&labelColor=181717&logo=github&logoColor=fff" /></a>
<a href="https://app.codecov.io/github/linrongbin16/fzfx.nvim"><img alt="codecov" src="https://img.shields.io/codecov/c/github/linrongbin16/fzfx.nvim?logo=codecov&logoColor=F01F7A&label=Codecov" /></a>
</p>

<p align="center"><i>
FZF-based fuzzy finder running on a dynamic engine that parsing user query and selection on every keystroke.
</i></p>

https://github.com/linrongbin16/fzfx.nvim/assets/6496887/47b03150-14e3-479a-b1af-1b2995659403

<!-- gif
![FzfxLiveGrep](https://github.com/linrongbin16/fzfx.nvim/assets/6496887/be8a7a52-c254-42ff-ad6d-93ba637c4f09)
-->

> Search `fzfx` with rg's `-g *spec.lua` option.

## 📖 Table of contents

- [Feature](#-feature)
- [Requirement](#-requirement)
  - [Windows](#windows)
  - [Whitespace Escaping Issue](#whitespace-escaping-issue)
- [Install](#-install)
  - [vim-plug](#vim-plug)
  - [packer.nvim](#packernvim)
  - [lazy.nvim](#lazynvim)
- [Commands](#-commands)
- [Recommended Key Mappings](#-recommended-key-mappings)
- [Configuration](#-configuration)
  - [Create Your Own Command](#create-your-own-command)
  - [API References](#api-references)
- [Credit](#-credit)
- [Development](#-development)
- [Contribute](#-contribute)

## ✨ Feature

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

## ✅ Requirement

- Neovim &ge; v0.7.0.
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

Commands are named following below rules:

- All commands are named with prefix `Fzfx`.
- The main command name has no suffix.
- **Visual select** variant is named with `V` suffix.
- **Cursor word** variant is named with `W` suffix.
- **Yank text** variant is named with `P` suffix (just like press the `p` key).
- **Resume last search** variant is named with `R` suffix.

> Note: command names can be configured, see [Configuration](#-configuration).

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

> Note: builtin keys can be configured, see [Configuration](#-configuration).

<details>
<summary><b>Files & Buffers</b></summary>

#### Files

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. **Unrestricted** variant is named with `U` suffix.

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
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
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
    <td>FzfxFiles(U)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### Buffers

1. Use `ctrl-q` to send selected lines to quickfix window and quit.

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
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
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
    <td>FzfxBuffersR</td>
    <td>N</td>
  </tr>
</tbody>
</table>

</details>

<details>
<summary><b>Grep</b></summary>

#### Live Grep

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. Use `--` flag to pass raw options to search command (`rg`/`grep`).
3. **Unrestricted** variant is named with `U` suffix.
4. **Current buffer** variant is named with `B` suffix.

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
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
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
  <tr>
    <td>FzfxLiveGrep(B/U)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### Git Live Grep

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. Use `--` flag to pass raw options to search command (`git grep`).

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
    <td>FzfxGLiveGrep</td>
    <td>N</td>
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
  </tr>
  <tr>
    <td>FzfxGLiveGrepV</td>
    <td>V</td>
  </tr>
  <tr>
    <td>FzfxGLiveGrepW</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxGLiveGrepP</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxGLiveGrepR</td>
    <td>N</td>
  </tr>
</tbody>
</table>

</details>

<details>
<summary><b>Git</b></summary>

#### Git Files

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. **Current directory** variant is named with `C` suffix.

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
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
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
  <tr>
    <td>FzfxGFiles(C)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### Git Status (Changed Files)

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. **Current directory** variant is named with `C` suffix.

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
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
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
  <tr>
    <td>FzfxGStatus(C)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### Git Branches

1. Use `enter` to checkout branch.
2. **Remote branch** variant is named with `R` suffix.

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
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
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
    <td>FzfxGBranches(R)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### Git Commits

1. Use `enter` to copy git commit SHA.
2. **Current buffer** variant is named with `B` suffix.

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
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
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
    <td>FzfxGCommits(B)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### Git Blame

1. Use `enter` to copy git commit SHA.

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
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
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
  <tr>
    <td>FzfxGBlameR</td>
    <td>N</td>
  </tr>
</tbody>
</table>

</details>

<details>
<summary><b>Lsp & Diagnostics</b></summary>

#### Lsp Locations

Lsp methods:

- FzfxLspDefinitions: "textDocument/definition".
- FzfxLspTypeDefinitions: "textDocument/type_definition".
- FzfxLspReferences: "textDocument/references".
- FzfxLspImplementations: "textDocument/implementation".
- FzfxLspIncomingCalls: "textDocument/incomingCalls".
- FzfxLspOutgoingCalls: "textDocument/outgoingCalls".

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
    <td rowspan="6">Yes</td>
    <td rowspan="6">Yes</td>
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
  <tr>
    <td>FzfxLspIncomingCalls</td>
    <td>N</td>
  </tr>
  <tr>
    <td>FzfxLspOutgoingCalls</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### Diagnostics

1. Use `ctrl-q` to send selected lines to quickfix window and quit.
2. **Current buffer** variant is named with `B` suffix.

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
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
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
  <tr>
    <td>FzfxLspDiagnostics(B)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

</details>

<details>
<summary><b>Vim</b></summary>

#### Commands

1. Use `enter` to input vim command.
2. **Ex(builtin) commands** variant is named with `E` suffix.
3. **User commands** variant is named with `U` suffix.

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
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
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
  <tr>
    <td>FzfxCommands(E/U)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

#### Key Maps

1. Use `enter` to execute vim key.
2. **Normal mode** variant is named with `N` suffix.
3. **Insert mode** variant is named with `I` suffix.
4. **Visual/select mode** variant is named with `V` suffix.

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
    <td rowspan="5">No</td>
    <td rowspan="5">Yes</td>
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
  <tr>
    <td>FzfxKeyMaps(N/I/V)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

</details>

<details>
<summary><b>Misc</b></summary>

#### File Explorer

> 1. **Unrestricted** variant is named with `U` suffix.

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
    <td rowspan="5">Yes</td>
    <td rowspan="5">Yes</td>
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
  <tr>
    <td>FzfxFileExplorer(U)R</td>
    <td>N</td>
  </tr>
</tbody>
</table>

</details>

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

For detailed explanation of each components, please see [A General Schema for Creating FZF Command](https://github.com/linrongbin16/fzfx.nvim/wiki/A-General-Schema-for-Creating-FZF-Command) and [schema.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/schema.lua).

### API References

To help easier customizing/integrating, fzfx provides below builtin modules and APIs:

- `fzfx.cfg`: Top-level configurations, e.g. directly create the `FzfxFiles`, `FzfxLiveGrep`, etc search commands. Easy to read and learn all the components used in those commands, as well as easy to copy and paste.
- `fzfx.helper`: Middle-level line-oriented helpers for parsing and rendering queries/lines required in all scenarios, a search command is actually all about the lines in (both left and right side of) fzf binary: generate lines, preview lines, invoke callbacks on selected lines, etc.
- `fzfx.lib`: Low-level fundamental infrastructures: cross-platform (Windows/Unix/Linux) and different Neovim versions API, file IO & paths, json, strings, numbers, lua tables/lists, colors, running child process & stdio, etc.

The `helper` and `lib` APIs are supposed to be stable and tested (except those starting with underline `_`, which are exposed for unit tests), please see [API References](https://linrongbin16.github.io/fzfx.nvim) for details.

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
