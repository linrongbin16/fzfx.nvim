--- @type table<string, any>
local Cache = {}

--- @param key string
--- @param value any
--- @return any
local function put(key, value)
    assert(type(key) == "string" and string.len(vim.trim(key)) > 0)
    Cache[key] = value
    return Cache[key]
end

--- @param key string
--- @return boolean
local function has(key)
    return Cache[key] ~= nil
end

--- @param key string
--- @param default_value any
local function get(key, default_value)
    return has(key) and Cache[key] or default_value
end

local M = {
    put = put,
    has = has,
    get = get,
}

return M
