vim.o.number = true
vim.o.autoread = true
vim.o.autowrite = true
vim.o.swapfile = false
vim.o.confirm = true
vim.o.termguicolors = true

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
                git_commits = {
                    commands = {
                        -- normal
                        {
                            name = "FzfxGCommits",
                            feed = require("fzfx.meta").CommandFeedEnum.ARGS,
                            opts = {
                                bang = true,
                                nargs = "?",
                                desc = "Search git commits",
                            },
                            default_provider = "all_commits",
                        },
                        {
                            name = "FzfxGCommitsB",
                            feed = require("fzfx.meta").CommandFeedEnum.ARGS,
                            opts = {
                                bang = true,
                                nargs = "?",
                                desc = "Search git commits only on current buffer",
                            },
                            default_provider = "buffer_commits",
                        },
                        -- visual
                        {
                            name = "FzfxGCommitsV",
                            feed = require("fzfx.meta").CommandFeedEnum.VISUAL,
                            opts = {
                                bang = true,
                                range = true,
                                desc = "Search git commits by visual select",
                            },
                            default_provider = "all_commits",
                        },
                        {
                            name = "FzfxGCommitsBV",
                            feed = require("fzfx.meta").CommandFeedEnum.VISUAL,
                            opts = {
                                bang = true,
                                range = true,
                                desc = "Search git commits only on current buffer by visual select",
                            },
                            default_provider = "buffer_commits",
                        },
                        -- cword
                        {
                            name = "FzfxGCommitsW",
                            feed = require("fzfx.meta").CommandFeedEnum.CWORD,
                            opts = {
                                bang = true,
                                desc = "Search git commits by cursor word",
                            },
                            default_provider = "all_commits",
                        },
                        {
                            name = "FzfxGCommitsBW",
                            feed = require("fzfx.meta").CommandFeedEnum.CWORD,
                            opts = {
                                bang = true,
                                desc = "Search git commits only on current buffer by cursor word",
                            },
                            default_provider = "buffer_commits",
                        },
                        -- put
                        {
                            name = "FzfxGCommitsP",
                            feed = require("fzfx.meta").CommandFeedEnum.PUT,
                            opts = {
                                bang = true,
                                desc = "Search git commits by yank text",
                            },
                            default_provider = "all_commits",
                        },
                        {
                            name = "FzfxGCommitsBP",
                            feed = require("fzfx.meta").CommandFeedEnum.PUT,
                            opts = {
                                bang = true,
                                desc = "Search git commits only on current buffer by yank text",
                            },
                            default_provider = "buffer_commits",
                        },
                    },
                    providers = {
                        all_commits = {
                            "ctrl-a",
                            string.format(
                                "git log --pretty=%s --date=short --color=always",
                                require("fzfx.utils").shellescape(
                                    default_git_log_pretty
                                )
                            ),
                        },
                        buffer_commits = {
                            "ctrl-u",
                            string.format(
                                "git log --pretty=%s --date=short --color=always",
                                require("fzfx.utils").shellescape(
                                    default_git_log_pretty
                                )
                            ),
                        },
                    },
                    previewers = "git show --color=always",
                    actions = {
                        ["esc"] = require("fzfx.actions").nop,
                        ["enter"] = require("fzfx.actions").yank_git_commit,
                        ["double-click"] = require("fzfx.actions").yank_git_commit,
                    },
                    fzf_opts = {
                        default_fzf_options.no_multi,
                        default_fzf_options.preview_half_page_down,
                        default_fzf_options.preview_half_page_up,
                        default_fzf_options.toggle_preview,
                        {
                            "--prompt",
                            "GCommits > ",
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
