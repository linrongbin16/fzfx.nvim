--- @class Yank
--- @field text string|nil
--- @field file string|nil
--- @field time integer|nil
local Yank = {
    text = nil,
    file = nil,
    time = nil,
}

--- @param text string
--- @param file string|nil
function Yank:new(text, file)
    local switch = vim.tbl_deep_extend("force", vim.deepcopy(Yank), {
        text = text,
        file = file,
        time = os.time(),
    })
end

--- @class YankHistoryManager
--- @field queue Yank[]
local YankHistoryManager = {
    queue = {},
}

local function yank_history() end

local function setup() end

local M = {
    setup = setup,
}

return M
