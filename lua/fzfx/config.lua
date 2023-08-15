local constants = require("fzfx.constants")

local default_fd_command =
    string.format("%s -cnever -tf -tl -L -i", constants.fd)
local default_rg_command =
    string.format("%s --column -n --no-heading --color=always -S", constants.rg)
--- @type table<string, string|string[]>
local default_fzf_opts = {
    multi = "--multi",
    select = { "--bind", "ctrl-e:select" },
    deselect = { "--bind", "ctrl-d:deselect" },
    select_all = { "--bind", "ctrl-a:select-all" },
    deselect_all = { "--bind", "alt-a:deselect-all" },
    toggle_preview = { "--bind", "ctrl-l:toggle-preview" },
}

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
            default_fzf_opts.multi,
            default_fzf_opts.select,
            default_fzf_opts.deselect,
            default_fzf_opts.select_all,
            default_fzf_opts.deselect_all,
            default_fzf_opts.toggle_preview,
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
            default_fzf_opts.multi,
            default_fzf_opts.select,
            default_fzf_opts.deselect,
            default_fzf_opts.select_all,
            default_fzf_opts.deselect_all,
            default_fzf_opts.toggle_preview,
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
                        complete = "file",
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
                    name = "FzfxBuffersW",
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
                delete_buffer = {
                    "ctrl-x",
                    require("fzfx.action").bdelete,
                },
            },
            expect = {
                ["esc"] = require("fzfx.action").nop,
                ["enter"] = require("fzfx.action").edit,
                ["double-click"] = require("fzfx.action").edit,
            },
        },
        fzf_opts = {
            default_fzf_opts.multi,
            default_fzf_opts.select,
            default_fzf_opts.deselect,
            default_fzf_opts.select_all,
            default_fzf_opts.deselect_all,
            default_fzf_opts.toggle_preview,
        },
        other_opts = {
            exclude_filetypes = { "qf", "neo-tree" },
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
        "--border=rounded",
        "--height=100%",
    },

    -- fzf color options
    -- color design based on doc: https://man.archlinux.org/man/fzf.1.en
    --  * border (border): `Ignore` bg (not sure, `s:dark_bg + 3`, candidates: `MatchParen`, `Ignore`, `DiffChange`)
    --  * spinner (input indicator: > ): `Statement` bg (not sure, candidates: `Statement`, `diffAdded`)
    --  * hl+ (highlighted substring current line): `Statement` fg (not sure, candidates: `Statement`, `diffAdded`)
    fzf_color_opts = {
        enable = true,
        mappings = {
            -- bg
            bg = { "bg", "Normal" },
            ["bg+"] = { "bg", "CursorLine" },
            info = { "fg", "PreProc" },
            border = { "bg", "Ignore" },
            spinner = { "bg", "Statement" },
            hl = { "bg", "Comment" },
            -- fg
            fg = { "fg", "Normal" },
            header = { "fg", "Comment" },
            ["fg+"] = { "fg", "Normal" },
            pointer = { "fg", "Exception" },
            marker = { "fg", "Keyword" },
            prompt = { "fg", "Conditional" },
            ["hl+"] = { "fg", "Statement" },
        },
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

        border = "none",
        zindex = 51,
    },

    -- nerd fonts: https://www.nerdfonts.com/cheat-sheet
    -- unicode: https://symbl.cc/en/
    icon = {
        enable = true,

        -- nerd fonts:
        --     nf-fa-file_text_o               \uf0f6
        unknown_filetype = "",

        -- nerd fonts:
        --     nf-oct-arrow_right              \uf432
        --     nf-cod-arrow_right              \uea9c
        --     nf-fa-caret_right               \uf0da  (default)
        --     nf-weather-direction_right      \ue349
        --     nf-fa-long_arrow_right          \uf178
        --
        -- unicode:
        -- https://symbl.cc/en/collections/arrow-symbols/
        -- ➜    U+279C                          &#10140;
        -- ➤    U+27A4                          &#10148;
        fzf_pointer = "",

        -- nerd fonts:
        --     nf-fa-star                      \uf005
        -- 󰓎    nf-md-star                      \udb81\udcce
        --     nf-cod-star_full                \ueb59
        --     nf-oct-dot_fill                 \uf444  (default)
        --     nf-fa-dot_circle_o              \uf192
        --
        -- unicode:
        -- https://symbl.cc/en/collections/star-symbols/
        -- https://symbl.cc/en/collections/list-bullets/
        -- https://symbl.cc/en/collections/special-symbols/
        -- •    U+2022                          &#8226;
        -- ✓    U+2713                          &#10003;
        fzf_marker = "",
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
