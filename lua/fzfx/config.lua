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
                desc = "Find files unrestrictly",
            },
            visual = {
                name = "FzfxFilesV",
                desc = "Find files by visual select",
            },
            unrestricted_visual = {
                name = "FzfxFilesUV",
                desc = "Find files unrestrictly by visual select",
            },
            cword = {
                name = "FzfxFilesW",
                desc = "Find files by cursor word",
            },
            unrestricted_cword = {
                name = "FzfxFilesUW",
                desc = "Find files unrestrictly by cursor word",
            },
        },
        provider = {
            restricted = default_fd_command,
            unrestricted = default_fd_command .. " -u",
        },
        action = {
            unrestricted_mode = "ctrl-u",
            restricted_mode = "ctrl-r",
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
            unrestricted_mode = "ctrl-u",
            restricted_mode = "ctrl-r",
        },
    },
    fzf_opts = {
        "--ansi",
        "--border=none",
        "--no-height",
    },
    win_opts = {
        height = 0.9,
        width = 0.9,
        border = "rounded",
        zindex = 50,
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
