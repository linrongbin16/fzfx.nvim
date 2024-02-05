local numbers = require("fzfx.commons.numbers")

local M = {}

M.LogLevels = require("fzfx.commons.logging").LogLevels

M.LogLevelNames = require("fzfx.commons.logging").LogLevelNames

local LogHighlights = {
  [0] = "Comment",
  [1] = "Comment",
  [2] = "None",
  [3] = "WarningMsg",
  [4] = "ErrorMsg",
  [5] = "ErrorMsg",
}

--- @param level integer
--- @param fmt string
--- @param ... any
M.echo = function(level, fmt, ...)
  level = numbers.bound(level, M.LogLevels.TRACE, M.LogLevels.OFF)

  local msg = string.format(fmt, ...)
  local msg_lines = vim.split(msg, "\n", { plain = true })

  local prefix = ""
  if level == M.LogLevels.ERROR then
    prefix = "error! "
  elseif level == M.LogLevels.WARN then
    prefix = "warning! "
  end

  for _, line in ipairs(msg_lines) do
    local chunks = {}
    table.insert(chunks, {
      string.format("[fzfx] %s%s", prefix, line),
      LogHighlights[level],
    })
    vim.schedule(function()
      vim.api.nvim_echo(chunks, false, {})
    end)
  end
end

--- @type fzfx.Options
local Defaults = {
  level = M.LogLevels.INFO,
  name = "[fzfx]",
  console_log = true,
  file_log = false,
  file_name = "fzfx.log",
  file_dir = vim.fn.stdpath("data"),
  file_path = nil,
}

--- @param opts fzfx.Options?
M.setup = function(opts)
  local configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), opts or {})
  require("fzfx.commons.logging").setup({
    name = "fzfx",
    level = configs.level,
    console_log = configs.console_log,
    file_log = configs.file_log,
    file_log_name = "fzfx.log",
  })
end

--- @param fmt string
--- @param ... any
M.debug = function(fmt, ...)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.DEBUG, fmt, ...)
end

--- @param fmt string
--- @param ... any
M.info = function(fmt, ...)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.INFO, fmt, ...)
end

--- @param fmt string
--- @param ... any
M.warn = function(fmt, ...)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.WARN, fmt, ...)
end

--- @param fmt string
--- @param ... any
M.err = function(fmt, ...)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.ERROR, fmt, ...)
end

--- @param fmt string
--- @param ... any
M.throw = function(fmt, ...)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.ERROR, fmt, ...)
  error(string.format(fmt, ...))
end

--- @param cond boolean
--- @param fmt string
--- @param ... any
M.ensure = function(cond, fmt, ...)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  if not cond then
    require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.ERROR, fmt, ...)
  end
  assert(cond, string.format(fmt, ...))
end

return M
