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

-- fd
local default_restricted_fd = string.format(
    [[%s . -cnever -tf -tl -L -i]],
    vim.fn.executable("fdfind") > 0 and "fdfind" or "fd"
)
local default_unrestricted_fd = string.format(
    [[%s . -cnever -tf -tl -L -i -u]],
    vim.fn.executable("fdfind") > 0 and "fdfind" or "fd"
)
-- find
local default_restricted_find = string.format(
    [[%s -L . -type f]],
    vim.fn.executable("gfind") > 0 and "gfind" or "find"
)
local default_unrestricted_find = [[find -L . -type f]]

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
                    enable = true,
                    file_log = true,
                },
                -- the 'Files' commands
                files = {
                    --- @type CommandConfig[]
                    commands = {
                        -- normal
                        {
                            name = "FzfxFiles",
                            feed = require("fzfx.meta").CommandFeedEnum.ARGS,
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
                            feed = require("fzfx.meta").CommandFeedEnum.ARGS,
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
                            feed = require("fzfx.meta").CommandFeedEnum.VISUAL,
                            opts = {
                                bang = true,
                                range = true,
                                desc = "Find files by visual select",
                            },
                            default_provider = "restricted",
                        },
                        {
                            name = "FzfxFilesUV",
                            feed = require("fzfx.meta").CommandFeedEnum.VISUAL,
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
                            feed = require("fzfx.meta").CommandFeedEnum.CWORD,
                            opts = {
                                bang = true,
                                desc = "Find files by cursor word",
                            },
                            default_provider = "restricted",
                        },
                        {
                            name = "FzfxFilesUW",
                            feed = require("fzfx.meta").CommandFeedEnum.CWORD,
                            opts = {
                                bang = true,
                                desc = "Find files unrestricted by cursor word",
                            },
                            default_provider = "unrestricted",
                        },
                        -- put
                        {
                            name = "FzfxFilesP",
                            feed = require("fzfx.meta").CommandFeedEnum.PUT,
                            opts = {
                                bang = true,
                                desc = "Find files by yank text",
                            },
                            default_provider = "restricted",
                        },
                        {
                            name = "FzfxFilesUP",
                            feed = require("fzfx.meta").CommandFeedEnum.PUT,
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
                            (
                                vim.fn.executable("fd") > 0
                                or vim.fn.executable("fdfind") > 0
                            )
                                    and default_restricted_fd
                                or default_restricted_find,
                        },
                        unrestricted = {
                            "ctrl-u",
                            (
                                vim.fn.executable("fd") > 0
                                or vim.fn.executable("fdfind") > 0
                            )
                                    and default_unrestricted_fd
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
                        function()
                            return {
                                "--prompt",
                                require("fzfx.path").shorten() .. " > ",
                            }
                        end,
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
