local infra = require("fzfx.infra")

local Cache = {
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
local function tempfilename()
    return vim.fn.tempname()
end

--- @return string
local function plugin_home()
    if Cache.plugin_home == nil then
        Cache.plugin_home = vim.fn["fzfx#nvim#plugin_home"]()
    end
    return Cache.plugin_home
end

--- @return string
local function plugin_bin()
    if Cache.plugin_bin == nil then
        Cache.plugin_bin = infra.is_windows and plugin_home() .. "\\bin"
            or plugin_home() .. "/bin"
    end
    return Cache.plugin_bin
end

local M = {
    normalize = normalize,
    tempfilename = tempfilename,
    plugin_home = plugin_home,
    plugin_bin = plugin_bin,
}

return M
