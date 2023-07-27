--- @type boolean
local is_windows = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0
--- @type boolean
local is_macos = vim.fn.has("mac") > 0
--- @type string
local plugin_home = vim.fn["fzfx#nvim#plugin_home"]()
--- @type string
local plugin_bin = is_windows and plugin_home .. "\\bin"
    or plugin_home .. "/bin"

local bat = vim.fn.executable("bat") > 0 and "bat" or "batcat"
local rg = "rg"
local fd = vim.fn.executable("fd") > 0 and "fd" or "fdfind"

local M = {
    -- os
    is_windows = is_windows,
    is_macos = is_macos,

    -- plugin
    plugin_home = plugin_home,
    plugin_bin = plugin_bin,

    -- command
    bat = bat,
    rg = rg,
    fd = fd,
}

return M
