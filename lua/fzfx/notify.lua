-- Zero Dependency

-- see: `lua print(vim.inspect(vim.log.levels))`
local NotifyLevels = (
    vim.fn.has("nvim-0.7") > 0
    and type(vim.log) == "table"
    and type(vim.log.levels) == "table"
)
        and vim.log.levels
    or {
        TRACE = 0,
        DEBUG = 1,
        INFO = 2,
        WARN = 3,
        ERROR = 4,
        OFF = 5,
    }

local NotifyLevelNames = {}

do
    for name, value in pairs(NotifyLevels) do
        NotifyLevelNames[value] = name
    end
end

local NotifyHighlights = {
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
    if level == NotifyLevels.ERROR then
        prefix = "error! "
    elseif level == NotifyLevels.WARN then
        prefix = "warning! "
    end
    for _, line in ipairs(msg_lines) do
        table.insert(msg_chunks, {
            string.format("[fzfx] %s%s", prefix, line),
            NotifyHighlights[level],
        })
    end
    vim.api.nvim_echo(msg_chunks, false, {})
end

local M = {
    NotifyLevels = NotifyLevels,
    NotifyLevelNames = NotifyLevelNames,
    echo = echo,
}

return M
