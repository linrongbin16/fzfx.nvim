local constants = require("fzfx.constants")
local utils = require("fzfx.utils")
local UserCommandFeedEnum = require("fzfx.schema").UserCommandFeedEnum

-- find
-- local default_restricted_find_exclude_git = [[*/\.git/*]]
-- local default_restricted_find_exclude_svn = [[*/\.svn/*]]
-- local default_restricted_find_exclude_hg = [[*/\.hg/*]]
local default_restricted_find_exclude_hidden_folder = [[*/\.*]]
local default_restricted_find_exclude_hidden_file = [[.*]]
local default_restricted_find = string.format(
    [[find -L . -type f -not -path %s -not -name %s]],
    -- utils.shellescape(default_restricted_find_exclude_git),
    -- utils.shellescape(default_restricted_find_exclude_svn),
    -- utils.shellescape(default_restricted_find_exclude_hg),
    utils.shellescape(default_restricted_find_exclude_hidden_folder),
    utils.shellescape(default_restricted_find_exclude_hidden_file)
)
local default_unrestricted_find = [[find -L . -type f]]

-- fd
local default_restricted_fd =
    string.format("%s -cnever -tf -tl -L -i", constants.fd)
local default_unrestricted_fd =
    string.format("%s -cnever -tf -tl -L -i -u", constants.fd)

-- grep
-- local default_restricted_grep_exclude_git = ".git"
-- local default_restricted_grep_exclude_svn = ".svn"
-- local default_restricted_grep_exclude_hg = ".hg"
local default_restricted_grep_exclude_hidden = [[./.*]]
local default_restricted_grep = string.format(
    [[grep --color=always -n -H -r --exclude-dir=%s --exclude=%s]],
    -- utils.shellescape(default_restricted_grep_exclude_git),
    -- utils.shellescape(default_restricted_grep_exclude_svn),
    utils.shellescape(default_restricted_grep_exclude_hidden),
    utils.shellescape(default_restricted_grep_exclude_hidden)
)
local default_unrestricted_grep = [[grep --color=always -n -H -r]]

-- rg
local default_restricted_rg =
    string.format("%s --column -n --no-heading --color=always -S", constants.rg)
local default_unrestricted_rg = string.format(
    "%s --column -n --no-heading --color=always -S -uu",
    constants.rg
)

--- @type table<string, FzfOption>
local default_fzf_options = {
    multi = "--multi",
    toggle = "--bind=ctrl-e:toggle",
    toggle_all = "--bind=ctrl-a:toggle-all",
    toggle_preview = "--bind=alt-p:toggle-preview",
    preview_half_page_down = "--bind=ctrl-f:preview-half-page-down",
    preview_half_page_up = "--bind=ctrl-b:preview-half-page-up",
    no_multi = "--no-multi",
}

local default_git_log_pretty =
    "%C(yellow)%h %C(cyan)%cd %C(green)%aN%C(auto)%d %Creset%s"

--- @alias Configs table<string, any>

