--- @alias LogLevel "ERROR"|"WARN"|"INFO"|"DEBUG"
--- @alias LogMessageHl "ErrorMsg"|"WarningMsg"|"None"|"Comment"

--- @type table<LogLevel, LogLevel>
local LogLevel = {
    ERROR = "ERROR",
    WARN = "WARN",
    INFO = "INFO",
    DEBUG = "DEBUG",
}

--- @type table<LogLevel, LogMessageHl>
local LogLevelHl = {
    ["ERROR"] = "ErrorMsg",
    ["WARN"] = "WarningMsg",
    ["INFO"] = "None",
    ["DEBUG"] = "Comment",
}

--- @type table<string, any>
local Defaults = {
    --- @type LogLevel
    level = "INFO",
    --- @type boolean
    console_log = true,
    --- @type string|nil
    name = "fzfx",
    --- @type boolean
    file_log = false,
    --- @type string|nil
    file_name = "fzfx.log",
    --- @type string|nil
    file_dir = vim.fn.stdpath("data"),
    --- @type string|nil
    file_path = nil,
}

--- @type table<string, any>
local Config = {}

--- @type string
local PathSeparator = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
        and "\\"
    or "/"

--- @param option table<string, any>
--- @return nil
local function setup(option)
    Config = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), option or {})
    if Config.file_name and string.len(Config.file_name) > 0 then
        -- For Windows: $env:USERPROFILE\AppData\Local\nvim-data\fzfx.log
        -- For *NIX: ~/.local/share/nvim/fzfx.log
        if Config.file_dir then
            Config.file_path = string.format(
                "%s%s%s",
                Config.file_dir,
                PathSeparator,
                Config.file_name
            )
        else
            Config.file_path = Config.file_name
        end
    end
    assert(type(Config.name) == "string")
    assert(string.len(Config.name) > 0)
    assert(type(Config.level) == "string")
    assert(LogLevelHl[Config.level] ~= nil)
    if Config.file_log then
        assert(type(Config.file_path) == "string")
        assert(string.len(Config.file_path) > 0)
        assert(type(Config.file_name) == "string")
        assert(string.len(Config.file_name) > 0)
    end
end

--- @param level LogLevel
--- @param msg string
--- @return nil
local function log(level, msg)
    if vim.log.levels[level] < vim.log.levels[Config.level] then
        return
    end

    local name = ""
    if type(Config.name) == "type" and string.len(Config.name) > 0 then
        name = Config.name .. " "
    end
    local msg_lines = vim.split(msg, "\n")
    if Config.console_log then
        vim.cmd("echohl " .. LogLevelHl[level])
        for _, line in ipairs(msg_lines) do
            vim.cmd(
                string.format(
                    'echomsg "%s"',
                    vim.fn.escape(string.format("%s%s", name, line), '"')
                )
            )
        end
        vim.cmd("echohl None")
    end
    if Config.file_log then
        local fp = io.open(Config.file_path, "a")
        if fp then
            for _, line in ipairs(msg_lines) do
                fp:write(
                    string.format(
                        "%s%s [%s]: %s\n",
                        name,
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

local function debug(fmt, ...)
    log("DEBUG", string.format(fmt, ...))
end

local function info(fmt, ...)
    log("INFO", string.format(fmt, ...))
end

local function warn(fmt, ...)
    log("WARN", string.format(fmt, ...))
end

local function error(fmt, ...)
    log("ERROR", string.format(fmt, ...))
end

local M = {
    LogLevel = LogLevel,
    setup = setup,
    error = error,
    warn = warn,
    info = info,
    debug = debug,
}

return M
