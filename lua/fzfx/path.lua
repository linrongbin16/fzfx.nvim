local Context = {
    plugin_home = nil,
    plugin_bin = nil,
    separator = nil,
}

--- @param path string
--- @return string
local function normalize(path)
    local result = path
    if string.match(path, "\\") then
        result, _ = string.gsub(path, "\\", "/")
    end
    return vim.fn.trim(result)
end

--- @return string
local function plugin_home()
    if Context.plugin_home == nil then
        Context.plugin_home = vim.fn["fzfx#nvim#plugin_home"]()
    end
    return Context.plugin_home
end

--- @return string
local function plugin_bin()
    if Context.plugin_bin == nil then
        Context.plugin_bin = vim.fn["fzfx#nvim#plugin_bin"]()
    end
    return Context.plugin_bin
end

local function separator()
    if Context.separator == nil then
        Context.separator = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
                and "\\"
            or "/"
    end
    return Context.separator
end

--- @return string
local function tempname()
    return vim.fn.tempname()
end

local M = {
    -- path
    normalize = normalize,
    separator = separator,

    -- plugin dir
    plugin_home = plugin_home,
    plugin_bin = plugin_bin,

    -- temp file
    tempname = tempname,
}

return M
