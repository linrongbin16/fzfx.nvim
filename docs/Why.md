# Why?

There're already lots of great fuzzy find plugins in (Neo)VIM community:

- [fzf.vim](https://github.com/junegunn/fzf.vim)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

Why build another one?

There're no big stories:

- I use fzf for many years, and I collect some really great out-of-box configurations to make fzf working with Vim. I believe it can help others as well.
- `fzf.vim` doesn't has icon and real-time parsing `rg` options.
- `fzf-lua` doesn't support Windows (Note: It supports Windows now, not at the time I wrote this). I had tried to add support for Windows, but failed.
- `telescope` has the best features, flexibilities and communities. But its internal sorter is based on [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and quite low performant, even with [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim) extension. I cannot accept. I always miss fzf's performance and smooth when I'm using telescope.

I had done some investigations, and found that it's possible to:

- Use `nvim` as a lua script interpreter, instead of writing shell scripts or Windows Batch/PowerShell scripts. Lua is a much more high-level language that has data types, and syntax grammars, that can help implementing more complicated and dynamical logic when working with fzf. And it's even possible to use the full Neovim's builtin lua library, i.e. the `vim.api`, `vim.lsp`, `vim.fn`, etc. That makes the lua script more like a Neovim-based VM and runtime environment.
- Use `nvim` the lua script interpreter as a RPC client, and the Neovim editor (the one you're editing files) as a RPC server . Thus we could send almost every data to the RPC client, and let it handle almost all kinds of logic when generating querying results for fzf.

  ?> Special thanks to [@ibhagwan](https://github.com/ibhagwan) and his [fzf-lua](https://github.com/ibhagwan/fzf-lua), I learned this from him.

So I decide to have a try.
