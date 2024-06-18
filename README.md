<!-- markdownlint-disable MD001 MD013 MD034 MD033 MD051 -->

# fzfx.nvim

<p>
<a href="https://github.com/neovim/neovim/releases/v0.9.0"><img alt="require" src="https://img.shields.io/badge/require-0.9+-blue" /></a>
<a href="https://github.com/linrongbin16/commons.nvim"><img alt="commons.nvim" src="https://img.shields.io/badge/power_by-commons.nvim-pink" /></a>
<a href="https://luarocks.org/modules/linrongbin16/fzfx.nvim"><img alt="luarocks" src="https://img.shields.io/luarocks/v/linrongbin16/fzfx.nvim" /></a>
<a href="https://github.com/linrongbin16/fzfx.nvim/actions/workflows/ci.yml"><img alt="ci.yml" src="https://img.shields.io/github/actions/workflow/status/linrongbin16/fzfx.nvim/ci.yml?label=ci" /></a>
<a href="https://app.codecov.io/github/linrongbin16/fzfx.nvim"><img alt="codecov" src="https://img.shields.io/codecov/c/github/linrongbin16/fzfx.nvim/main?label=codecov" /></a>
</p>

<p align="center"><i>
A Neovim fuzzy finder that updates on every keystroke.
</i></p>

https://github.com/linrongbin16/fzfx.nvim/assets/6496887/b5e2b0dc-4dd6-4c18-b1da-f54419efbba3

> Search `require("fzfx` with rg's `-g *spec.lua -F` option.

## 📖 Table of contents

