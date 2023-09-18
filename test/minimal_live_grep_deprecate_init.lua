vim.o.number = true
vim.o.autoread = true
vim.o.autowrite = true
vim.o.swapfile = false
vim.o.confirm = true
vim.o.termguicolors = true
vim.o.showcmd = true
vim.o.cmdheight = 2

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local opts = {
    defaults = { lazy = false },
}

--- @type table<string, FzfOpt>
local default_fzf_options = {
    multi = "--multi",
    toggle = "--bind=ctrl-e:toggle",
    toggle_all = "--bind=ctrl-a:toggle-all",
    toggle_preview = "--bind=alt-p:toggle-preview",
    preview_half_page_down = "--bind=ctrl-f:preview-half-page-down",
    preview_half_page_up = "--bind=ctrl-b:preview-half-page-up",
    no_multi = "--no-multi",
}

local default_restricted_rg = "rg --column -n --no-heading --color=always -S"
local default_unrestricted_rg =
    "rg --column -n --no-heading --color=always -S -uu"

require("lazy").setup({
    "folke/tokyonight.nvim",
    "nvim-tree/nvim-web-devicons",
    {
        "junegunn/fzf",
        build = ":call fzf#install()",
    },
    {
        "linrongbin16/fzfx.nvim",
        dev = true,
        dir = "~/github/linrongbin16/fzfx.nvim",
        config = function()
            require("fzfx").setup({
                debug = {
                    enable = false,
                    file_log = true,
                },
                -- the 'Live Grep' commands
                live_grep = {
                    --- @type CommandConfig[]
                    commands = {
                        -- normal
                        {
                            name = "FzfxLiveGrep",
                            feed = require("fzfx.meta").CommandFeedEnum.ARGS,
                            opts = {
                                bang = true,
                                nargs = "*",
                                desc = "Live grep",
                            },
                            default_provider = "restricted",
                        },
                        {
                            name = "FzfxLiveGrepU",
                            feed = require("fzfx.meta").CommandFeedEnum.ARGS,
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
                            feed = require("fzfx.meta").CommandFeedEnum.VISUAL,
                            opts = {
                                bang = true,
                                range = true,
                                desc = "Live grep by visual select",
                            },
                            default_provider = "restricted",
                        },
                        {
                            name = "FzfxLiveGrepUV",
                            feed = require("fzfx.meta").CommandFeedEnum.VISUAL,
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
                            feed = require("fzfx.meta").CommandFeedEnum.CWORD,
                            opts = {
                                bang = true,
                                desc = "Live grep by cursor word",
                            },
                            default_provider = "restricted",
                        },
                        {
                            name = "FzfxLiveGrepUW",
                            feed = require("fzfx.meta").CommandFeedEnum.CWORD,
                            opts = {
                                bang = true,
                                desc = "Live grep unrestricted by cursor word",
                            },
                            default_provider = "unrestricted",
                        },
                        -- put
                        {
                            name = "FzfxLiveGrepP",
                            feed = require("fzfx.meta").CommandFeedEnum.PUT,
                            opts = {
                                bang = true,
                                desc = "Live grep by yank text",
                            },
                            default_provider = "restricted",
                        },
                        {
                            name = "FzfxLiveGrepUP",
                            feed = require("fzfx.meta").CommandFeedEnum.PUT,
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
                            default_restricted_rg,
                        },
                        unrestricted = {
                            "ctrl-u",
                            default_unrestricted_rg,
                        },
                    },
                    actions = {
                        ["esc"] = require("fzfx.actions").nop,
                        ["enter"] = require("fzfx.actions").edit_rg,
                        ["double-click"] = require("fzfx.actions").edit_rg,
                    },
                    fzf_opts = {
                        default_fzf_options.multi,
                        { "--prompt", "Live Grep > " },
                        { "--delimiter", ":" },
                        { "--preview-window", "+{2}-/2" },
                    },
                    other_opts = {
                        onchange_reload_delay = (
                            vim.fn.executable("sleep") > 0
                            and not require("fzfx.constants").is_windows
                        )
                                and "sleep 0.1 && "
                            or nil,
                    },
                },
            })
        end,
        dependencies = {
            "folke/tokyonight.nvim",
            "nvim-tree/nvim-web-devicons",
            "junegunn/fzf",
        },
    },
}, opts)

require("lazy").sync({ wait = true, show = false })

vim.cmd([[
colorscheme tokyonight
]])
