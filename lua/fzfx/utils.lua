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

--- @param s any
--- @return boolean
local function string_empty(s)
    return type(s) ~= "string" or string.len(s) == 0
end

--- @param s any
--- @return boolean
local function string_not_empty(s)
    return type(s) == "string" and string.len(s) > 0
end

local M = {
    table_filter = table_filter,
    list_filter = list_filter,
    get_buf_option = get_buf_option,
    set_buf_option = set_buf_option,
    set_win_option = set_win_option,
    string_empty = string_empty,
    string_not_empty = string_not_empty,
}

return M
