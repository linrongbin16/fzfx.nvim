local log = require("fzfx.log")

--- @type Config
local Defaults = {
    live_grep = {
        command = {
            restricted = "rg --column -n --no-heading --color=always -S",
            unrestricted = "rg --column -n --no-heading --color=always -S -uu",
        },
        action = {
            fzf_mode = "ctrl-f",
            rg_mode = "ctrl-r",
        },
    },
}

--- @type Config
local Configs = {}

--- @param options Config
--- @return nil
local function setup(options)
    Configs = vim.tbl_deep_extend("force", Defaults, options or {})

    log.setup({
        level = Configs.debug and "DEBUG" or "INFO",
        console_log = Configs.console_log,
        file_log = Configs.file_log,
    })
end

local M = {
    setup = setup,
}

return M
