local consts = require("fzfx.lib.constants")

local M = {}

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

return M
