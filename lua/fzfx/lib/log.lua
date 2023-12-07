local strs = require("fzfx.lib.strings")
local paths = require("fzfx.lib.paths")

local M = {}

-- see: `lua print(vim.inspect(vim.log.levels))`
M.LogLevels = {
  TRACE = 0,
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
  OFF = 5,
}

M.LogLevelNames = {
  [0] = "TRACE",
  [1] = "DEBUG",
  [2] = "INFO",
  [3] = "WARN",
  [4] = "ERROR",
  [5] = "OFF",
}

local LogHighlights = {
  [1] = "Comment",
  [2] = "None",
  [3] = "WarningMsg",
  [4] = "ErrorMsg",
}

--- @param level integer
--- @param fmt string
--- @param ... any
M.echo = function(level, fmt, ...)
  local msg = string.format(fmt, ...)
  local msg_lines = strs.split(msg, "\n")
  local msg_chunks = {}
  local prefix = ""
  if level == M.LogLevels.ERROR then
    prefix = "error! "
  elseif level == M.LogLevels.WARN then
    prefix = "warning! "
  end
  for _, line in ipairs(msg_lines) do
    table.insert(msg_chunks, {
      string.format("[fzfx] %s%s", prefix, line),
      LogHighlights[level],
    })
  end
  vim.schedule(function()
    vim.api.nvim_echo(msg_chunks, false, {})
  end)
end

--- @type fzfx.Options
local Defaults = {
  level = M.LogLevels.INFO,
  console_log = true,
  name = "[fzfx]",
  file_log = false,
  file_name = "fzfx.log",
  file_dir = vim.fn.stdpath("data"),
  file_path = nil,
}

--- @type fzfx.Options
local Configs = {
  level = M.LogLevels.DEBUG,
  console_log = true,
  name = "[fzfx-safe-mode]",
  file_log = false,
  file_name = "fzfx_safe_mode.log",
  file_dir = vim.fn.stdpath("data"),
  file_path = string.format(
    "%s%s%s",
    vim.fn.stdpath("data"),
    paths.SEPARATOR,
    "fzfx_safe_mode.log"
  ),
}

--- @param option fzfx.Options
M.setup = function(option)
  Configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), option or {})
  if type(Configs.level) == "string" then
    Configs.level = M.LogLevels[Configs.level]
  end
  assert(type(Configs.name) == "string")
  assert(string.len(Configs.name) > 0)
  assert(type(Configs.level) == "number")
  if Configs.file_log then
    Configs.file_path = string.format(
      "%s%s%s",
      Configs.file_dir,
      paths.SEPARATOR,
      Configs.file_name
    )
    assert(type(Configs.file_path) == "string")
    assert(string.len(Configs.file_path) > 0)
  end
end

--- @param level integer
--- @param msg string
local function _log(level, msg)
  if level < Configs.level then
    return
  end

  local msg_lines = strs.split(msg, "\n")
  if Configs.console_log and level >= M.LogLevels.INFO then
    M.echo(level, msg)
  end
  if Configs.file_log then
    local fp = io.open(Configs.file_path, "a")
    if fp then
      for _, line in ipairs(msg_lines) do
        local secs, ms = vim.loop.gettimeofday()
        fp:write(
          string.format(
            "%s.%03d [%s]: %s\n",
            os.date("%Y-%m-%d %H:%M:%S", secs),
            math.floor(ms / 1000),
            M.LogLevelNames[level],
            line
          )
        )
      end
      fp:close()
    end
  end
end

--- @param fmt string
--- @param ... any
M.debug = function(fmt, ...)
  _log(M.LogLevels.DEBUG, string.format(fmt, ...))
end

--- @param fmt string
--- @param ... any
M.info = function(fmt, ...)
  _log(M.LogLevels.INFO, string.format(fmt, ...))
end

--- @param fmt string
--- @param ... any
M.warn = function(fmt, ...)
  _log(M.LogLevels.WARN, string.format(fmt, ...))
end

--- @param fmt string
--- @param ... any
M.err = function(fmt, ...)
  _log(M.LogLevels.ERROR, string.format(fmt, ...))
end

--- @param fmt string
--- @param ... any
M.throw = function(fmt, ...)
  M.err(fmt, ...)
  error(string.format(fmt, ...))
end

--- @param cond boolean
--- @param fmt string
--- @param ... any
M.ensure = function(cond, fmt, ...)
  if not cond then
    M.throw(fmt, ...)
  end
end

return M
