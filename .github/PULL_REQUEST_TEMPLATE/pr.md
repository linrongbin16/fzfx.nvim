# Regresion test

## Platform

- [ ] windows
- [ ] macOS
- [ ] ubuntu

## Commands

- [ ] FzfxFiles
  - [ ] It can use `CTRL-U`/`CTRL-R` to switch between restricted/unrestricted mode, and the lines count is consistent when press multiple times.
  - [ ] It can use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - [ ] It can use `ESC` to quit, `ENTER` to open file.
- [ ] FzfxLiveGrep
  - [ ] It can use `CTRL-U`/`CTRL-R` to switch between restricted/unrestricted mode, and the lines count is consistent when press multiple times.
  - [ ] It can use `-w` to match word only, use `-g *.lua` to search only lua files.
  - [ ] It can use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - [ ] It can use `ESC` to quit, `ENTER` to open file.
- [ ] FzfxBuffers
  - [ ] It can use `CTRL-D` to delete buffers.
  - [ ] It can use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - [ ] It can use `ESC` to quit, `ENTER` to open file.
- [ ] FzfxGFiles
  - [ ] It can use `CTRL-U`/`CTRL-W` to switch between workspace/current folder mode.
  - [ ] It can use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - [ ] It can use `ESC` to quit, `ENTER` to open file.
- [ ] FzfxGCommits
  - [ ] It can use `CTRL-U`/`CTRL-A` to switch between git repo commits/current buffer commits.
  - [ ] It can use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - [ ] It can use `ESC` to quit, `ENTER` to copy commit hash.
- [ ] FzfxGBlame
  - [ ] It can use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - [ ] It can use `ESC` to quit, `ENTER` to copy commit hash.
- [ ] FzfxLspDiagnostics
  - [ ] It can use `CTRL-U`/`CTRL-W` to switch between workspace/current buffer diagnostics.
  - [ ] It can use `V`/`W`/`P` variants (visual selection, cursor word, yank text).
  - [ ] It can use `ESC` to quit, `ENTER` to open file.
- [ ] FzfxLspDefinitions, FzfxLspTypeDefinitions, FzfxLspReferences, FzfxLspImplementations
  - [ ] It can go to definitions/references (this is the most 2 easiest use case when developing this lua plugin with lua\_ls).
  - [ ] It can use `ESC` to quit, `ENTER` to open file.
- [ ] FzfxFileExplorer
  - [ ] It can use `CTRL-U`/`CTRL-I` to switch between filter/include hidden files mode.
  - [ ] It can use `CTRL-L`/`CTRL-H` to cd into folder and cd upper folder.
  - [ ] It can use `ESC` to quit, `ENTER` to open file.
