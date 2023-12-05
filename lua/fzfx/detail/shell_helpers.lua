local M = {}

-- infra utils {

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
  LoggerContext.file_path = string.format(
    "%s%s%s",
    vim.fn.stdpath("data"),
    require("fzfx.lib.paths").SEPARATOR,
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

  local msg_lines = require("fzfx.lib.strings").split(msg, "\n")
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
          string.format(
            "%s [%s]: %s\n",
            os.date("%Y-%m-%d %H:%M:%S"),
            LogLevelNames[level],
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

-- infra utils }

-- icon render {

local DEVICONS_PATH = vim.env._FZFX_NVIM_DEVICONS_PATH
local UNKNOWN_FILE_ICON = vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON
local FOLDER_ICON = vim.env._FZFX_NVIM_FILE_FOLDER_ICON
local devicons = nil
if type(DEVICONS_PATH) == "string" and string.len(DEVICONS_PATH) > 0 then
  vim.opt.runtimepath:append(DEVICONS_PATH)
  devicons = require("nvim-web-devicons")
end

--- @param line string
--- @param delimiter string?
--- @param pos integer?
--- @return string
M.prepend_path_with_icon = function(line, delimiter, pos)
  local colors = require("fzfx.lib.colors")
  local strs = require("fzfx.lib.strings")

  if devicons == nil then
    return line
  end
  local filename = nil
  if strs.not_empty(delimiter) and type(pos) == "number" then
    local splits =
      require("fzfx.lib.strings").split(line, delimiter --[[@as string]])
    filename = splits[pos]
  else
    filename = line
  end
  -- remove ansi color codes
  -- see: https://stackoverflow.com/a/55324681/4438921
  if strs.not_empty(filename) then
    filename = colors.erase(filename)
  end
  local ext = vim.fn.fnamemodify(filename, ":e")
  local icon, icon_color = devicons.get_icon_color(filename, ext)
  -- log_debug(
  --     "|fzfx.shell_helpers - render_line_with_icon| ext:%s, icon:%s, icon_color:%s",
  --     vim.inspect(ext),
  --     vim.inspect(icon),
  --     vim.inspect(icon_color)
  -- )
  if strs.not_empty(icon) then
    local fmt = colors.csi(icon_color, true)
    if fmt then
      return string.format("[%sm%s[0m %s", fmt, icon, line)
    else
      return string.format("%s %s", icon, line)
    end
  else
    if vim.fn.isdirectory(filename) > 0 then
      return string.format("%s %s", FOLDER_ICON, line)
    else
      return string.format("%s %s", UNKNOWN_FILE_ICON, line)
    end
  end
end

-- icon render }

return M
