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

local default_git_log_pretty =
    "%C(yellow)%h %C(cyan)%cd %C(green)%aN%C(auto)%d %Creset%s"

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
                -- the 'Git Branches' commands
                git_branches = {
                    commands = {
                        -- normal
                        {
                            name = "FzfxGBranches",
                            feed = require("fzfx.meta").CommandFeedEnum.ARGS,
                            opts = {
                                bang = true,
                                nargs = "?",
                                complete = "dir",
                                desc = "Search local git branches",
                            },
                            default_provider = "local_branch",
                        },
                        {
                            name = "FzfxGBranchesR",
                            feed = require("fzfx.meta").CommandFeedEnum.ARGS,
                            opts = {
                                bang = true,
                                nargs = "?",
                                complete = "dir",
                                desc = "Search remote git branches",
                            },
                            default_provider = "remote_branch",
                        },
                        -- visual
                        {
                            name = "FzfxGBranchesV",
                            feed = require("fzfx.meta").CommandFeedEnum.VISUAL,
                            opts = {
                                bang = true,
                                range = true,
                                desc = "Search local git branches by visual select",
                            },
                            default_provider = "local_branch",
                        },
                        {
                            name = "FzfxGBranchesRV",
                            feed = require("fzfx.meta").CommandFeedEnum.VISUAL,
                            opts = {
                                bang = true,
                                range = true,
                                desc = "Search remote git branches by visual select",
                            },
                            default_provider = "remote_branch",
                        },
                        -- cword
                        {
                            name = "FzfxGBranchesW",
                            feed = require("fzfx.meta").CommandFeedEnum.CWORD,
                            opts = {
                                bang = true,
                                desc = "Search local git branches by cursor word",
                            },
                            default_provider = "local_branch",
                        },
                        {
                            name = "FzfxGBranchesRW",
                            feed = require("fzfx.meta").CommandFeedEnum.CWORD,
                            opts = {
                                bang = true,
                                desc = "Search remote git branches by cursor word",
                            },
                            default_provider = "remote_branch",
                        },
                        -- put
                        {
                            name = "FzfxGBranchesP",
                            feed = require("fzfx.meta").CommandFeedEnum.PUT,
                            opts = {
                                bang = true,
                                desc = "Search local git branches by yank text",
                            },
                            default_provider = "local_branch",
                        },
                        {
                            name = "FzfxGBranchesRP",
                            feed = require("fzfx.meta").CommandFeedEnum.PUT,
                            opts = {
                                bang = true,
                                desc = "Search remote git branches by yank text",
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
                        "git log --pretty=%s --graph --date=short --color=always",
                        require("fzfx.utils").shellescape(
                            default_git_log_pretty
                        )
                    ),
                    actions = {
                        ["esc"] = require("fzfx.actions").nop,
                        ["enter"] = require("fzfx.actions").git_checkout,
                        ["double-click"] = require("fzfx.actions").git_checkout,
                    },
                    fzf_opts = {
                        default_fzf_options.no_multi,
                        {
                            "--prompt",
                            "GBranches > ",
                        },
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
