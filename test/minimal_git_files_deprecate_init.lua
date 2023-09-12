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
                -- the 'Git Files' commands
                git_files = {
                    commands = {
                        -- normal
                        {
                            name = "FzfxGFiles",
                            feed = require("fzfx.meta").CommandFeedEnum.ARGS,
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
                            feed = require("fzfx.meta").CommandFeedEnum.VISUAL,
                            opts = {
                                bang = true,
                                range = true,
                                desc = "Find git files by visual select",
                            },
                        },
                        -- cword
                        {
                            name = "FzfxGFilesW",
                            feed = require("fzfx.meta").CommandFeedEnum.CWORD,
                            opts = {
                                bang = true,
                                desc = "Find git files by cursor word",
                            },
                        },
                        -- put
                        {
                            name = "FzfxGFilesP",
                            feed = require("fzfx.meta").CommandFeedEnum.PUT,
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
