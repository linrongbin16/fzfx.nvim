--- @alias Config table<string, any>
--- @alias Option table<string, any>

local log = require("fzfx.log")

local default_fd_command = string.format(
    "%s . -cnever -tf -tl -L -i",
    vim.fn.executable("fd") > 0 and "fd" or "fdfind"
)
local default_rg_command = "rg --column -n --no-heading --color=always -S"

--- @type Config
local Defaults = {
    files = {
        command = {
            restricted = default_fd_command,
            unrestricted = default_fd_command .. " -u",
        },
    },
    live_grep = {
        command = {
            restricted = default_rg_command,
            unrestricted = default_rg_command .. " -uu",
        },
        action = {
            fzf_mode = "ctrl-f",
            rg_mode = "ctrl-r",
        },
    },
    debug = {
        enable = false,
        console_log = true,
        file_log = false,
    },
}

--- @type Config
local Configs = {}

--- @param options Option
--- @return nil
local function setup(options)
    Configs = vim.tbl_deep_extend("force", Defaults, options or {})

    log.setup({
        level = Configs.debug.enable and "DEBUG" or "INFO",
        console_log = Configs.debug.console_log,
        file_log = Configs.debug.file_log,
    })
end

local M = {
    setup = setup,
}

return M
