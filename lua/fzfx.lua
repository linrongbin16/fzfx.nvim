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
            unrestricted_switch = "ctrl-u",
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
            unrestricted_switch = "ctrl-u",
            fzf_switch = "ctrl-f",
            rg_switch = "ctrl-r",
        },
    },
    env = {
        nvim = "nvim",
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

    -- log
    log.setup({
        level = Configs.debug.enable and "DEBUG" or "INFO",
        console_log = Configs.debug.console_log,
        file_log = Configs.debug.file_log,
    })
    log.debug("|fzfx - setup| Configs:%s", vim.inspect(Configs))
    if Configs.debug.enable then
        vim.fn.mkdir(string.format("%s/fzfx.nvim", vim.fn.stdpath("data")), "p")
    end

    -- env
    vim.env._FZFX_DEBUG_ENABLE = Configs.debug.enable
    vim.env._FZFX_NVIM_PATH = Configs.env.nvim

    -- legacy
    require("fzfx.legacy").setup()

    -- files
    require("fzfx.files").setup(Configs.files)

    -- live_grep
    require("fzfx.live_grep").setup(Configs.live_grep)
end

local M = {
    setup = setup,
}

return M