--- @type Configs
local Defaults = {
    -- the 'Files' commands
    files = {
        commands = {
            -- normal
            {
                name = "FzfxFiles",
                feed = UserCommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find files",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxFilesU",
                feed = UserCommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find files",
                },
                default_provider = "unrestricted",
            },
            -- visual
            {
                name = "FzfxFilesV",
                feed = UserCommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find files by visual select",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxFilesUV",
                feed = UserCommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find files unrestricted by visual select",
                },
                default_provider = "unrestricted",
            },
            -- cword
            {
                name = "FzfxFilesW",
                feed = UserCommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find files by cursor word",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxFilesUW",
                feed = UserCommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find files unrestricted by cursor word",
                },
                default_provider = "unrestricted",
            },
            -- put
            {
                name = "FzfxFilesP",
                feed = UserCommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find files by yank text",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxFilesUP",
                feed = UserCommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find files unrestricted by yank text",
                },
                default_provider = "unrestricted",
            },
        },
        providers = {
            restricted = {
                "ctrl-r",
                constants.has_fd and default_restricted_fd
                    or default_restricted_find,
            },
            unrestricted = {
                "ctrl-u",
                constants.has_fd and default_unrestricted_fd
                    or default_unrestricted_find,
            },
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").edit,
            ["double-click"] = require("fzfx.actions").edit,
        },
        fzf_opts = {
            default_fzf_options.multi,
            default_fzf_options.toggle,
            default_fzf_options.toggle_all,
            default_fzf_options.preview_half_page_down,
            default_fzf_options.preview_half_page_up,
            default_fzf_options.toggle_preview,
            function()
                return {
                    "--prompt",
                    require("fzfx.path").shorten() .. " > ",
                }
            end,
        },
    },

    -- the 'Live Grep' commands
    live_grep = {
        commands = {
            -- normal
            {
                name = "FzfxLiveGrep",
                feed = UserCommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "*",
                    desc = "Live grep",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxLiveGrepU",
                feed = UserCommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "*",
                    desc = "Live grep unrestricted",
                },
                default_provider = "unrestricted",
            },
            -- visual
            {
                name = "FzfxLiveGrepV",
                feed = UserCommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Live grep by visual select",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxLiveGrepUV",
                feed = UserCommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Live grep unrestricted by visual select",
                },
                default_provider = "unrestricted",
            },
            -- cword
            {
                name = "FzfxLiveGrepW",
                feed = UserCommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Live grep by cursor word",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxLiveGrepUW",
                feed = UserCommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Live grep unrestricted by cursor word",
                },
                default_provider = "unrestricted",
            },
            -- put
            {
                name = "FzfxLiveGrepP",
                feed = UserCommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Live grep by yank text",
                },
                default_provider = "restricted",
            },
            {
                name = "FzfxLiveGrepUP",
                feed = UserCommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Live grep unrestricted by yank text",
                },
                default_provider = "unrestricted",
            },
        },
        providers = {
            restricted = {
                "ctrl-r",
                constants.has_rg and default_restricted_rg
                    or default_restricted_grep,
            },
            unrestricted = {
                "ctrl-u",
                constants.has_rg and default_unrestricted_rg
                    or default_unrestricted_grep,
            },
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = constants.has_rg and require("fzfx.actions").edit_rg
                or require("fzfx.actions").edit_grep,
            ["double-click"] = constants.has_rg
                    and require("fzfx.actions").edit_rg
                or require("fzfx.actions").edit_grep,
        },
        fzf_opts = {
            default_fzf_options.multi,
            default_fzf_options.toggle,
            default_fzf_options.toggle_all,
            default_fzf_options.preview_half_page_down,
            default_fzf_options.preview_half_page_up,
            default_fzf_options.toggle_preview,
            { "--prompt", "Live Grep > " },
            { "--delimiter", ":" },
            { "--preview-window", "+{2}-/2" },
        },
        other_opts = {
            onchange_reload_delay = vim.fn.executable("sleep") > 0
                    and "sleep 0.1 && "
                or nil,
        },
    },

    -- the 'Buffers' commands
    buffers = {
        commands = {
            -- normal
            {
                name = "FzfxBuffers",
                feed = UserCommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "file",
                    desc = "Find buffers",
                },
            },
            -- visual
            {
                name = "FzfxBuffersV",
                feed = UserCommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find buffers by visual select",
                },
            },
            -- cword
            {
                name = "FzfxBuffersW",
                feed = UserCommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find buffers by cursor word",
                },
            },
            -- put
            {
                name = "FzfxBuffersP",
                feed = UserCommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find buffers by yank text",
                },
            },
        },
        interactions = {
            "ctrl-d",
            require("fzfx.actions").bdelete,
        },
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").buffer,
            ["double-click"] = require("fzfx.actions").buffer,
        },
        fzf_opts = {
            default_fzf_options.multi,
            default_fzf_options.toggle,
            default_fzf_options.toggle_all,
            default_fzf_options.preview_half_page_down,
            default_fzf_options.preview_half_page_up,
            default_fzf_options.toggle_preview,
            {
                "--prompt",
                "Buffers > ",
            },
        },
        other_opts = {
            exclude_filetypes = { "qf", "neo-tree" },
        },
    },

    -- the 'Git Files' commands
    git_files = {
        commands = {
            -- normal
            {
                name = "FzfxGFiles",
                feed = UserCommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find git files",
                },
            },
            -- visual
            {
                name = "FzfxGFilesV",
                feed = UserCommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find git files by visual select",
                },
            },
            -- cword
            {
                name = "FzfxGFilesW",
                feed = UserCommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find git files by cursor word",
                },
            },
            -- put
            {
                name = "FzfxGFilesP",
                feed = UserCommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find git files by yank text",
                },
            },
        },
        providers = "git ls-files",
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").edit,
            ["double-click"] = require("fzfx.actions").edit,
        },
        fzf_opts = {
            default_fzf_options.multi,
            default_fzf_options.toggle,
            default_fzf_options.toggle_all,
            default_fzf_options.preview_half_page_down,
            default_fzf_options.preview_half_page_up,
            default_fzf_options.toggle_preview,
            function()
                return {
                    "--prompt",
                    require("fzfx.path").shorten() .. " > ",
                }
            end,
        },
    },

    -- the 'Git Branches' commands
    git_branches = {
        commands = {
            -- normal
            {
                name = "FzfxGBranches",
                feed = UserCommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find local git branches",
                },
                default_provider = "local_branch",
            },
            {
                name = "FzfxGBranchesR",
                feed = UserCommandFeedEnum.ARGS,
                opts = {
                    bang = true,
                    nargs = "?",
                    complete = "dir",
                    desc = "Find remote git branches",
                },
                default_provider = "remote_branch",
            },
            -- visual
            {
                name = "FzfxGBranchesV",
                feed = UserCommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find local git branches by visual select",
                },
                default_provider = "local_branch",
            },
            {
                name = "FzfxGBranchesRV",
                feed = UserCommandFeedEnum.VISUAL,
                opts = {
                    bang = true,
                    range = true,
                    desc = "Find remote git branches by visual select",
                },
                default_provider = "remote_branch",
            },
            -- cword
            {
                name = "FzfxGBranchesW",
                feed = UserCommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find local git branches by cursor word",
                },
                default_provider = "local_branch",
            },
            {
                name = "FzfxGBranchesRW",
                feed = UserCommandFeedEnum.CWORD,
                opts = {
                    bang = true,
                    desc = "Find remote git branches by cursor word",
                },
                default_provider = "remote_branch",
            },
            -- put
            {
                name = "FzfxGBranchesP",
                feed = UserCommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find local git branches by yank text",
                },
                default_provider = "local_branch",
            },
            {
                name = "FzfxGBranchesRP",
                feed = UserCommandFeedEnum.PUT,
                opts = {
                    bang = true,
                    desc = "Find remote git branches by yank text",
                },
                default_provider = "remote_branch",
            },
        },
        providers = {
            local_branch = { "ctrl-o", "git branch" },
            remote_branch = { "ctrl-r", "git branch --remotes" },
        },
        -- "git log --graph --date=short --color=always --pretty='%C(auto)%cd %h%d %s'",
        -- "git log --graph --color=always --date=relative",
        previewers = string.format(
            "git log --pretty=%s --graph --date=relative --color=always",
            utils.shellescape(default_git_log_pretty)
        ),
        actions = {
            ["esc"] = require("fzfx.actions").nop,
            ["enter"] = require("fzfx.actions").git_checkout,
            ["double-click"] = require("fzfx.actions").git_checkout,
        },
        fzf_opts = {
            default_fzf_options.no_multi,
            default_fzf_options.preview_half_page_down,
            default_fzf_options.preview_half_page_up,
            default_fzf_options.toggle_preview,
            {
                "--prompt",
                "GBranches > ",
            },
        },
    },

    -- the 'Yank History' commands
    yank_history = {
        other_opts = {
            maxsize = 100,
        },
    },

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

    -- nerd fonts: https://www.nerdfonts.com/cheat-sheet
    -- unicode: https://symbl.cc/en/
    icons = {
        -- nerd fonts:
        --     nf-fa-file_text_o               \uf0f6 (default)
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
        --     nf-fa-caret_right               \uf0da
        --     nf-weather-direction_right      \ue349
        --     nf-fa-long_arrow_right          \uf178
        --     nf-oct-chevron_right            \uf460
        --     nf-fa-chevron_right             \uf054 (default)
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
        -- ✓    U+2713                          &#10003; (default)
        fzf_marker = "✓",
    },

    popup = {
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

--- @type Configs
local Configs = {}

--- @param options Configs|nil
--- @return Configs
local function setup(options)
    Configs = vim.tbl_deep_extend("force", Defaults, options or {})
    return Configs
end

--- @return Configs
local function get_config()
    return Configs
end

local M = {
    setup = setup,
    get_config = get_config,
}

return M
