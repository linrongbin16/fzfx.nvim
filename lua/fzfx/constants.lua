-- Zero Dependency

--- @type boolean
local is_windows = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0
--- @type boolean
local is_macos = vim.fn.has("mac") > 0
--- @type boolean
local is_bsd = vim.fn.has("bsd") > 0
-- we just think others are linux
--- @type boolean
local is_linux = not is_windows
    and not is_macos
    and not is_bsd
    and (vim.fn.has("linux") > 0 or vim.fn.has("unix") > 0)

local path_separator = is_windows and "\\" or "/"

local has_bat = vim.fn.executable("batcat") > 0 or vim.fn.executable("bat") > 0
local bat = vim.fn.executable("batcat") > 0 and "batcat" or "bat"

local has_rg = vim.fn.executable("rg") > 0
local rg = "rg"

local has_fd = vim.fn.executable("fdfind") > 0 or vim.fn.executable("fd") > 0
local fd = vim.fn.executable("fdfind") > 0 and "fdfind" or "fd"

local has_gnu_grep = (
    (is_windows or is_linux) and vim.fn.executable("grep") > 0
) or ((is_macos or is_bsd) and vim.fn.executable("ggrep") > 0)
local gnu_grep = (is_bsd or is_macos) and "ggrep" or "grep"

local grep = "grep"

local has_gnu_find = (
    (is_windows or is_linux) and vim.fn.executable("find") > 0
) or ((is_macos or is_bsd) and vim.fn.executable("gfind") > 0)
local gnu_find = (is_bsd or is_macos) and "gfind" or "find"
local find = "find"

local M = {
    -- os
    is_windows = is_windows,
    is_macos = is_macos,
    is_bsd = is_bsd,
    is_linux = is_linux,

    -- path
    path_separator = path_separator,

    -- command
    has_bat = has_bat,
    bat = bat,

    has_rg = has_rg,
    rg = rg,

    has_fd = has_fd,
    fd = fd,

    has_gnu_grep = has_gnu_grep,
    gun_grep = gnu_grep,
    grep = grep,

    has_gnu_find = has_gnu_find,
    gnu_find = gnu_find,
    find = find,
}

return M
