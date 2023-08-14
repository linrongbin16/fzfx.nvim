local constants = require("fzfx.constants")

local default_fd_command =
    string.format("%s -cnever -tf -tl -L -i", constants.fd)
local default_rg_command =
    string.format("%s --column -n --no-heading --color=always -S", constants.rg)

--- @alias Config table<string, any>

--- @type Config
local Defaults = {
    -- the 'Files' commands
    files = {
        commands = {
            normal = {
                {
                    name = "FzfxFiles",
                    unrestricted = false,
                    opts = {
                        bang = true,
                        nargs = "?",
                        complete = "dir",
                        desc = "Find files",
                    },
                },
                {
                    name = "FzfxFilesU",
                    unrestricted = true,
                    opts = {
                        bang = true,
                        nargs = "?",
                        complete = "dir",
                        desc = "Find files",
                    },
                },
            },
            visual = {
                {
                    name = "FzfxFilesV",
                    unrestricted = false,
                    opts = {
                        bang = true,
                        range = true,
                        desc = "Find files by visual select",
                    },
                },
                {
                    name = "FzfxFilesUV",
                    unrestricted = true,
                    opts = {
                        bang = true,
                        range = true,
                        desc = "Find files unrestricted by visual select",
                    },
                },
            },
            cword = {
                {
                    name = "FzfxFilesW",
                    unrestricted = false,
                    opts = {
                        bang = true,
                        desc = "Find files by cursor word",
                    },
                },
                {
                    name = "FzfxFilesUW",
                    unrestricted = true,
                    opts = {
                        bang = true,
                        desc = "Find files unrestricted by cursor word",
                    },
                },
            },
            put = {
                {
                    name = "FzfxFilesP",
                    unrestricted = false,
                    opts = {
                        bang = true,
                        desc = "Find files by yank text",
                    },
                },
                {
                    name = "FzfxFilesUP",
                    unrestricted = true,
                    opts = {
                        bang = true,
                        desc = "Find files unrestricted by yank text",
                    },
                },
            },
        },
        providers = {
            restricted = default_fd_command,
            unrestricted = default_fd_command .. " -u",
        },
        actions = {
            builtin = {
                unrestricted_mode = "ctrl-u",
                restricted_mode = "ctrl-r",
            },
            expect = {
                ["esc"] = require("fzfx.action").nop,
                ["enter"] = require("fzfx.action").edit,
                ["double-click"] = require("fzfx.action").edit,
            },
        },
        fzf_opts = {
            { "--bind", "ctrl-l:toggle-preview" },
        },
    },

    -- the 'Live Grep' commands
    live_grep = {
        commands = {
            normal = {
                {
                    name = "FzfxLiveGrep",
                    unrestricted = false,
                    opts = {
                        bang = true,
                        nargs = "*",
                        desc = "Live grep",
                    },
                },
                {
                    name = "FzfxLiveGrepU",
                    unrestricted = true,
                    opts = {
                        bang = true,
                        nargs = "*",
                        desc = "Live grep unrestricted",
                    },
                },
            },
            visual = {
                {
                    name = "FzfxLiveGrepV",
                    unrestricted = false,
                    opts = {
                        bang = true,
                        range = true,
                        desc = "Live grep by visual select",
                    },
                },
                {
                    name = "FzfxLiveGrepUV",
                    unrestricted = true,
                    opts = {
                        bang = true,
                        range = true,
                        desc = "Live grep unrestricted by visual select",
                    },
                },
            },
            cword = {
                {
                    name = "FzfxLiveGrepW",
                    unrestricted = false,
                    opts = {
                        bang = true,
                        desc = "Live grep by cursor word",
                    },
                },
                {
                    name = "FzfxLiveGrepUW",
                    unrestricted = true,
                    opts = {
                        bang = true,
                        desc = "Live grep unrestricted by cursor word",
                    },
                },
            },
            put = {
                {
                    name = "FzfxLiveGrepP",
                    unrestricted = false,
                    opts = {
                        bang = true,
                        desc = "Live grep by yank text",
                    },
                },
                {
                    name = "FzfxLiveGrepUP",
                    unrestricted = true,
                    opts = {
                        bang = true,
                        desc = "Live grep unrestricted by yank text",
                    },
                },
            },
        },
        providers = {
            restricted = default_rg_command,
            unrestricted = default_rg_command .. " -uu",
        },
        actions = {
            builtin = {
                unrestricted_mode = "ctrl-u",
                restricted_mode = "ctrl-r",
            },
            expect = {
                ["esc"] = require("fzfx.action").nop,
                ["enter"] = require("fzfx.action").edit_rg,
                ["double-click"] = require("fzfx.action").edit_rg,
            },
        },
        fzf_opts = {
            { "--bind", "ctrl-l:toggle-preview" },
        },
        other_opts = {
            onchange_reload_delay = "sleep 0.1 && ",
        },
    },

    -- the 'Buffers' commands
    buffers = {
        commands = {
            normal = {
                {
                    name = "FzfxBuffers",
                    opts = {
                        bang = true,
                        nargs = "?",
                        complete = "dir",
                        desc = "Find buffers",
                    },
                },
            },
            visual = {
                {
                    name = "FzfxBuffersV",
                    opts = {
                        bang = true,
                        range = true,
                        desc = "Find buffers by visual select",
                    },
                },
            },
            cword = {
                {
                    name = "FzfxFilesW",
                    opts = {
                        bang = true,
                        desc = "Find buffers by cursor word",
                    },
                },
            },
            put = {
                {
                    name = "FzfxBuffersP",
                    opts = {
                        bang = true,
                        desc = "Find buffers by yank text",
                    },
                },
            },
        },
        actions = {
            builtin = {
                delete_buffer = "ctrl-d",
            },
            expect = {
                ["esc"] = require("fzfx.action").nop,
                ["enter"] = require("fzfx.action").edit,
                ["double-click"] = require("fzfx.action").edit,
            },
        },
        fzf_opts = {
            { "--bind", "ctrl-l:toggle-preview" },
        },
    },

    -- the 'Yank History' commands
    yank_history = {
        other_opts = {
            history_size = 100,
        },
    },

    -- basic fzf options
    fzf_opts = {
        "--ansi",
        "--info=inline",
        "--layout=reverse",
        "--border=none",
        "--height=100%",
    },

    -- popup window options
    -- implemented via float window, please check: https://neovim.io/doc/user/api.html#nvim_open_win()
    win_opts = {

        -- popup window height/width.
        --
        -- 1. if 0 <= h/w <= 1, evaluate proportionally according to editor's lines and columns,
        --    e.g. popup height = h * lines, width = w * columns.
        --
        -- 2. if h/w > 1, evaluate as absolute height and width, directly pass to vim.api.nvim_open_win.

        --- @type number
        height = 0.85,
        --- @type number
        width = 0.85,

        -- popup window position, by default popup window is right in the center of editor.
        -- especially useful when popup window is too big and conflicts with command/status line at bottom.
        --
        -- 1. if -0.5 <= r/c <= 0.5, evaluate proportionally according to editor's lines and columns.
        --    e.g. shift rows = r * lines, shift columns = c * columns.
        --
        -- 2. if r/c <= -1 or r/c >= 1, evaluate as absolute rows/columns to be shift.
        --    e.g. you can easily set 'row = -vim.o.cmdheight' to move popup window to up 1~2 lines (based on your 'cmdheight' option).
        --
        -- 3. r/c cannot be in range (-1, -0.5) or (0.5, 1), it makes no sense.

        --- @type number
        row = 0,
        --- @type number
        col = 0,

        border = "rounded",
        zindex = 51,
    },

    -- icon
    icon = {
        enable = true,
        -- default = "",
    },

    -- environment variables
    env = {
        --- @type string|nil
        nvim = nil,
        --- @type string|nil
        fzf = nil,
    },

    cache = {
        --- @type string
        dir = string.format(
            "%s%sfzfx.nvim",
            vim.fn.stdpath("data"),
            constants.path_separator
        ),
    },

    -- debug
    debug = {
        enable = false,
        console_log = true,
        file_log = false,
    },
}

--- @type Config
local Configs = {}

--- @param options Config|nil
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
