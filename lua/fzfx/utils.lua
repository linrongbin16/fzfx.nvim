local log = require("fzfx.log")
local path = require("fzfx.path")
local env = require("fzfx.env")

-- vim {

local function table_filter(f, t)
    local result = {}
    for k, v in pairs(t) do
        if f(k, v) then
            result[k] = v
        end
    end
    return result
end

local function list_filter(f, l)
    local result = {}
    for i, v in ipairs(l) do
        if f(i, v) then
            table.insert(result, v)
        end
    end
    return result
end

-- vim }

local M = {
    table_filter = table_filter,
    list_filter = list_filter,
}

return M
