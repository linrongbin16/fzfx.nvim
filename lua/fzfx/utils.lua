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

--- @class FileSwitch
--- @field value string|nil
--- @field next string|nil
--- @field swap string|nil
local FileSwitch = {
    value = nil,
    next = nil,
    swap = nil,
}

--- @param name string
--- @param value string[]
--- @param next_value string[]
--- @return FileSwitch
function FileSwitch:new(name, value, next_value)
    local init = env.debug_enable()
            and {
                value = string.format(
                    "%s%sfzfx.nvim%s%s_value",
                    vim.fn.stdpath("data"),
                    path.sep(),
                    path.sep(),
                    name
                ),
                next = string.format(
                    "%s%sfzfx.nvim%s%s_next",
                    vim.fn.stdpath("data"),
                    path.sep(),
                    path.sep(),
                    name
                ),
                swap = string.format(
                    "%s%sfzfx.nvim%s%s_swap",
                    vim.fn.stdpath("data"),
                    path.sep(),
                    path.sep(),
                    name
                ),
            }
        or {
            value = path.tempname(),
            next = path.tempname(),
            swap = path.tempname(),
        }
    --- @type FileSwitch
    local switch = vim.tbl_deep_extend("force", vim.deepcopy(FileSwitch), init)
    vim.fn.writefile(value, switch.value, "b")
    vim.fn.writefile(next_value, switch.next, "b")
    return switch
end

--- @return string
function FileSwitch:switch()
    -- value => swap, next => value, swap => next
    return string.format(
        "mv %s %s && mv %s %s && mv %s %s",
        self.value,
        self.swap,
        self.next,
        self.value,
        self.swap,
        self.next
    )
end

local M = {
    table_filter = table_filter,
    list_filter = list_filter,
    FileSwitch = FileSwitch,
}

return M
