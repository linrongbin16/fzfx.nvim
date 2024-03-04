local M = {}

M.IS_WINDOWS = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0

M.DEBUG_ENABLE = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE) == "1"

if M.IS_WINDOWS then
  vim.o.shell = "cmd.exe"
  vim.o.shellslash = false
  vim.o.shellcmdflag = "/s /c"
  vim.o.shellxquote = '"'
  vim.o.shellquote = ""
  vim.o.shellredir = ">%s 2>&1"
  vim.o.shellpipe = "2>&1| tee"
  vim.o.shellxescape = ""
else
  vim.o.shell = "sh"
end

local LoggerContext = {
  level = M.DEBUG_ENABLE and require("fzfx.lib.log").LogLevels.DEBUG
    or require("fzfx.lib.log").LogLevels.INFO,
  console_log = M.DEBUG_ENABLE and true or false,
  file_log = M.DEBUG_ENABLE and true or false,
  file_path = nil,
}

--- @param name string
M.setup = function(name)
  local path = require("fzfx.commons.path")
  LoggerContext.file_path = string.format(
    "%s%s%s",
    vim.fn.stdpath("data"),
    path.SEPARATOR,
    string.format("fzfx_bin_%s.log", name)
  )
end

--- @param level integer
--- @param msg string
local function _log(level, msg)
  local LogLevelNames = require("fzfx.lib.log").LogLevelNames
  if level < LoggerContext.level then
    return
  end

  local msg_lines = vim.split(msg, "\n", { plain = true })
  if LoggerContext.console_log then
    for _, line in ipairs(msg_lines) do
      io.write(string.format("%s %s\n", LogLevelNames[level], line))
    end
  end
  if LoggerContext.file_log then
    local fp = io.open(LoggerContext.file_path, "a")
    if fp then
      for _, line in ipairs(msg_lines) do
        fp:write(
          string.format("%s [%s]: %s\n", os.date("%Y-%m-%d %H:%M:%S"), LogLevelNames[level], line)
        )
      end
      fp:close()
    end
  end
end

--- @param fmt string
--- @param ... any
M.log_debug = function(fmt, ...)
  local LogLevels = require("fzfx.lib.log").LogLevels
  _log(LogLevels.DEBUG, string.format(fmt, ...))
end

--- @param fmt string
--- @param ... any
M.log_err = function(fmt, ...)
  local LogLevels = require("fzfx.lib.log").LogLevels
  _log(LogLevels.ERROR, string.format(fmt, ...))
end

--- @param fmt string
--- @param ... any
M.log_throw = function(fmt, ...)
  M.log_err(fmt, ...)
  error(string.format(fmt, ...))
end

--- @param cond boolean
--- @param fmt string
--- @param ... any
M.log_ensure = function(cond, fmt, ...)
  if not cond then
    M.log_throw(fmt, ...)
  end
end

return M
