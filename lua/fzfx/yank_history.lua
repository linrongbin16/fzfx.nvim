--- @class Yank
--- @field time integer|nil
--- @field text string|nil
--- @field file string|nil
local Yank = {
    time = nil,
    text = nil,
    file = nil,
}

--- @class YankHistoryManager
--- @field time integer|nil
--- @field text string|nil
local YankHistoryManager = {
    time = nil,
    text = nil,
}

local function yank_history() end

local function setup() end

local M = {
    setup = setup,
}

return M
