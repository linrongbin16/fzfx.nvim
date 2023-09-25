-- infra utils {

local IS_WINDOWS = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0

if IS_WINDOWS then
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

--- @type string
local PATH_SEPARATOR = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
        and "\\"
    or "/"

local DEBUG_ENABLE = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"

local LoggerContext = {
    --- @type "DEBUG"|"INFO"|"WARN"|"ERROR"
    level = DEBUG_ENABLE and "DEBUG" or "INFO",
    --- @type boolean
    console_log = true,
    --- @type string|nil
    name = "[fzfx-shell-helpers]",
    --- @type boolean
    file_log = DEBUG_ENABLE and true or false,
    --- @type string|nil
    file_path = string.format(
        "%s%s%s",
        vim.fn.stdpath("data"),
        PATH_SEPARATOR,
        "fzfx_shell_helpers.log"
    ),
}

--- @param level "DEBUG"|"INFO"|"WARN"|"ERROR"
--- @param msg string
--- @return nil
local function _log(level, msg)
    local LogLevels = require("fzfx.notify").LogLevels

    if LogLevels[level] < LogLevels[LoggerContext.level] then
        return
    end

    local msg_lines = require("fzfx.utils").string_split(msg, "\n")
    if LoggerContext.console_log then
        for _, line in ipairs(msg_lines) do
            io.write(string.format("%s %s\n", level, line))
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
                        level,
                        line
                    )
                )
            end
            fp:close()
        end
    end
end

local function log_debug(fmt, ...)
    _log("DEBUG", string.format(fmt, ...))
end

local function log_err(fmt, ...)
    _log("ERROR", string.format(fmt, ...))
end

local function log_throw(fmt, ...)
    log_err(fmt, ...)
    error(string.format(fmt, ...))
end

--- @param condition boolean
--- @param fmt string
--- @param ... any[]|any
local function log_ensure(condition, fmt, ...)
    if not condition then
        log_throw(fmt, ...)
    end
end

-- infra utils }

-- icon render {

local DEVICONS_PATH = vim.env._FZFX_NVIM_DEVICONS_PATH
local UNKNOWN_FILE_ICON = vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON
local FOLDER_ICON = vim.env._FZFX_NVIM_FILE_FOLDER_ICON
local DEVICONS = nil
if type(DEVICONS_PATH) == "string" and string.len(DEVICONS_PATH) > 0 then
    vim.opt.runtimepath:append(DEVICONS_PATH)
    DEVICONS = require("nvim-web-devicons")
end

--- @param line string
--- @param delimiter string?
--- @param pos integer?
local function prepend_path_with_icon(line, delimiter, pos)
    if DEVICONS == nil then
        return line
    end
    local filename = nil
    if
        type(delimiter) == "string"
        and string.len(delimiter) > 0
        and type(pos) == "number"
    then
        local splits = require("fzfx.utils").string_split(line, delimiter)
        filename = splits[pos]
    else
        filename = line
    end
    -- remove ansi color codes
    -- see: https://stackoverflow.com/a/55324681/4438921
    if type(filename) == "string" and string.len(filename) > 0 then
        filename = require("fzfx.color").erase(filename)
    end
    local ext = vim.fn.fnamemodify(filename, ":e")
    local icon, icon_color = DEVICONS.get_icon_color(filename, ext)
    -- log_debug(
    --     "|fzfx.shell_helpers - render_line_with_icon| ext:%s, icon:%s, icon_color:%s",
    --     vim.inspect(ext),
    --     vim.inspect(icon),
    --     vim.inspect(icon_color)
    -- )
    if type(icon) == "string" and string.len(icon) > 0 then
        local colorfmt = require("fzfx.color").csi(icon_color, true)
        if colorfmt then
            return string.format("[%sm%s[0m %s", colorfmt, icon, line)
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

local M = {
    log_debug = log_debug,
    log_err = log_err,
    log_throw = log_throw,
    log_ensure = log_ensure,
    prepend_path_with_icon = prepend_path_with_icon,
    Cmd = require("fzfx.cmd").Cmd,
    GitRootCmd = require("fzfx.cmd").GitRootCmd,
    GitBranchCmd = require("fzfx.cmd").GitBranchCmd,
    GitCurrentBranchCmd = require("fzfx.cmd").GitCurrentBranchCmd,
    AsyncCmd = require("fzfx.cmd").AsyncCmd,
    -- async_cmd = require("fzfx.cmd").async_cmd,
    string_find = require("fzfx.utils").string_find,
    string_rfind = require("fzfx.utils").string_rfind,
    string_ltrim = require("fzfx.utils").string_ltrim,
    string_rtrim = require("fzfx.utils").string_rtrim,
    FileLineReader = require("fzfx.utils").FileLineReader,
    readfile = require("fzfx.utils").readfile,
}

return M
