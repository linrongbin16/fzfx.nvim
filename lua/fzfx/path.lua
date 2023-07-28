local infra = require("fzfx.infra")

local Runtime = {
    separator = nil,
    plugin_home = nil,
    plugin_bin = nil,
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
    if Runtime.plugin_home == nil then
        Runtime.plugin_home = vim.fn["fzfx#nvim#plugin_home"]()
    end
    return Runtime.plugin_home
end

--- @return string
local function plugin_bin()
    if Runtime.plugin_bin == nil then
        Runtime.plugin_bin = infra.is_windows and plugin_home() .. "\\bin"
            or plugin_home() .. "/bin"
    end
    return Runtime.plugin_bin
end

local function separator()
    if Runtime.separator == nil then
        Runtime.separator = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
                and "\\"
            or "/"
    end
    return Runtime.separator
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
