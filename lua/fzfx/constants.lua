--- @type boolean
local is_windows = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0
--- @type boolean
local is_macos = vim.fn.has("mac") > 0

local bat = vim.fn.executable("batcat") > 0 and "batcat" or "bat"
local rg = "rg"
local fd = vim.fn.executable("fdfind") > 0 and "fdfind" or "fd"

local M = {
    -- os
    is_windows = is_windows,
    is_macos = is_macos,

    -- command
    bat = bat,
    rg = rg,
    fd = fd,
}

return M
