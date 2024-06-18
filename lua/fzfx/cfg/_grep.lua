local path = require("fzfx.commons.path")
local str = require("fzfx.commons.str")

local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels
local consts = require("fzfx.lib.constants")
local bufs = require("fzfx.lib.bufs")

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

-- Get buffer file path by the buffer number.
-- Returns `nil` and print an error message if failed to get the file path.
--- @param bufnr integer
--- @return string?
M.buf_path = function(bufnr)
  local bufpath = bufs.buf_is_valid(bufnr) and path.reduce(vim.api.nvim_buf_get_name(bufnr)) or nil
  if str.empty(bufpath) then
    log.echo(LogLevels.INFO, string.format("invalid buffer(%s).", vim.inspect(bufnr)))
    return nil
  end
  return bufpath
end

-- Split `opts` string option into a strings list by whitespaces, then append to arguments table `args`.
--- @param args string[]
--- @param opts string?
--- @return string[]
M.append_options = function(args, opts)
  assert(type(args) == "table")
  if str.not_empty(opts) then
    local option_splits = str.split(opts --[[@as string]], " ", { plain = true, trimempty = true })
    for _, o in ipairs(option_splits) do
      local trimmed_o = str.trim(o)
      if str.not_empty(trimmed_o) then
        table.insert(args, trimmed_o)
      end
    end
  end

  return args
end

return M
