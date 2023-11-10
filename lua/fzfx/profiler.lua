local log = require("fzfx.log")

--- @class Profiler
--- @field name string
--- @field start_at {secs:integer,ms:integer}
local Profiler = {}

local default_millis_formatter = "%d.%03d s"
local default_micros_formatter = "%d.%06d s"

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
        "%s start at: " .. default_millis_formatter,
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
function Profiler:elapsed_millis(message)
    local now_secs, now_ms = vim.loop.gettimeofday()
    local used_ms = (now_secs * 1000 + math.floor(now_ms / 1000))
        - (self.start_at.secs * 1000 + math.floor(self.start_at.ms / 1000))
    log.debug(
        "%s%s running at: " .. default_millis_formatter .. ", used: %d millis",
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

--- @param message string?
--- @return integer
function Profiler:elapsed_micros(message)
    local now_secs, now_ms = vim.loop.gettimeofday()
    local used_ms = (now_secs * 1000000 + now_ms)
        - (self.start_at.secs * 1000000 + self.start_at.ms)
    log.debug(
        "%s%s running at: " .. default_micros_formatter .. ", used: %d micros",
        self.name,
        (type(message) == "string" and string.len(message) > 0)
                and string.format("(%s)", message)
            or "",
        now_secs,
        now_ms,
        used_ms
    )
    return used_ms
end

local M = {
    Profiler = Profiler,
}

return M
