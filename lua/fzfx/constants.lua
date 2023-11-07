-- No Setup Need

local is_windows = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0
local is_macos = vim.fn.has("mac") > 0
local is_bsd = vim.fn.has("bsd") > 0
-- we just think others are linux
local is_linux = not is_windows
    and not is_macos
    and not is_bsd
    and (vim.fn.has("linux") > 0 or vim.fn.has("unix") > 0)
local int32_max = 2 ^ 31 - 1

local path_separator = is_windows and "\\" or "/"

local has_bat = vim.fn.executable("batcat") > 0 or vim.fn.executable("bat") > 0
local bat = vim.fn.executable("batcat") > 0 and "batcat" or "bat"

local has_rg = vim.fn.executable("rg") > 0
local rg = "rg"

local has_fd = vim.fn.executable("fdfind") > 0 or vim.fn.executable("fd") > 0
local fd = vim.fn.executable("fdfind") > 0 and "fdfind" or "fd"
local find = vim.fn.executable("gfind") > 0 and "gfind" or "find"

local has_gnu_grep = (
    (is_windows or is_linux) and vim.fn.executable("grep") > 0
) or vim.fn.executable("ggrep") > 0
local gnu_grep = vim.fn.executable("ggrep") > 0 and "ggrep" or "grep"
local grep = vim.fn.executable("ggrep") > 0 and "ggrep" or "grep"

local has_lsd = vim.fn.executable("lsd") > 0
local has_eza = vim.fn.executable("exa") > 0 or vim.fn.executable("eza") > 0
local eza = vim.fn.executable("eza") > 0 and "eza" or "exa"

local has_delta = vim.fn.executable("delta") > 0

local M = {
    -- os
    is_windows = is_windows,
    is_macos = is_macos,
    is_bsd = is_bsd,
    is_linux = is_linux,
    int32_max = int32_max,

    -- path
    path_separator = path_separator,

    -- command
    has_bat = has_bat,
    bat = bat,

    has_rg = has_rg,
    rg = rg,

    has_fd = has_fd,
    fd = fd,
    find = find,

    has_gnu_grep = has_gnu_grep,
    gnu_grep = gnu_grep,
    grep = grep,

    has_lsd = has_lsd,
    has_eza = has_eza,
    eza = eza,

    has_delta = has_delta,
}

return M
