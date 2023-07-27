local log = require("fzfx.log")
local infra = require("fzfx.infra")

local default_fd_command = string.format("%s . -cnever -tf -tl -L -i", infra.fd)
local default_rg_command =
    string.format("%s --column -n --no-heading --color=always -S", infra.rg)

--- @alias Config table<string, any>

--- @type Config
local Defaults = {
    files = {
        command = {
            normal = {
                name = "FzfxFiles",
                desc = "Find files",
            },
            unrestricted = {
                name = "FzfxFilesU",
                desc = "Find files unrestricted",
            },
            visual = {
                name = "FzfxFilesV",
                desc = "Find files by visual select",
            },
            unrestricted_visual = {
                name = "FzfxFilesUV",
                desc = "Find files unrestricted by visual select",
            },
        },
        provider = {
            restricted = default_fd_command,
            unrestricted = default_fd_command .. " -u",
        },
        action = {
            restricted = "ctrl-r",
            unrestricted = "ctrl-u",
        },
    },
    live_grep = {
        provider = {
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

--- @param options Config
--- @return nil
local function setup(options)
    Configs = vim.tbl_deep_extend("force", Defaults, options or {})

    log.setup({
        level = Configs.debug.enable and "DEBUG" or "INFO",
        console_log = Configs.debug.console_log,
        file_log = Configs.debug.file_log,
    })
    log.debug("|fzfx - setup| Configs:%s", vim.inspect(Configs))

    require("fzfx.files").setup(Configs.files)
end

local M = {
    setup = setup,
}

return M
