local log = require("fzfx.log")
local constants = require("fzfx.constants")

local default_fd_command =
    string.format("%s . -cnever -tf -tl -L -i", constants.fd)
local default_rg_command =
    string.format("%s --column -n --no-heading --color=always -S", constants.rg)

--- @alias Config table<string, any>

--- @type Config
local Defaults = {
    files = {
        command = {
            FzfxFiles = {
                bang = true,
                nargs = "?",
                complete = "dir",
                desc = "Find files",
                unrestricted = false,
            },
            FzfxFilesU = {
                bang = true,
                nargs = "?",
                complete = "dir",
                desc = "Find files unrestricted",
                unrestricted = true,
            },
            FzfxFilesV = {
                bang = true,
                range = true,
                desc = "Find files by visual select",
                unrestricted = false,
            },
            FzfxFielsUV = {
                bang = true,
                range = true,
                desc = "Find files unrestricted by visual select",
                unrestricted = true,
            },
            FzfxFilesW = {
                bang = true,
                desc = "Find files by cursor word",
                unrestricted = false,
            },
            FzfxFilesUW = {
                bang = true,
                desc = "Find files unrestricted by cursor word",
                unrestricted = true,
            },
        },
        provider = {
            restricted = default_fd_command,
            unrestricted = default_fd_command .. " -u",
        },
        action = {
            builtin = {
                unrestricted_mode = "ctrl-u",
                restricted_mode = "ctrl-r",
            },
            expect = {
                ["enter"] = require("fzfx.actions").open_buffer,
                ["double-click"] = require("fzfx.actions").open_buffer,
            },
        },
    },
    live_grep = {
        command = {
            FzfxLiveGrep = {
                bang = true,
                nargs = "*",
                desc = "Live grep",
                unrestricted = false,
            },
            FzfxLiveGrepU = {
                bang = true,
                nargs = "*",
                desc = "Live grep unrestricted",
                unrestricted = true,
            },
            FzfxLiveGrepV = {
                bang = true,
                range = true,
                desc = "Live grep by visual select",
                unrestricted = false,
            },
            FzfxLiveGrepUV = {
                bang = true,
                range = true,
                desc = "Live grep unrestricted by visual select",
                unrestricted = true,
            },
            FzfxLiveGrepW = {
                bang = true,
                desc = "Live grep by cursor word",
                unrestricted = false,
            },
            FzfxLiveGrepUW = {
                bang = true,
                desc = "Live grep unrestricted by cursor word",
                unrestricted = true,
            },
        },
        provider = {
            restricted = default_rg_command,
            unrestricted = default_rg_command .. " -uu",
        },
        action = {
            builtin = {
                unrestricted_mode = "ctrl-u",
                restricted_mode = "ctrl-r",
            },
            expect = {
                ["enter"] = require("fzfx.actions").open_buffer,
                ["double-click"] = require("fzfx.actions").open_buffer,
            },
        },
    },
    fzf = {
        opts = {
            "--ansi",
            "--border=rounded",
            "--no-height",
            { "--bind", "alt-a:select-all" },
            { "--bind", "alt-d:deselect-all" },
        },
    },
    popup = {
        win_opts = {
            height = 0.85,
            width = 0.85,
            border = "none",
            zindex = 51,
        },
    },
    env = {
        nvim = nil,
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
--- @return Config
local function setup(options)
    Configs = vim.tbl_deep_extend("force", Defaults, options or {})
    return Configs
end

--- @return Config
local function get_config()
    return Configs
end

local M = {
    setup = setup,
    get_config = get_config,
}

return M
