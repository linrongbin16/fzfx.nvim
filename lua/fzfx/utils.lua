local log = require("fzfx.log")
local path = require("fzfx.path")
local env = require("fzfx.env")

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

--- @param bufnr integer
--- @param name string
--- @return any
local function get_buf_option(bufnr, name)
    if vim.fn.has("nvim-0.7") > 0 then
        return vim.api.nvim_get_option_value(name, { buf = bufnr })
    else
        return vim.api.nvim_buf_get_option(bufnr, name)
    end
end

--- @param bufnr integer
--- @param name string
--- @param value any
--- @return any
local function set_buf_option(bufnr, name, value)
    if vim.fn.has("nvim-0.7") > 0 then
        return vim.api.nvim_set_option_value(name, value, { buf = bufnr })
    else
        return vim.api.nvim_buf_set_option(bufnr, name, value)
    end
end

--- @param winnr integer
--- @param name string
--- @return any
local function get_win_option(winnr, name)
    if vim.fn.has("nvim-0.7") > 0 then
        return vim.api.nvim_get_option_value(name, { win = winnr })
    else
        return vim.api.nvim_win_get_option(winnr, name)
    end
end

--- @param winnr integer
--- @param name string
--- @param value any
--- @return any
local function set_win_option(winnr, name, value)
    if vim.fn.has("nvim-0.7") > 0 then
        return vim.api.nvim_set_option_value(name, value, { win = winnr })
    else
        return vim.api.nvim_win_set_option(winnr, name, value)
    end
end

--- @alias ListHelperHasher fun(a:any):integer
--- @class ListHelper
--- @field ref any[]?
--- @field visited table<any, boolean>
--- @field hasher ListHelperHasher?
local ListHelper = {
    ref = nil,
    visited = {},
    hasher = nil,
}

--- @param ref any[]
--- @param hasher ListHelperHasher?
--- @return ListHelper
function ListHelper:new(ref, hasher)
    return vim.tbl_deep_extend("force", vim.deepcopy(ListHelper), {
        ref = ref,
        visited = {},
        hasher = hasher,
    })
end

--- @return integer
function ListHelper:size()
    return #self.ref
end

--- @param idx integer
--- @return any
function ListHelper:get(idx)
    return self.ref[idx]
end

--- @param value any
--- @return integer
function ListHelper:_hash(value)
    return type(self.hasher) == "function" and self.hasher(value) or value
end

--- @param value any
function ListHelper:contains(value)
    local key = self:_hash(value)
    if self.visited[key] then
        return true
    end
    local result = false
    for _, v in ipairs(self.ref) do
        local k = self:_hash(v)
        self.visited[k] = true
        if k == key then
            result = true
        end
    end
    return result
end

local M = {
    table_filter = table_filter,
    list_filter = list_filter,
    ListHelper = ListHelper,
    get_buf_option = get_buf_option,
    set_buf_option = set_buf_option,
    set_win_option = set_win_option,
}

return M
