local term_colors = require("fzfx.commons.colors.term")
local consts = require("fzfx.lib.constants")

local M = {}

-- files {

-- "fd . -cnever -tf -tl -L -i"
M.RESTRICTED_FD = {
  consts.FD,
  ".",
  "-cnever",
  "-tf",
  "-tl",
  "-L",
  "-i",
}

-- "fd . -cnever -tf -tl -L -i -u"
M.UNRESTRICTED_FD = {
  consts.FD,
  ".",
  "-cnever",
  "-tf",
  "-tl",
  "-L",
  "-i",
  "-u",
}

-- 'find -L . -type f -not -path "*/.*"'
M.RESTRICTED_FIND = consts.IS_WINDOWS
    and {
      consts.FIND,
      "-L",
      ".",
      "-type",
      "f",
    }
  or {
    consts.FIND,
    "-L",
    ".",
    "-type",
    "f",
    "-not",
    "-path",
    [[*/.*]],
  }

-- "find -L . -type f"
M.UNRESTRICTED_FIND = {
  consts.FIND,
  "-L",
  ".",
  "-type",
  "f",
}

M.provide_files_restricted_mode = consts.HAS_FD and M.RESTRICTED_FD
  or M.RESTRICTED_FIND
M.provide_files_unrestricted_mode = consts.HAS_FD and M.UNRESTRICTED_FD
  or M.UNRESTRICTED_FIND

-- files }

-- live grep {

-- "rg --column -n --no-heading --color=always -S"
M.RESTRICTED_RG = {
  "rg",
  "--column",
  "-n",
  "--no-heading",
  "--color=always",
  "-H",
  "-S",
}

-- "rg --column -n --no-heading --color=always -S -uu"
M.UNRESTRICTED_RG = {
  "rg",
  "--column",
  "-n",
  "--no-heading",
  "--color=always",
  "-H",
  "-S",
  "-uu",
}

-- "grep --color=always -n -H -r --exclude-dir='.*' --exclude='.*'"
M.RESTRICTED_GREP = {
  consts.GREP,
  "--color=always",
  "-n",
  "-H",
  "-r",
  "--exclude-dir=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]]),
  "--exclude=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]]),
}

-- "grep --color=always -n -H -r"
M.UNRESTRICTED_GREP = {
  consts.GREP,
  "--color=always",
  "-n",
  "-H",
  "-r",
}

-- live grep }

-- lsp {

-- simulate rg's filepath color, see:
-- * https://github.com/BurntSushi/ripgrep/discussions/2605#discussioncomment-6881383
-- * https://github.com/BurntSushi/ripgrep/blob/d596f6ebd035560ee5706f7c0299c4692f112e54/crates/printer/src/color.rs#L14
M.LSP_FILENAME_COLOR = consts.IS_WINDOWS and term_colors.cyan
  or term_colors.magenta

-- lsp }

return M
