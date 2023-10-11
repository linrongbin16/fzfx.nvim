# Regresion test

## Platforms

- [ ] windows
- [ ] macOS
- [ ] linux

## Tasks

- [ ] FzfxFiles
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Press `CTRL-U`/`CTRL-R` to switch between restricted/unrestricted mode, and the lines count is consistent when press multiple times.
  - Use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - Press `ESC` to quit, `ENTER` to open file, and open the `test/hello world.txt`, `test/goodbye world/goodbye.lua` files.
  - Both `fd` and `find` works.
- [ ] FzfxLiveGrep
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Press `CTRL-U`/`CTRL-R` to switch between restricted/unrestricted mode, and the lines count is consistent when press multiple times.
  - Use `-w` to match word only, use `-g *.lua` to search only lua files.
  - Use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - Press `ESC` to quit, `ENTER` to open file, and open the `test/hello world.txt`, `test/goodbye world/goodbye.lua` files.
  - Both `rg` and `grep` works.
- [ ] FzfxBuffers
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Press `CTRL-D` to delete buffers, and delete the `test/hello world.txt`, `test/goodbye world/goodbye.lua` buffers.
  - Use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - Press `ESC` to quit, `ENTER` to open file.
- [ ] FzfxGFiles
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Press `CTRL-U`/`CTRL-W` to switch between workspace/current folder mode.
  - Use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - Press `ESC` to quit, `ENTER` to open file.
- [ ] FzfxGBranches
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Press `CTRL-R`/`CTRL-O` to switch between local/remote branches.
  - Use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - Press `ESC` to quit, `ENTER` to checkout branch.
- [ ] FzfxGCommits
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Press `CTRL-U`/`CTRL-A` to switch between git repo commits/current buffer commits.
  - Use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - Press `ESC` to quit, `ENTER` to copy commit hash.
- [ ] FzfxGBlame
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - Press `ESC` to quit, `ENTER` to copy commit hash.
- [ ] FzfxLspDiagnostics
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Press `CTRL-U`/`CTRL-W` to switch between workspace/current buffer diagnostics.
  - Use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - Press `ESC` to quit, `ENTER` to open file.
- [ ] FzfxLspDefinitions, FzfxLspTypeDefinitions, FzfxLspReferences, FzfxLspImplementations
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Go to definitions/references (this is the most 2 easiest use case when developing this lua plugin with lua_ls).
  - Press `ESC` to quit, `ENTER` to open file.
- [ ] FzfxFileExplorer
  - Press `CTRL-N`/`CTRL-P` to move down/up and preview contents.
  - Press `CTRL-U`/`CTRL-R` to switch between filter/include hidden files mode.
  - Press `ALT-L`/`ALT-H` to cd into folder and cd upper folder.
  - Press `ESC` to quit, `ENTER` to open file, and open the `test/hello world.txt`, `test/goodbye world/goodbye.lua` files.
  - Both `eza` and `ls` works.
- [ ] Backward Compatible
  - Open with `nvim -u ./test/minimal_buffers_deprecate_init.lua` and test `FzfxBuffers`.
  - Open with `nvim -u ./test/minimal_files_deprecate_init.lua` and test `FzfxFiles`.
  - Open with `nvim -u ./test/minimal_git_branches_deprecate_init.lua` and test `FzfxGBranches`.
  - Open with `nvim -u ./test/minimal_git_commits_deprecate_init.lua` and test `FzfxGCommits`.
  - Open with `nvim -u ./test/minimal_git_files_deprecate_init.lua` and test `FzfxGFiles`.
  - Open with `nvim -u ./test/minimal_live_grep_deprecate_init.lua` and test `FzfxLiveGrep`.
