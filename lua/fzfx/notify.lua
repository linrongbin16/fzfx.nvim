-- No Setup Need

-- see: `lua print(vim.inspect(vim.log.levels))`
local LogLevels = {
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    OFF = 5,
}

local LogLevelNames = {}

do
    for name, value in pairs(LogLevels) do
        LogLevelNames[value] = name
    end
end

local LogHighlights = {
    [1] = "Comment",
    [2] = "None",
    [3] = "WarningMsg",
    [4] = "ErrorMsg",
}

--- @param level integer
--- @param fmt string
--- @param ... any?
local function echo(level, fmt, ...)
    local msg = string.format(fmt, ...)
    local msg_lines = require("fzfx.utils").string_split(msg, "\n")
    local msg_chunks = {}
    local prefix = ""
    if level == LogLevels.ERROR then
        prefix = "error! "
    elseif level == LogLevels.WARN then
        prefix = "warning! "
    end
    for _, line in ipairs(msg_lines) do
        table.insert(msg_chunks, {
            string.format("[fzfx] %s%s", prefix, line),
            LogHighlights[level],
        })
    end
    vim.api.nvim_echo(msg_chunks, false, {})
end

local M = {
    LogLevels = LogLevels,
    LogLevelNames = LogLevelNames,
    echo = echo,
}

return M
