-- see: `lua print(vim.inspect(vim.log.levels))`
local NotifyLevel = vim.fn.has("nvim-0.7") > 0 and vim.log.levels
    or {
        TRACE = 0,
        DEBUG = 1,
        INFO = 2,
        WARN = 3,
        ERROR = 4,
        OFF = 5,
    }

local MaxNotifyLevel = -1
local MinNotifyLevel = 2147483647
do
    for _, value in pairs(NotifyLevel) do
        MaxNotifyLevel = math.max(MaxNotifyLevel, value)
        MinNotifyLevel = math.min(MinNotifyLevel, value)
    end
end

--- @param level string|integer|nil
--- @param fmt string
--- @param ... any?
local function notify(level, fmt, ...)
    level = level or "INFO"
    if type(level) == "integer" then
        if level < MinNotifyLevel or level > MaxNotifyLevel then
            error(
                string.format(
                    "error! invalid 'level' (%s) to notify!",
                    vim.inspect(level)
                )
            )
        end
    elseif type(level) == "string" then
        if string.len(level) == 0 then
            error(
                string.format(
                    "error! invalid 'level' (%s) to notify!",
                    vim.inspect(level)
                )
            )
        end
        level = string.upper(level)
        if not NotifyLevel[level] then
            error(
                string.format(
                    "error! invalid 'level' (%s) to notify!",
                    vim.inspect(level)
                )
            )
        end
        level = NotifyLevel[level]
    else
    end
    local level_name = ""
    if level == NotifyLevel.WARN then
        level_name = "warning! "
    elseif level == NotifyLevel.ERROR then
        level_name = "error! "
    end
    vim.api.nvim_notify(
        string.format("[fzfx] %s%s", level_name, string.format(fmt, ...)),
        level,
        {}
    )
end

local M = {
    NotifyLevel = NotifyLevel,
    notify = notify,
}

return M
