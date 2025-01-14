# Known Issues

## Common Issues

### 1. Whitespace Escaping Issue

This plugin internally extends `nvim`, `fzf` and lua scripts to full path when launching the underground fzf command.

1. Example on macOS:

   `/Users/rlin/.config/nvim/lazy/fzf/bin/fzf --print-query --listen --query '' --preview 'nvim -n -u NONE --clean --headless -l /Users/rlin/.local/share/nvim/site/pack/test/start/fzfx.nvim/bin/general/previewer.lua 2 /Users/rlin/.local/share/nvim/fzfx.nvim/previewer_metafile /Users/rlin/.local/share/nvim/fzfx.nvim/previewer_resultfile {}' --bind 'start:execute-silent(echo $FZF_PORT>/Users/rlin/.local/share/nvim/fzfx.nvim/fzf_port_file)' --multi --preview-window 'left,65%,+{2}-/2' --border=none --delimiter ':' --prompt 'Incoming Calls > ' --expect 'esc' --expect 'double-click' --expect 'enter' >/var/folders/5p/j4q6bz395fbbxdf_6b95_nz80000gp/T/nvim.rlin/fIj5xA/2`

2. Example on Windows 10:

   `C:/Users/linrongbin/github/junegunn/fzf/bin/fzf --query "" --header ":: Press \27[38;2;255;121;198mCTRL-U\27[0m to unrestricted mode" --prompt "~/g/l/fzfx.nvim > " --bind "start:unbind(ctrl-r)" --bind "ctrl-u:unbind(ctrl-u)+execute-silent(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\rpc\\client.lua 1)+change-header(:: Press \27[38;2;255;121;198mCTRL-R\27[0m to restricted mode)+rebind(ctrl-r)+reload(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\files\\provider.lua C:\\Users\\linrongbin\\AppData\\Local\\nvim-data\\fzfx.nvim\\switch_files_provider)" --bind "ctrl-r:unbind(ctrl-r)+execute-silent(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\rpc\\client.lua 1)+change-header(:: Press \27[38;2;255;121;198mCTRL-U\27[0m to unrestricted mode)+rebind(ctrl-u)+reload(C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\files\\provider.lua C:\\Users\\linrongbin\\AppData\\Local\\nvim-data\\fzfx.nvim\\switch_files_provider)" --preview "C:\\Users\\linrongbin\\scoop\\apps\\neovim\\current\\bin\\nvim.exe -n --clean --headless -l C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\bin\\files\\previewer.lua {}" --bind "ctrl-l:toggle-preview" --expect "enter" --expect "double-click" >C:\\Users\\LINRON~1\\AppData\\Local\\Temp\\nvim.0\\JSmP06\\2`

But when there're whitespaces on the path, escaping fzf command becomes quite difficult, since it will seriously affected single/double quotes. Here're two typical cases:

1. `C:\Program Files\Neovim\bin\nvim.exe` - Neovim installed in `C:\Program Files` directory.

   ?> Please add executables (`nvim.exe`, `fzf.exe`) to `%PATH%` (`$env:PATH` in PowerShell), so let this plugin find them.

2. `C:\Users\Lin Rongbin\opt\Neovim\bin\nvim.exe` - User name (`Lin Rongbin`) contains whitespace.

   !> We still cannot handle the 2nd case because all lua scripts in this plugin will thus always contain whitespaces in their path.

Please always avoid whitespaces in directories and file names.

### 2. Too many open files

Fzfx heavily uses disk caches, e.g. read/write files a lot. If you encounter an error "EMFILE: Too many open files" on Linux/MacOS, it's because fzfx opens too many files. Please set a big number in your shell profile, it's usually add below configs `.bashrc` in your home directory (or `.zshrc` for [zsh](https://www.zsh.org/)):

```bash
ulimit -n 200000
```

## File Explorer

### 1. Cannot go upper in empty directory?

When in normal variant (not showing hidden files/directories), once cd into an empty directory (with `CTRL-L`) you will cannot go upper (with `CTRL-H`).

Please switch to hidden variant (with `CTRL-U`), e.g. showing hidden files/directories, thus there will have two lines `.` and `..`, then you could go upper (with `CTRL-H`).
