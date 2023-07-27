local log = require("fzfx.log")

--- @type boolean
local is_windows = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0
--- @type boolean
local is_macos = vim.fn.has("mac") > 0
--- @type string
local plugin_home = vim.fn["fzfx#nvim#plugin_home_dir"]()
--- @type string
local plugin_bin = is_windows and plugin_home .. "\\bin"
    or plugin_home .. "/bin"

local M = {
    is_windows = is_windows,
    is_macos = is_macos,
    plugin_home = plugin_home,
    plugin_bin = plugin_bin,
}

log.debug("|fzfx.infra| %s", vim.inspect(M))

return M
