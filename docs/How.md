# How?

## Background

After deep dive into [fzf](https://github.com/junegunn/fzf) and [fzf.vim](https://github.com/junegunn/fzf.vim), I found fzf-based fuzzy finder is actually running a fzf command inside a terminal buffer and a float window.

Each time when user start to search, the user opens the popup window. It actually first creates a terminal buffer and floating window. The terminal buffer starts to run the `fzf` command, the floating window is the popup UI component. Then user will either press some keys (such as `CTRL-U`, `CTRL-E`, etc) to make some changes, without quit the popup window. Or press some keys (such as `Enter`, `Esc`, etc) to select some lines and do some actions with these selected lines.

> Here we introduce two terms:
>
> - Interaction (Interactive Action): The keys (and the triggered actions) that don't need to quit fzf.
> - Action (Exit Action): The keys (and the triggered actions) that will quit fzf.

The architecture (simply) looks like:

<img width="50%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/bfc1740f-5d2e-4afb-af72-2f5b224b5c29">

Most exit actions are actually quite intuitive, for example:

- User will press `Enter` to quit fzf and open a file on the select line.
- User will press `Esc` to quit fzf and do nothing.

While for the interactive actions, it can provide much more UX behavior for users. The key of fuzzy finder plugins is all about how to make the fzf command running inside a terminal shell interact with the floating window inside Neovim editor.

There comes two technologies.

## Lua Interpreter

When binding any actions, use `nvim` itself as a lua interpreter instead of traditional shell scripts. It has several benefits:

1. It avoids to develop the terminal-oriented shell scripts or Windows Batch/PowerShell scripts. It uses lua, a much more high-level language that has data types and better syntax designs, which helps implementing more complicated logics when working with fzf and Neovim, and easier to maintain in long-term.
2. It's even possible to allow using all the Neovim's builtin library, i.e. the `vim.api`, `vim.lsp`, `vim.fn`, etc. That makes the lua interpreter more like a general purposed Neovim-based virtual machine or runtime environment, including infrastructures such as filesystem, IO, network, child-process, etc.

## RPC Between Forked Process

When this plugin first initializes, it setups a RPC server via [`serverstart()`](<https://neovim.io/doc/user/builtin.html#serverstart()>), it listens on a socket/named-pipe address, serves as a RPC service.

Then, when user press keys and run the binding actions, (since it's running a lua script launched by `nvim`) the lua script (child process) setup a RPC client and make a request to the Neovim editor (parent process). This allows the child-process fetch all the data from the Neovim editor, thus it works as if it's still running inside the Neovim editor.

For example, when we use the `FzfxBuffers` command (similar to `:Buffers` in `fzf.vim` and `:FzfLua buffers` in `fzf-lua`), the lua script connects to Neovim editor and request for the opened buffers list via RPC call. The Neovim editor handles the query logic and send the results to child process, then lua script renders them and prints to `stdout`, and user can see the output in fzf (i.e. the left side of popup window).

> Special thanks to [@ibhagwan](https://github.com/ibhagwan) and his [fzf-lua](https://github.com/ibhagwan/fzf-lua), I learned this from him.

The architecture becomes:

<img width="100%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/2f199c28-1833-47cc-9f94-d39499d21ce3">
