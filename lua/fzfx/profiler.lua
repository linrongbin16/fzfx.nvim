local log = require("fzfx.log")

--- @class Profiler
--- @field name string
--- @field start_at {secs:integer,ms:integer}
local Profiler = {}

local default_timestamp_formatter = "%d.%03d s"

--- @param name string
--- @return Profiler
function Profiler:new(name)
    local secs, ms = vim.loop.gettimeofday()
    local o = {
        name = name,
        start_at = {
            secs = secs,
            ms = ms,
        },
    }
    log.debug(
        "%s start at: " .. default_timestamp_formatter,
        name,
        secs,
        math.floor(ms / 1000)
    )
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param message string?
--- @return integer
function Profiler:elapsed_ms(message)
    local now_secs, now_ms = vim.loop.gettimeofday()
    local used_ms = (now_secs * 1000 + math.floor(now_ms / 1000))
        - (self.start_at.secs * 1000 + math.floor(self.start_at.ms / 1000))
    log.debug(
        "%s%s running at: " .. default_timestamp_formatter .. ", used: %d ms",
        self.name,
        (type(message) == "string" and string.len(message) > 0)
                and string.format("(%s)", message)
            or "",
        now_secs,
        math.floor(now_ms / 1000),
        used_ms
    )
    return used_ms
end

local M = {
    Profiler = Profiler,
}

return M
