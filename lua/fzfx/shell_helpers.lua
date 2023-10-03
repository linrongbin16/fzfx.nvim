-- infra utils {

local is_windows = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0

if is_windows then
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

local PATH_SEPARATOR = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
        and "\\"
    or "/"

local DEBUG_ENABLE = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"

-- see: `lua print(vim.inspect(vim.log.levels))`
local LogLevels = {
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    OFF = 5,
}

local LogLevelNames = {
    [0] = "TRACE",
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
    [5] = "OFF",
}

local LogDefaults = {
    level = DEBUG_ENABLE and LogLevels.DEBUG or LogLevels.INFO,
    console_log = true,
    file_log = DEBUG_ENABLE and true or false,
    file_name = "fzfx_shell_helpers.log",
    file_path = string.format(
        "%s%s%s",
        vim.fn.stdpath("data"),
        PATH_SEPARATOR,
        "fzfx_shell_helpers.log"
    ),
}
local LogConfigs = {}

--- @param option Configs
local function log_setup(option)
    LogConfigs =
        vim.tbl_deep_extend("force", vim.deepcopy(LogDefaults), option or {})
    if LogConfigs.file_name and string.len(LogConfigs.file_name) > 0 then
        LogConfigs.file_path = string.format(
            "%s%s%s",
            vim.fn.stdpath("data"),
            PATH_SEPARATOR,
            LogConfigs.file_name
        )
    end
end

--- @param level integer
--- @param msg string
--- @return nil
local function _log(level, msg)
    if level < LogConfigs.level then
        return
    end

    local msg_lines = require("fzfx.utils").string_split(msg, "\n")
    if LogConfigs.console_log then
        for _, line in ipairs(msg_lines) do
            io.write(string.format("%s %s\n", LogLevelNames[level], line))
        end
    end
    if LogConfigs.file_log then
        local fp = io.open(LogConfigs.file_path, "a")
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

local function log_debug(fmt, ...)
    _log(LogLevels.DEBUG, string.format(fmt, ...))
end

local function log_err(fmt, ...)
    _log(LogLevels.ERROR, string.format(fmt, ...))
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
    is_windows = is_windows,
    log_setup = log_setup,
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
    string_find = require("fzfx.utils").string_find,
    string_rfind = require("fzfx.utils").string_rfind,
    string_ltrim = require("fzfx.utils").string_ltrim,
    string_rtrim = require("fzfx.utils").string_rtrim,
    FileLineReader = require("fzfx.utils").FileLineReader,
    readfile = require("fzfx.utils").readfile,
}

return M
