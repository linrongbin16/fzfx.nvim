--- @alias LogLevel "ERROR"|"WARN"|"INFO"|"DEBUG"
--- @alias LogMessageHl "ErrorMsg"|"WarningMsg"|"None"|"Comment"

--- @type table<LogLevel, LogLevel>
local LogLevel = {
    ERROR = "ERROR",
    WARN = "WARN",
    INFO = "INFO",
    DEBUG = "DEBUG",
}

local LogLevelValue = {
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    OFF = 5,
}

--- @type Configs
local Defaults = {
    --- @type LogLevel
    level = "INFO",
    --- @type boolean
    console_log = true,
    --- @type string|nil
    name = "[fzfx]",
    --- @type boolean
    file_log = false,
    --- @type string|nil
    file_name = "fzfx.log",
    --- @type string|nil
    file_dir = vim.fn.stdpath("data"),
    --- @type string|nil
    file_path = nil,
}

--- @type Configs
local Configs = {}

--- @type string
local PathSeparator = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
        and "\\"
    or "/"

--- @param option Configs
--- @return nil
local function setup(option)
    Configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), option or {})
    if Configs.file_name and string.len(Configs.file_name) > 0 then
        -- For Windows: $env:USERPROFILE\AppData\Local\nvim-data\fzfx.log
        -- For *NIX: ~/.local/share/nvim/fzfx.log
        if Configs.file_dir then
            Configs.file_path = string.format(
                "%s%s%s",
                Configs.file_dir,
                PathSeparator,
                Configs.file_name
            )
        else
            Configs.file_path = Configs.file_name
        end
    end
    assert(type(Configs.name) == "string")
    assert(string.len(Configs.name) > 0)
    assert(type(Configs.level) == "string")
    if Configs.file_log then
        assert(type(Configs.file_path) == "string")
        assert(string.len(Configs.file_path) > 0)
        assert(type(Configs.file_name) == "string")
        assert(string.len(Configs.file_name) > 0)
    end
end

--- @param level LogLevel
--- @param msg string
--- @return nil
local function log(level, msg)
    if LogLevelValue[level] < LogLevelValue[Configs.level] then
        return
    end

    local msg_lines = vim.split(msg, "\n")
    if
        Configs.console_log
        and LogLevelValue[level] >= LogLevelValue[LogLevel.INFO]
    then
        local level_name = ""
        if string.upper(level) == "ERROR" then
            level_name = "error! "
        elseif string.upper(level) == "WARN" then
            level_name = "warning! "
        end
        for _, line in ipairs(msg_lines) do
            vim.api.nvim_out_write(
                string.format("[fzfx] %s%s\n", level_name, line)
            )
        end
    end
    if Configs.file_log then
        local fp = io.open(Configs.file_path, "a")
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

local function debug(fmt, ...)
    log("DEBUG", string.format(fmt, ...))
end

local function info(fmt, ...)
    log("INFO", string.format(fmt, ...))
end

local function warn(fmt, ...)
    log("WARN", string.format(fmt, ...))
end

local function err(fmt, ...)
    log("ERROR", string.format(fmt, ...))
end

local function throw(fmt, ...)
    err(fmt, ...)
    error(string.format(fmt, ...))
end

--- @param condition boolean
--- @param fmt string
--- @param ... any[]|any
local function ensure(condition, fmt, ...)
    if not condition then
        throw(fmt, ...)
    end
end

local M = {
    LogLevel = LogLevel,
    setup = setup,
    throw = throw,
    ensure = ensure,
    err = err,
    warn = warn,
    info = info,
    debug = debug,
}

return M
