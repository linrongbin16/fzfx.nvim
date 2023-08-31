local LogHighlights = {
    ERROR = "ErrorMsg",
    WARN = "WarningMsg",
    INFO = "None",
    DEBUG = "Comment",
}

-- see: `lua print(vim.inspect(vim.log.levels))`
local LogLevelValue = vim.fn.has("nvim-0.7") > 0 and vim.log.levels
    or {
        TRACE = 0,
        DEBUG = 1,
        INFO = 2,
        WARN = 3,
        ERROR = 4,
        OFF = 5,
    }

--- @enum LogLevel
local LogLevel = {
    TRACE = "TRACE",
    DEBUG = "DEBUG",
    INFO = "INFO",
    WARN = "WARN",
    ERROR = "ERROR",
    OFF = "OFF",
}

local MaxLogLevelValue = -1
local MinLogLevelValue = 2147483647
do
    for _, value in pairs(LogLevelValue) do
        MaxLogLevelValue = math.max(MaxLogLevelValue, value)
        MinLogLevelValue = math.min(MinLogLevelValue, value)
    end
end

--- @param level LogLevel?
--- @param fmt string
--- @param ... any?
local function echo(level, fmt, ...)
    level = level or LogLevel.INFO
    if type(level) == "string" then
        if string.len(level) == 0 then
            error(
                string.format(
                    "error! invalid 'level' (%s) to log!",
                    vim.inspect(level)
                )
            )
        end
        level = string.upper(level)
        if not LogLevel[level] then
            error(
                string.format(
                    "error! invalid 'level' (%s) to log!",
                    vim.inspect(level)
                )
            )
        end
    else
        error(
            string.format(
                "error! invalid 'level' (%s) to log!",
                vim.inspect(level)
            )
        )
    end
    local msg = string.format(fmt, ...)
    local msg_lines = vim.split(msg, "\n")
    local msg_chunks = {}
    local level_name = ""
    if level == "ERROR" then
        level_name = "error! "
    elseif level == "WARN" then
        level_name = "warning! "
    end
    for _, line in ipairs(msg_lines) do
        table.insert(msg_chunks, {
            string.format("[fzfx] %s%s", level_name, line),
            LogHighlights[level],
        })
    end
    vim.api.nvim_echo(msg_chunks, false, {})
end

--- @type Configs
local Defaults = {
    --- @type "ERROR"|"WARN"|"INFO"|"DEBUG"
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

--- @param level "ERROR"|"WARN"|"INFO"|"DEBUG"
--- @param msg string
--- @return nil
local function log(level, msg)
    if LogLevelValue[level] < LogLevelValue[Configs.level] then
        return
    end

    local msg_lines = vim.split(msg, "\n")
    if Configs.console_log and LogLevelValue[level] >= LogLevelValue.INFO then
        echo(level, msg)
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
    setup = setup,
    throw = throw,
    ensure = ensure,
    err = err,
    warn = warn,
    info = info,
    debug = debug,
    LogLevel = LogLevel,
    echo = echo,
}

return M
