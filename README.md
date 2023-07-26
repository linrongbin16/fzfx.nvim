<!-- markdownlint-disable MD013 MD034 -->

# fzfx.nvim

[![Neovim-v0.8.0](https://img.shields.io/badge/Neovim-v0.8.0-blueviolet.svg?style=flat-square&logo=Neovim&logoColor=green)](https://github.com/neovim/neovim/releases/tag/v0.8.0)
[![License](https://img.shields.io/github/license/linrongbin16/lin.nvim?style=flat-square&logo=GNU)](https://github.com/linrongbin16/lin.nvim/blob/main/LICENSE)
![Linux](https://img.shields.io/badge/Linux-%23.svg?style=flat-square&logo=linux&color=FCC624&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-%23.svg?style=flat-square&logo=apple&color=000000&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-%23.svg?style=flat-square&logo=windows&color=0078D6&logoColor=white)

E(x)tended commands missing in fzf.vim, focused on better usability and improvements.

> - For people using Linux/macOS + neovim, you can choose [fzf-lua](https://github.com/ibhagwan/fzf-lua).
> - For people working on small repository and don't care performance issue, you can choose [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

- [Requirements](#requirements)
  - [For Windows](#for-windows)

## Requirements

- Neovim &ge; 0.5.
- [fzf](https://github.com/junegunn/fzf) and [fzf.vim](https://github.com/junegunn/fzf.vim).
- [rg](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd), [bat](https://github.com/sharkdp/bat), recommand to install them with [cargo](https://www.rust-lang.org/):

  ```bash
  cargo install ripgrep
  cargo install fd-find
  cargo install --locked bat
  ```

### For Windows

Since fzf.vim rely on bash shell to run on Windows, so you need either:

1. Automatically install `git` and `bash` via [scoop](https://scoop.sh) and run powershell commands:

   ```powershell
   # scoop
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm get.scoop.sh | iex

   scoop install git
   scoop install mingw
   ```

2. Or manually install [Git for Windows](https://git-scm.com/download/win), and explicitly add `bash.exe` to `%PATH%` environment, it's under `C:\Program Files\Git\bin\bash.exe` by default. But a better way to expose the path is following below two steps when installing:

   1. In **Adjusting your PATH environment**, select **Use Git and optional Unix tools from the Command Prompt**.

   <p align="center">
     <img alt="install-git-step1.png" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/32c20d74-be0b-438b-8de4-347a3c6e1066" width="70%" />
   </p>

   2. In **Configuring the terminal emulator to use with Git Bash**, select **Use Windows's default console window**.

   <p align="center">
     <img alt="install-git-step2.png" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/22a51d91-5f48-42a2-8a31-71584a52efe4" width="70%" />
   </p>

## Credit

- [fzf.vim](https://github.com/junegunn/fzf.vim): Things you can do with [fzf](https://github.com/junegunn/fzf) and Vim.
- [fzf-lua](https://github.com/ibhagwan/fzf-lua): Improved fzf.vim written in lua.

## Contribute

Please open [issue](https://github.com/linrongbin16/fzfx.nvim/issues)/[PR](https://github.com/linrongbin16/fzfx.nvim/pulls) for anything about fzfx.nvim.

Like fzfx.nvim? Consider

[![Github Sponsor](https://img.shields.io/badge/-Sponsor%20Me%20on%20Github-magenta?logo=github&logoColor=white)](https://github.com/sponsors/linrongbin16)
[![Wechat Pay](https://img.shields.io/badge/-Tip%20Me%20on%20WeChat-brightgreen?logo=wechat&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
[![Alipay](https://img.shields.io/badge/-Tip%20Me%20on%20Alipay-blue?logo=alipay&logoColor=white)](https://github.com/linrongbin16/lin.nvim/wiki/Sponsor)
