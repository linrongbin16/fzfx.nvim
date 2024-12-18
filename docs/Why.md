# Why?

There're already lots of great fuzzy find plugins in (Neo)VIM community:

- [fzf.vim](https://github.com/junegunn/fzf.vim)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

Why build another one?

- `fzf.vim` doesn't has icon and real-time parsing `rg` options.
- `fzf-lua` doesn't support Windows (Note: It supports Windows now, not at the time when I first wrote this). I had tried to add support for Windows, but failed.
- `telescope` looks the best, but its internal sorter is based on [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and is quite low performant, even with [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim) extension. I cannot accept the delay and always miss the smooth of fzf.
