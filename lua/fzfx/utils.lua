local is_windows = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0

local is_macos = vim.fn.has("mac") > 0

local plugin_home = vim.fn["fzfx#nvim#plugin_home_dir"]()
local plugin_bin = is_windows and plugin_home .. "\\bin"
    or plugin_home .. "/bin"

local M = {
    os = {
        is_windows = is_windows,
        is_macos = is_macos,
    },
    fs = {
        plugin_home = plugin_home,
        plugin_bin = plugin_bin,
    },
}

return M
