# [`fzfx.helper`](https://github.com/linrongbin16/fzfx.nvim/tree/main/lua/fzfx/helper)

The `fzfx.helper` package contains all the line-oriented utilities for parsing and rendering the lines for (both left side and right side of) the fzf binary. Since a searching command is actually all about the lines: generating, previewing and invoking binded function on the lines.

And there're multiple sub-packages inside (sorted in alphabetical order):

- [`actions`](#fzfxhelperactions)
- [`parsers`](#fzfxhelperparsers)
- [`provider_decorators`](#fzfxhelperprovider_decorators)

## `fzfx.helper.actions`

This sub-package contains all the actions.

## `fzfx.helper.parsers`

This sub-package contains all the parsers used for parsing user inputs & query results. For example the `FzfxLiveGrep` runs `rg --column -n --no-heading --color=always -H -S 'fzfx'` command (suppose you have `rg` and search for text `'fzfx'`) as the underlying command, the query results look like:

<img width="860" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/033cd998-3b06-4846-8cff-d2794216ebc0">

It's easy to tell that the query results are lines, each line contains a single query result. In each line, there're 4 components separated by colons (`:`):

1. The file path that contains the keyword `'fzfx'`, starting from current working directory (`CWD`/`PWD`).
2. The line number specifies which line contains the keyword `'fzfx'`.
3. The column number specifies which column is the keyword `'fzfx'` starting.

   !> Note: The 3rd component **column number** only exists in `rg`, while `grep` and `git grep` don't have it.

4. The line text.

When previewing this line, `fzf` will let the previewer know which line it's currently pointing to.

<img width="989" alt="image" src="https://github.com/linrongbin16/fzfx.nvim/assets/6496887/38b507f7-fd5b-47c9-89b6-0db1aaa87e85">


## `fzfx.helper.provider_decorators`
