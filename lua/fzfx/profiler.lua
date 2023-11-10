-- No Setup Need

--- @class Profiler
--- @field start_at {secs:integer,ms:integer}
local Profiler = {}

--- @return Profiler
function Profiler:new()
    local secs, ms = vim.loop.gettimeofday()
    local o = {
        start_at = {
            secs = secs,
            ms = ms,
        },
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @return integer
function Profiler:elapsed_secs()
    local secs, _ = vim.loop.gettimeofday()
    return secs - self.start_at.secs
end

--- @return integer
function Profiler:elapsed_ms()
    local secs, ms = vim.loop.gettimeofday()
    return (secs * 1000 + ms) - (self.start_at.secs * 1000 + self.start_at.ms)
end

local M = {
    Profiler = Profiler,
}

return M