- [Features](#-features)
- [Requirements](#-requirements)
  - [For Windows](#for-windows)
- [Install](#-install)
- [Usage](#-usage)
  - [Files & Buffers](#files--buffers)
  - [Grep](#grep)
  - [Git](#git)
  - [Lsp & Diagnostics](#lsp--diagnostics)
  - [Vim](#vim)
  - [Misc](#misc)
- [Recommended Key Mappings](#-recommended-key-mappings)
- [Configuration](#-configuration)
  - [Feature Flags](#feature-flags)
  - [Create Your Own Command](#create-your-own-command)
  - [API References](#api-references)
- [Known Issues](#-known-issues)
- [Alternatives](#-alternatives)
- [Development](#-development)
- [Contribute](#-contribute)

## ✨ Features

- Colors/icons, Windows and modern Neovim features support.
- Updates on every keystroke of user query and selection.
- Multiple variants to avoid manual input:
  - Search by visual select.
  - Search by cursor word.
  - Search by yank text.
  - Search by resume last search.
- Multiple data sources to avoid restart search flow:
  - Exclude or include hiddens/ignores when searching files.
  - Local or remote when searching git branches.
  - Whole workspace or current buffer only when searching diagnostics.
  - ...
- And a lot more.

> Please see [Demo](https://github.com/linrongbin16/fzfx.nvim/wiki/Demo) for more use cases.

## ✅ Requirements

> [!NOTE]
>
> This plugin keeps up with the latest Neovim stable version, supports until the last legacy version to reduce maintenance effort.
>
> For example at the time of writing, 2024-06-11, stable is 0.10, last legacy is 0.9, and this plugin supports v0.9+.

- Neovim &ge; 0.9.
- [fzf](https://github.com/junegunn/fzf).
- [curl](https://man7.org/linux/man-pages/man1/curl.1.html) (for query fzf status or update preview label).
- [nerd-fonts](https://www.nerdfonts.com/) (**optional** for icons).
- [rg](https://github.com/BurntSushi/ripgrep) (**optional** for live grep, by default use [grep](https://man7.org/linux/man-pages/man1/grep.1.html)).
- [fd](https://github.com/sharkdp/fd) (**optional** for find files, by default use [find](https://man7.org/linux/man-pages/man1/find.1.html)).
- [bat](https://github.com/sharkdp/bat) (**optional** for preview files, by default use [cat](https://man7.org/linux/man-pages/man1/cat.1.html)).
- [git](https://git-scm.com/) (**mandatory** for git diff, show, blame).
- [delta](https://github.com/dandavison/delta) (**optional** for preview git diff, show, blame).
- [lsd](https://github.com/lsd-rs/lsd)/[eza](https://github.com/eza-community/eza) (**optional** for file explorer, by default use [ls](https://man7.org/linux/man-pages/man1/ls.1.html)).

### For Windows

Windows users will have to install the linux shell environment and core utils, since basic shell commands such as `echo`, `mkdir` are internally required.

<details>
<summary><i>Click here to see how to install linux commands</i></summary>
<br/>

There're many ways to install portable linux shell and core utils on Windows, but personally I would recommend below two methods:

#### [Git for Windows](https://git-scm.com/download/win)

Install with the below 3 options:

- In **Select Components**, select **Associate .sh files to be run with Bash**.

  <img alt="install-windows-git-step1.jpg" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/495d894b-49e4-4c58-b74e-507920a11048" width="70%" />

- In **Adjusting your PATH environment**, select **Use Git and optional Unix tools from the Command Prompt**.

  <img alt="install-windows-git-step2.jpg" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/b4f477ad-4436-4027-baa6-8320806801e2" width="70%" />

- In **Configuring the terminal emulator to use with Git Bash**, select **Use Windows's default console window**.

  <img alt="install-windows-git-step3.jpg" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/f9174330-ca58-4117-a58d-9e84826c13d1" width="70%" />

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

> Note: Install the rust rewritten [uutils-coreutils](https://github.com/uutils/coreutils) instead of GNU [coreutils](https://www.gnu.org/software/coreutils/), some GNU commands (for example `ls`) is actually broken on Windows 10 x86_64 PC.

#### Fix conflicts between embedded commands in `C:\Windows\System32` and portable linux commands

Windows actually already provide some commands (`find.exe`, `bash.exe`) in `C:\Windows\System32` (or `%SystemRoot%\system32`), while they are not the linux commands they are named after, but could override our installations. To fix this issue, we could prioritize the git or scoop environment variables in `%PATH%`.

<img alt="windows-path" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/5296429b-daae-40f6-be16-6c065ef7bf05" width="70%" />

</details>

## 📦 Install

> [!NOTE]
>
> You can specify the plugin version/tag (i.e. `v5.*`) to avoid break changes between major versions!

<details>
<summary><b>With <a href="https://github.com/folke/lazy.nvim">lazy.nvim</a></b></summary>

```lua
require("lazy").setup({
  -- optional for icons
  { "nvim-tree/nvim-web-devicons" },

  -- optional for the 'fzf' command
  {
    "junegunn/fzf",
    build = function()
      vim.fn["fzf#install"]()
    end,
  },

  {
    "linrongbin16/fzfx.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", 'junegunn/fzf' },

    -- specify version to avoid break changes
    -- version = 'v5.*',

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

  -- optional for the 'fzf' command
  use({
    "junegunn/fzf",
    run = function()
      vim.fn["fzf#install"]()
    end,
  })

  use({
    "linrongbin16/fzfx.nvim",

    -- specify version to avoid break changes
    -- version = 'v5.0.0',

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

" optional for the 'fzf' command
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

" specify version to avoid break changes
Plug 'linrongbin16/fzfx.nvim' ", { 'tag': 'v5.0.0' }

call plug#end()

lua require('fzfx').setup()
```

</details>

## 🚀 Usage

There're multiple commands provided, named with prefix `Fzfx`. The sub commands indicates the user query's input method, (i.e. the variants) named with below rules:

- **Basic** variant is named with `args`, accepts the following arguments as query content.
- **Visual select** variant is named with `visual`, uses visual selection as query content.
- **Cursor word** variant is named with `cword`, uses the word text under cursor as query content.
- **Put** (i.e. yank text) variant is named with `put` (just like press the `p` key), uses the yank text as query content.
- **Resume last search** variant is named with `resume`, uses the last search content as query content.

> [!NOTE]
>
> The `args` sub command can be omitted, for example `:FzfxFiles<CR>` is equivalent to `:FzfxFiles args<CR>`.
>
> To specify query text, for example `asdf`, you will have to type `:FzfxFiles args asdf<CR>`.

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

### Files & Buffers

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code>FzfxFiles</code>
      </td>
      <td>
        <details>
          <summary>Find files.</summary>
          <small>
            <ol>
              <li>
                Use <code>ctrl-q</code> to send selected lines to quickfix
                window and quit.
              </li>
              <li>
                <b>Unrestricted</b> variant is named with
                <code>unres_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(unres_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">Yes</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(unres_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(unres_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(unres_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(unres_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td>
        <code>FzfxBuffers</code>
      </td>
      <td>
        <details>
          <summary>Find buffers.</summary>
          <small>
            <ol>
              <li>
                Use <code>ctrl-q</code> to send selected lines to quickfix
                window and quit.
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="5">Yes</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td>
        <code>FzfxGFiles</code>
      </td>
      <td>
        <details>
          <summary>Find git files.</summary>
          <small>
            <ol>
              <li>
                Use <code>ctrl-q</code> to send selected lines to quickfix
                window and quit.
              </li>
              <li>
                <b>Current directory (only)</b> variant is named with
                <code>cwd_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(cwd_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">Yes</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(cwd_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(cwd_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(cwd_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(cwd_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
  </tbody>
</table>

### Grep

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>FzfxLiveGrep</code></td>
      <td>
        <details>
          <summary>Live grep.</summary>
          <small>
            <ol>
              <li>
                Use <code>ctrl-q</code> to send selected lines to quickfix
                window and quit.
              </li>
              <li>
                Use <code>--</code> flag to pass raw options to search command
                (<code>rg</code>/<code>grep</code>).
              </li>
              <li>
                <b>Unrestricted</b> variant is named with
                <code>unres_</code> suffix.
              </li>
              <li>
                <b>Current buffer (only)</b> variant is named with
                <code>buf_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(unres_/buf_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">Yes</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(unres_/buf_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(unres_/buf_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(unres_/buf_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(unres_/buf_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxBufLiveGrep</code></td>
      <td>
        <details>
          <summary>Live grep only on current buffer.</summary>
          <small>
            <ol>
              <li>
                This command has the same functionality with
                <code>FzfxLiveGrep</code> currently buffer variant
                (<code>buf_</code>), while the file name is removed for better
                user view.
              </li>
              <li>
                Use <code>ctrl-q</code> to send selected lines to quickfix
                window and quit.
              </li>
              <li>
                Use <code>--</code> flag to pass raw options to search command
                (<code>rg</code>/<code>grep</code>).
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="5">Yes</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxGLiveGrep</code></td>
      <td>
        <details>
          <summary>Live grep with git grep.</summary>
          <small>
            <ol>
              <li>
                Use <code>ctrl-q</code> to send selected lines to quickfix
                window and quit.
              </li>
              <li>
                Use <code>--</code> flag to pass raw options to search command
                (<code>git grep</code>).
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="5">Yes</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
  </tbody>
</table>

### Git

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>FzfxGStatus</code></td>
      <td>
        <details>
          <summary>Search git status (changed files).</summary>
          <small>
            <ol>
              <li>
                Use <code>ctrl-q</code> to send selected lines to quickfix
                window and quit.
              </li>
              <li>
                <b>Current directory (only)</b> variant is named with
                <code>cwd_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(cwd_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">Yes</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(cwd_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(cwd_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(cwd_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(cwd_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxGBranches</code></td>
      <td>
        <details>
          <summary>Search git branches.</summary>
          <small>
            <ol>
              <li>Use <code>enter</code> to checkout branch.</li>
              <li>
                <b>Remote branch</b> variant is named with
                <code>remote_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(remote_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">No</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(remote_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(remote_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(remote_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(remote_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxGCommits</code></td>
      <td>
        <details>
          <summary>Search git commits.</summary>
          <small>
            <ol>
              <li>Use <code>enter</code> to copy git commit SHA.</li>
              <li>
                <b>Current buffer</b> variant is named with
                <code>buf_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(buf_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">No</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(buf_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(buf_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(buf_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(buf_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxGBlame</code></td>
      <td>
        <details>
          <summary>Search git blame.</summary>
          <small>
            <ol>
              <li>Use <code>enter</code> to copy git commit SHA.</li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="5">No</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
  </tbody>
</table>

### Lsp & Diagnostics

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>FzfxLspDefinitions</code></td>
      <td>
        <details>
          <summary>Search definitions.</summary>
          <small>
            <ol>
              <li>
                The <code>args</code> variant always use cursor word as query
                content (not command arguments), because the scenario is
                navigating symbols, i.e. go to definitions.
              </li>
              <li>
                Use protocol
                <a
                  href="https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition"
                  >textDocument/definition</a
                >.
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="6">Yes</td>
                  <td rowspan="6">Yes</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxLspTypeDefinitions</code></td>
      <td>
        <details>
          <summary>Search type definitions.</summary>
          <small>
            <ol>
              <li>
                The <code>args</code> variant always use cursor word as query
                content (not command arguments), because the scenario is
                navigating symbols, i.e. go to type definitions.
              </li>
              <li>
                Use protocol
                <a
                  href="https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_typeDefinition"
                  >textDocument/typeDefinition</a
                >.
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="6">Yes</td>
                  <td rowspan="6">Yes</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxLspImplementations</code></td>
      <td>
        <details>
          <summary>Search implementations.</summary>
          <small>
            <ol>
              <li>
                The <code>args</code> variant always use cursor word as query
                content (not command arguments), because the scenario is
                navigating symbols, i.e. go to implementations.
              </li>
              <li>
                Use protocol
                <a
                  href="https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_implementation"
                  >textDocument/implementation</a
                >.
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="6">Yes</td>
                  <td rowspan="6">Yes</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxLspReferences</code></td>
      <td>
        <details>
          <summary>Search references.</summary>
          <small>
            <ol>
              <li>
                The <code>args</code> variant always use cursor word as query
                content (not command arguments), because the scenario is
                navigating symbols, i.e. go to references.
              </li>
              <li>
                Use protocol
                <a
                  href="https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references"
                  >textDocument/references</a
                >.
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="6">Yes</td>
                  <td rowspan="6">Yes</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxLspIncomingCalls</code></td>
      <td>
        <details>
          <summary>Search incoming calls.</summary>
          <small>
            <ol>
              <li>
                The <code>args</code> variant always use cursor word as query
                content (not command arguments), because the scenario is
                navigating symbols, i.e. go to incoming calls.
              </li>
              <li>
                Use protocol
                <a
                  href="https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#callHierarchy_incomingCalls"
                  >callHierarchy/incomingCalls</a
                >.
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="6">Yes</td>
                  <td rowspan="6">Yes</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxLspOutgoingCalls</code></td>
      <td>
        <details>
          <summary>Search outgoing calls.</summary>
          <small>
            <ol>
              <li>
                The <code>args</code> variant always use cursor word as query
                content (not command arguments), because the scenario is
                navigating symbols, i.e. go to outgoing calls.
              </li>
              <li>
                Use protocol
                <a
                  href="https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#callHierarchy_outgoingCalls"
                  >callHierarchy/outgoingCalls</a
                >.
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="6">Yes</td>
                  <td rowspan="6">Yes</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxLspDiagnostics</code></td>
      <td>
        <details>
          <summary>Search diagnostics.</summary>
          <small>
            <ol>
              <li>
                Use <code>ctrl-q</code> to send selected lines to quickfix
                window and quit.
              </li>
              <li>
                <b>Current buffer (only)</b> variant is named with
                <code>buf_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(buf_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">Yes</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(buf_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(buf_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(buf_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(buf_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
  </tbody>
</table>

### Vim

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>FzfxCommands</code></td>
      <td>
        <details>
          <summary>Search vim commands.</summary>
          <small>
            <ol>
              <li>Use <code>enter</code> to input command.</li>
              <li>
                <b>Ex (builtin) commands</b> variant is named with
                <code>ex_</code> suffix.
              </li>
              <li>
                <b>User commands</b> variant is named with
                <code>user_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(ex_/user_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">No</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(ex_/user_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(ex_/user_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(ex_/user_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(ex_/user_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxKeyMaps</code></td>
      <td>
        <details>
          <summary>Search vim key mappings.</summary>
          <small>
            <ol>
              <li>Use <code>enter</code> to execute key mapping.</li>
              <li>
                <b>Normal mode</b> variant is named with
                <code>n_mode_</code> suffix.
              </li>
              <li>
                <b>Insert mode</b> variant is named with
                <code>i_mode_</code> suffix.
              </li>
              <li>
                <b>Visual/select mode</b> variant is named with
                <code>v_mode_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(n_mode_/i_mode_/v_mode_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">No</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(n_mode_/i_mode_/v_mode_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(n_mode_/i_mode_/v_mode_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(n_mode_/i_mode_/v_mode_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(n_mode_/i_mode_/v_mode_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
    <tr>
      <td><code>FzfxMarks</code></td>
      <td>
        <details>
          <summary>Search vim marks.</summary>
          <small>
            <ol>
              <li>
                Use <code>ctrl-q</code> to send selected lines to quickfix
                window and quit.
              </li>
            </ol>
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
                  <td><code>args</code></td>
                  <td>N</td>
                  <td rowspan="5">No</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
  </tbody>
</table>

### Misc

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>FzfxFileExplorer</code></td>
      <td>
        <details>
          <summary>Navigate around file explorer.</summary>
          <small>
            <ol>
              <li>
                <b>Include hidden</b> variant is named with
                <code>hidden_</code> suffix.
              </li>
            </ol>
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
                  <td><code>(hidden_)args</code></td>
                  <td>N</td>
                  <td rowspan="5">Yes</td>
                  <td rowspan="5">Yes</td>
                </tr>
                <tr>
                  <td><code>(hidden_)visual</code></td>
                  <td>V</td>
                </tr>
                <tr>
                  <td><code>(hidden_)cword</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(hidden_)put</code></td>
                  <td>N</td>
                </tr>
                <tr>
                  <td><code>(hidden_)resume</code></td>
                  <td>N</td>
                </tr>
              </tbody>
            </table>
          </small>
        </details>
      </td>
    </tr>
  </tbody>
</table>

## 📌 Recommended Key Mappings

<details>
<summary><i>Click here to see vim scripts</i></summary>
<br/>

```vim
" ======== files ========

" by args
nnoremap <space>f :\<C-U>FzfxFiles<CR>
" by visual select
xnoremap <space>f :\<C-U>FzfxFiles visual<CR>
" by cursor word
nnoremap <space>wf :\<C-U>FzfxFiles cword<CR>
" by yank text
nnoremap <space>pf :\<C-U>FzfxFiles put<CR>
" by resume
nnoremap <space>rf :\<C-U>FzfxFiles resume<CR>

" ======== live grep ========

" by args
nnoremap <space>l :\<C-U>FzfxLiveGrep<CR>
" by visual select
xnoremap <space>l :\<C-U>FzfxLiveGrep visual<CR>
" by cursor word
nnoremap <space>wl :\<C-U>FzfxLiveGrep cword<CR>
" by yank text
nnoremap <space>pl :\<C-U>FzfxLiveGrep put<CR>
" by resume
nnoremap <space>rl :\<C-U>FzfxLiveGrep resume<CR>

" ======== buffers ========

" by args
nnoremap <space>bf :\<C-U>FzfxBuffers<CR>

" ======== git files ========

" by args
nnoremap <space>gf :\<C-U>FzfxGFiles<CR>

" ======== git live grep ========

" by args
nnoremap <space>gl :\<C-U>FzfxGLiveGrep<CR>
" by visual select
xnoremap <space>gl :\<C-U>FzfxGLiveGrep visual<CR>
" by cursor word
nnoremap <space>wgl :\<C-U>FzfxGLiveGrep cword<CR>
" by yank text
nnoremap <space>pgl :\<C-U>FzfxGLiveGrep put<CR>
" by resume
nnoremap <space>rgl :\<C-U>FzfxGLiveGrep resume<CR>

" ======== git changed files (status) ========

" by args
nnoremap <space>gs :\<C-U>FzfxGStatus<CR>

" ======== git branches ========

" by args
nnoremap <space>br :\<C-U>FzfxGBranches<CR>

" ======== git commits ========

" by args
nnoremap <space>gc :\<C-U>FzfxGCommits<CR>

" ======== git blame ========

" by args
nnoremap <space>gb :\<C-U>FzfxGBlame<CR>

" ======== lsp diagnostics ========

" by args
nnoremap <space>dg :\<C-U>FzfxLspDiagnostics<CR>

" ======== lsp locations ========

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

" by args
nnoremap <space>cm :\<C-U>FzfxCommands<CR>

" ======== vim key maps ========

" by args
nnoremap <space>km :\<C-U>FzfxKeyMaps<CR>

" ======== vim marks ========

" by args
nnoremap <space>mk :\<C-U>FzfxMarks<CR>

" ======== file explorer ========

" by args
nnoremap <space>xp :\<C-U>FzfxFileExplorer<CR>
```

</details>

<details>
<summary><i>Click here to see lua scripts</i></summary>
<br/>

```lua
-- ======== files ========

-- by args
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
  "<cmd>FzfxFiles visual<CR>",
  { silent = true, noremap = true, desc = "Find files" }
)
-- by cursor word
vim.keymap.set(
  "n",
  "<space>wf",
  "<cmd>FzfxFiles cword<cr>",
  { silent = true, noremap = true, desc = "Find files by cursor word" }
)
-- by yank text
vim.keymap.set(
  "n",
  "<space>pf",
  "<cmd>FzfxFiles put<cr>",
  { silent = true, noremap = true, desc = "Find files by yank text" }
)
-- by resume
vim.keymap.set(
  "n",
  "<space>rf",
  "<cmd>FzfxFiles resume<cr>",
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
  "<cmd>FzfxLiveGrep visual<cr>",
  { silent = true, noremap = true, desc = "Live grep" }
)
-- by cursor word
vim.keymap.set(
  "n",
  "<space>wl",
  "<cmd>FzfxLiveGrep cword<cr>",
  { silent = true, noremap = true, desc = "Live grep by cursor word" }
)
-- by yank text
vim.keymap.set(
  "n",
  "<space>pl",
  "<cmd>FzfxLiveGrep put<cr>",
  { silent = true, noremap = true, desc = "Live grep by yank text" }
)
-- by resume
vim.keymap.set(
  "n",
  "<space>rl",
  "<cmd>FzfxLiveGrep resume<cr>",
  { silent = true, noremap = true, desc = "Live grep by resume last" }
)

-- ======== buffers ========

-- by args
vim.keymap.set(
  "n",
  "<space>bf",
  "<cmd>FzfxBuffers<cr>",
  { silent = true, noremap = true, desc = "Find buffers" }
)

-- ======== git files ========

-- by args
vim.keymap.set(
  "n",
  "<space>gf",
  "<cmd>FzfxGFiles<cr>",
  { silent = true, noremap = true, desc = "Find git files" }
)

-- ======== git live grep ========

-- by args
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
  "<cmd>FzfxGLiveGrep visual<cr>",
  { silent = true, noremap = true, desc = "Git live grep" }
)
-- by cursor word
vim.keymap.set(
  "n",
  "<space>wgl",
  "<cmd>FzfxGLiveGrep cword<cr>",
  { silent = true, noremap = true, desc = "Git live grep by cursor word" }
)
-- by yank text
vim.keymap.set(
  "n",
  "<space>pgl",
  "<cmd>FzfxGLiveGrep put<cr>",
  { silent = true, noremap = true, desc = "Git live grep by yank text" }
)
-- by resume
vim.keymap.set(
  "n",
  "<space>rgl",
  "<cmd>FzfxGLiveGrep resume<cr>",
  { silent = true, noremap = true, desc = "Git live grep by resume last" }
)

-- ======== git changed files (status) ========

-- by args
vim.keymap.set(
  "n",
  "<space>gs",
  "<cmd>FzfxGStatus<cr>",
  { silent = true, noremap = true, desc = "Find git changed files (status)" }
)

-- ======== git branches ========

-- by args
vim.keymap.set(
  "n",
  "<space>br",
  "<cmd>FzfxGBranches<cr>",
  { silent = true, noremap = true, desc = "Search git branches" }
)

-- ======== git commits ========

-- by args
vim.keymap.set(
  "n",
  "<space>gc",
  "<cmd>FzfxGCommits<cr>",
  { silent = true, noremap = true, desc = "Search git commits" }
)

-- ======== git blame ========

-- by args
vim.keymap.set(
  "n",
  "<space>gb",
  "<cmd>FzfxGBlame<cr>",
  { silent = true, noremap = true, desc = "Search git blame" }
)

-- ======== lsp diagnostics ========

-- by args
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

-- by args
vim.keymap.set(
  "n",
  "<space>cm",
  "<cmd>FzfxCommands<cr>",
  { silent = true, noremap = true, desc = "Search vim commands" }
)

-- ======== vim key maps ========

-- by args
vim.keymap.set(
  "n",
  "<space>km",
  "<cmd>FzfxKeyMaps<cr>",
  { silent = true, noremap = true, desc = "Search vim keymaps" }
)

-- ======== vim marks ========

-- by args
vim.keymap.set(
  "n",
  "<space>mk",
  "<cmd>FzfxMarks<cr>",
  { silent = true, noremap = true, desc = "Search vim marks" }
)

-- ======== file explorer ========

-- by args
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
require('fzfx').setup(opts)
```

The `opts` is an optional lua table that override the default options.

For complete default options, please see [config.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/config.lua).

For advanced configurations, please check [Advanced Configuration](https://github.com/linrongbin16/fzfx.nvim/wiki/Advanced-Configuration).

### Feature Flags

To enable/disable some features, please define below global variables before setup this plugin:

- `vim.g.fzfx_disable_buffer_previewer`: Disable nvim buffer for previewing file contents, use fzf builtin preview window via `bat` with best performance.

   <details>
   <summary><i>Click here to see how to configure</i></summary>

  ```vim
  " vim scripts
  let g:fzfx_disable_buffer_previewer = 1 " or v:true
  ```

  ```lua
  -- lua scripts
  vim.g.fzfx_disable_buffer_previewer = 1 -- or true
  ```

   </details>

### Create Your Own Command

Here's a minimal example that implement the `ls -1` like `FzfxLs` command:

https://github.com/linrongbin16/fzfx.nvim/assets/6496887/c704e5b2-d82a-45f2-8920-adeec5d3e7c2

<details>
<summary><i>Click here to see how to configure</i></summary>

```lua
require("fzfx").setup()

require("fzfx").register("ls", {
  --- @type CommandConfig
  command = {
    name = "FzfxLs",
    desc = "File Explorer (ls -1)",
  },
  variants = {
    {
      name = "args",
      feed = "args",
      default_provider = "filter_hiddens",
    },
    {
      name = "hidden_args",
      feed = "args",
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
})
```

</details>

First setup this plugin, then use `require("fzfx").register(name, opts})` api to create your own searching command.

For detailed explanation of each components, please see [A Generic Schema for Creating FZF Command](https://linrongbin16.github.io/fzfx.nvim/#/GenericSchema) and [schema.lua](https://github.com/linrongbin16/fzfx.nvim/blob/main/lua/fzfx/schema.lua).

### API References

To help easier customizing/integrating, fzfx provides below builtin modules and APIs:

- `fzfx.cfg`: Top-level configurations, i.e. directly create the `FzfxFiles`, `FzfxLiveGrep`, etc search commands. Easy to read and learn all the components used in those commands, as well as easy to copy and paste.
- `fzfx.helper`: Line-oriented helper utilities for parsing and rendering user queries and lines, since a search command is actually all about the lines in (both left and right side of) the fzf binary: generate lines, preview lines, invoke callbacks on selected lines, etc.
- `fzfx.lib`: Low-level fundamental infrastructures, fzfx use the [commons](https://github.com/linrongbin16/commons.nvim) lua library for most of the common utilities, please also refer to [commons.nvim's documentation](https://linrongbin16.github.io/commons.nvim/).

  > The **commons** library was originally part of **fzfx.lib**, since I found they're so commonly used that I almost need them for every of my Neovim plugins, I extracted them from fzfx and build up this library.

Please see [API References](https://linrongbin16.github.io/fzfx.nvim/#/ApiReferences) for more details.

## 🪲 Known Issues

Please see [Known Issues](https://linrongbin16.github.io/fzfx.nvim/#/KnownIssues) if you encountered any issue.

## 🍀 Alternatives

- [fzf.vim](https://github.com/junegunn/fzf.vim): Things you can do with [fzf](https://github.com/junegunn/fzf) and Vim.
- [fzf-lua](https://github.com/ibhagwan/fzf-lua): Improved fzf.vim written in lua.
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim): Find, Filter, Preview, Pick. All lua, all the time.

## ✏️ Development

To develop the project and make PR, please setup with:

- [lua_ls](https://github.com/LuaLS/lua-language-server).
- [stylua](https://github.com/JohnnyMorganz/StyLua).
- [selene](https://github.com/Kampfkarren/selene).

To run unit tests, please install below dependencies:

- [vusted](https://github.com/notomo/vusted).

Then test with `vusted ./spec`.

## 🎁 Contribute

Please open [issue](https://github.com/linrongbin16/fzfx.nvim/issues)/[PR](https://github.com/linrongbin16/fzfx.nvim/pulls) for anything about fzfx.nvim.

Like fzfx.nvim? Consider

[![Github Sponsor](https://img.shields.io/badge/-Sponsor%20Me%20on%20Github-magenta?logo=github&logoColor=white)](https://github.com/sponsors/linrongbin16)
[![Wechat Pay](https://img.shields.io/badge/-Tip%20Me%20on%20WeChat-brightgreen?logo=wechat&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
[![Alipay](https://img.shields.io/badge/-Tip%20Me%20on%20Alipay-blue?logo=alipay&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
