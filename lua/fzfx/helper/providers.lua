local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")
local cmds = require("fzfx.lib.commands")
local colors = require("fzfx.lib.colors")
local paths = require("fzfx.lib.paths")
local fs = require("fzfx.lib.filesystems")
local tbls = require("fzfx.lib.tables")

local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local queries_helper = require("fzfx.helper.queries")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")

local M = {}

-- common error message

M.INVALID_BUFFER_ERROR = "invalid buffer(%s)."

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

return M
