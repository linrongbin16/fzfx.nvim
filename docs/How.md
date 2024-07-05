# How?

After deep dive into [fzf](https://github.com/junegunn/fzf) and [fzf.vim](https://github.com/junegunn/fzf.vim), I found fzf-based plugin is actually trying to start a fzf command inside a terminal and a float window of (Neo)VIM.

The architecture (simply) looks like:

<img width="40%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/bfc1740f-5d2e-4afb-af72-2f5b224b5c29">

The key of this kind of plugin is how to interact with the terminal/float-window and the fzf command.

There're two technologies come to me:

## Use `nvim` as a lua script interpreter

It has several benefits:

1. It avoid to run the raw shell command (for example `rg --column -n --no-heading -S -- {q}`), thus avoid the shell escaping characters.
2. It avoid to develop the shell scripts or Windows Batch/PowerShell scripts, which makes the project development and maintenance easier.

## Setup RPC connections

When the plugin initialize, it starts a RPC server on `127.0.0.1`. When start searching, the `nvim` lua interpreter is been launched by fzf command, as a query command and a child process, it connects to the RPC server as a RPC client. This allows it works as if it's still running inside the Neovim editor we're using.

For example, when we start the `FzfxBuffers` command, the `nvim` lua interpreter connects to Neovim editor to ask for the opened buffers list via a RPC call. The Neovim editor handles the query logic and send the query results to the lua interpreter, and the interpreter renders them and prints them to `stdout`, and we can see the output in fzf, i.e. the left side of popup window.

?> Special thanks to [@ibhagwan](https://github.com/ibhagwan) and his [fzf-lua](https://github.com/ibhagwan/fzf-lua), I learned this from him.

So the architecture becomes:

<img width="100%" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/2f199c28-1833-47cc-9f94-d39499d21ce3">
