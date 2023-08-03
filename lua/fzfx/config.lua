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
            normal = {
                name = "FzfxFiles",
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find files",
                },
            },
            unrestricted = {
                name = "FzfxFilesU",
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find files unrestricted",
                },
            },
            visual = {
                name = "FzfxFilesV",
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find files by visual select",
                },
            },
            unrestricted_visual = {
                name = "FzfxFilesUV",
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find files unrestricted by visual select",
                },
            },
            cword = {
                name = "FzfxFilesW",
                opts = {
                    bang = true,
                    desc = "Find files by cursor word",
                },
            },
            unrestricted_cword = {
                name = "FzfxFilesUW",
                opts = {
                    bang = true,
                    desc = "Find files unrestricted by cursor word",
                },
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
                ["enter"] = function(name, lines) end,
                ["double-click"] = function(name, lines) end,
            },
        },
    },
    live_grep = {
        command = {
            normal = {
                name = "FzfxLiveGrep",
                desc = "Live grep",
            },
            unrestricted = {
                name = "FzfxLiveGrepU",
                desc = "Live grep unrestrictly",
            },
            visual = {
                name = "FzfxLiveGrepV",
                desc = "Live grep by visual select",
            },
            unrestricted_visual = {
                name = "FzfxLiveGrepUV",
                desc = "Live grep unrestrictly by visual select",
            },
            cword = {
                name = "FzfxLiveGrepW",
                desc = "Live grep by cursor word",
            },
            unrestricted_cword = {
                name = "FzfxLiveGrepUW",
                desc = "Live grep unrestrictly by cursor word",
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
            "--border=none",
            "--no-height",
            { "--bind", "alt-a:select-all" },
            { "--bind", "alt-d:deselect-all" },
        },
    },
    popup = {
        win_opts = {
            height = 0.85,
            width = 0.85,
            border = "rounded",
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
