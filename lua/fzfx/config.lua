local constants = require("fzfx.constants")

local default_fd_command =
    string.format("%s -cnever -tf -tl -L -i", constants.fd)
local default_rg_command =
    string.format("%s --column -n --no-heading --color=always -S", constants.rg)

--- @alias FzfOpt string|string[]
--- @alias FzfOpts FzfOpt[]
--- @type table<string, FzfOpt>
local fzf_opt_candidates = {
    multi = "--multi",
    toggle = { "--bind", "ctrl-e:toggle" },
    toggle_all = { "--bind", "ctrl-a:toggle-all" },
    toggle_preview = { "--bind", "alt-p:toggle-preview" },
    no_multi = "--no-multi",
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
            fzf_opt_candidates.multi,
            fzf_opt_candidates.toggle,
            fzf_opt_candidates.toggle_all,
            fzf_opt_candidates.toggle_preview,
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
            fzf_opt_candidates.multi,
            fzf_opt_candidates.toggle,
            fzf_opt_candidates.toggle_all,
            fzf_opt_candidates.toggle_preview,
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
                    "ctrl-d",
                    require("fzfx.action").bdelete,
                },
            },
            expect = {
                ["esc"] = require("fzfx.action").nop,
                ["enter"] = require("fzfx.action").buffer,
                ["double-click"] = require("fzfx.action").buffer,
            },
        },
        fzf_opts = {
            fzf_opt_candidates.multi,
            fzf_opt_candidates.toggle,
            fzf_opt_candidates.toggle_all,
            fzf_opt_candidates.toggle_preview,
        },
        other_opts = {
            exclude_filetypes = { "qf", "neo-tree" },
        },
    },

    -- the 'Git Files' commands
    git_files = {
        commands = {
            normal = {
                {
                    name = "FzfxGFiles",
                    opts = {
                        bang = true,
                        nargs = "?",
                        complete = "dir",
                        desc = "Find git files",
                    },
                },
            },
            visual = {
                {
                    name = "FzfxGFilesV",
                    opts = {
                        bang = true,
                        range = true,
                        desc = "Find git files by visual select",
                    },
                },
            },
            cword = {
                {
                    name = "FzfxGFilesW",
                    opts = {
                        bang = true,
                        desc = "Find git files by cursor word",
                    },
                },
            },
            put = {
                {
                    name = "FzfxGFilesP",
                    opts = {
                        bang = true,
                        desc = "Find git files by yank text",
                    },
                },
            },
        },
        providers = {
            ls_files = "git ls-files",
        },
        actions = {
            builtin = {},
            expect = {
                ["esc"] = require("fzfx.action").nop,
                ["enter"] = require("fzfx.action").edit,
                ["double-click"] = require("fzfx.action").edit,
            },
        },
        fzf_opts = {
            fzf_opt_candidates.multi,
            fzf_opt_candidates.toggle,
            fzf_opt_candidates.toggle_all,
            fzf_opt_candidates.toggle_preview,
        },
        other_opts = {},
    },

    -- the 'Git Branches' commands
    git_branches = {
        commands = {
            normal = {
                {
                    name = "FzfxGBranches",
                    remote = false,
                    opts = {
                        bang = true,
                        nargs = "?",
                        complete = "dir",
                        desc = "Find local git branches",
                    },
                },
                {
                    name = "FzfxGBranchesR",
                    remote = true,
                    opts = {
                        bang = true,
                        nargs = "?",
                        complete = "dir",
                        desc = "Find remote git branches",
                    },
                },
            },
            visual = {
                {
                    name = "FzfxGBranchesV",
                    remote = false,
                    opts = {
                        bang = true,
                        range = true,
                        desc = "Find local git branches by visual select",
                    },
                },
                {
                    name = "FzfxGBranchesRV",
                    remote = true,
                    opts = {
                        bang = true,
                        range = true,
                        desc = "Find remote git branches by visual select",
                    },
                },
            },
            cword = {
                {
                    name = "FzfxGBranchesW",
                    remote = false,
                    opts = {
                        bang = true,
                        desc = "Find local git branches by cursor word",
                    },
                },
                {
                    name = "FzfxGBranchesRW",
                    remote = true,
                    opts = {
                        bang = true,
                        desc = "Find remote git branches by cursor word",
                    },
                },
            },
            put = {
                {
                    name = "FzfxGBranchesP",
                    remote = false,
                    opts = {
                        bang = true,
                        desc = "Find local git branches by yank text",
                    },
                },
                {
                    name = "FzfxGBranchesRP",
                    remote = true,
                    opts = {
                        bang = true,
                        desc = "Find remote git branches by yank text",
                    },
                },
            },
        },
        providers = {
            local_branch = "git branch",
            remote_branch = "git branch --remotes",
        },
        previewers = {
            log = "git log --graph --date=short --color=always --pretty='%C(auto)%cd %h%d %s'",
        },
        actions = {
            builtin = {
                remote_mode = "ctrl-r",
                local_mode = "ctrl-o",
            },
            expect = {
                ["esc"] = require("fzfx.action").nop,
                ["enter"] = require("fzfx.action").git_checkout,
                ["double-click"] = require("fzfx.action").git_checkout,
            },
        },
        fzf_opts = {
            fzf_opt_candidates.no_multi,
            fzf_opt_candidates.toggle_preview,
        },
        other_opts = {},
    },

    -- the 'Yank History' commands
    yank_history = {
        other_opts = {
            history_size = 100,
        },
    },

    popup = {

        -- FZF_DEFAULT_OPTS
        fzf_opts = {
            "--ansi",
            "--info=inline",
            "--layout=reverse",
            "--border=rounded",
            "--height=100%",
        },

        -- fzf colors
        -- see: https://github.com/junegunn/fzf/blob/master/README-VIM.md#explanation-of-gfzf_colors
        fzf_color_opts = {
            fg = { "fg", "Normal" },
            bg = { "bg", "Normal" },
            hl = { "fg", "Comment" },
            ["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
            ["bg+"] = { "bg", "CursorLine", "CursorColumn" },
            ["hl+"] = { "fg", "Statement" },
            info = { "fg", "PreProc" },
            border = { "fg", "Ignore" },
            prompt = { "fg", "Conditional" },
            pointer = { "fg", "Exception" },
            marker = { "fg", "Keyword" },
            spinner = { "fg", "Label" },
            header = { "fg", "Comment" },
        },

        -- nvim float window options
        -- see: https://neovim.io/doc/user/api.html#nvim_open_win()
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
            -- nerd fonts:
            --     nf-fa-file_text_o               \uf0f6  (default)
            --     nf-fa-file_o                    \uf016
            unknown_file = "",

            -- nerd fonts:
            --     nf-custom-folder                \ue5ff (default)
            --     nf-fa-folder                    \uf07b
            -- 󰉋    nf-md-folder                    \udb80\ude4b
            folder = "",

            -- nerd fonts:
            --     nf-custom-folder_open           \ue5fe (default)
            --     nf-fa-folder_open               \uf07c
            -- 󰝰    nf-md-folder_open               \udb81\udf70
            folder_open = "",

            -- nerd fonts:
            --     nf-oct-arrow_right              \uf432
            --     nf-cod-arrow_right              \uea9c
            --     nf-fa-caret_right               \uf0da  (default)
            --     nf-weather-direction_right      \ue349
            --     nf-fa-long_arrow_right          \uf178
            --     nf-oct-chevron_right            \uf460
            --     nf-fa-chevron_right             \uf054
            --
            -- unicode:
            -- https://symbl.cc/en/collections/arrow-symbols/
            -- ➜    U+279C                          &#10140;
            -- ➤    U+27A4                          &#10148;
            fzf_pointer = "",

            -- nerd fonts:
            --     nf-fa-star                      \uf005
            -- 󰓎    nf-md-star                      \udb81\udcce
            --     nf-cod-star_full                \ueb59
            --     nf-oct-dot_fill                 \uf444
            --     nf-fa-dot_circle_o              \uf192
            --     nf-cod-check                    \ueab2
            --     nf-fa-check                     \uf00c
            -- 󰄬    nf-md-check                     \udb80\udd2c
            --
            -- unicode:
            -- https://symbl.cc/en/collections/star-symbols/
            -- https://symbl.cc/en/collections/list-bullets/
            -- https://symbl.cc/en/collections/special-symbols/
            -- •    U+2022                          &#8226;
            -- ✓    U+2713                          &#10003;  (default)
            fzf_marker = "✓",
        },
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
