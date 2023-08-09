vim.o.number = true
vim.o.autoread = true
vim.o.autowrite = true
vim.o.swapfile = false
vim.o.confirm = true
vim.o.termguicolors = true

local lazypath = vim.fn.expand("<sfile>:p:h") .. "/lazy/lazy.nvim"
print("lazypath:" .. lazypath)

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
    root = vim.fn.expand("<sfile>:p:h") .. "/lazy",
}

require("lazy").setup({
    "folke/tokyonight.nvim",
    {
        "linrongbin16/fzfx.nvim",
        dev = true,
        dir = "~/github/linrongbin16/fzfx.nvim",
        opts = {},
        dependencies = {
            {
                "junegunn/fzf",
                build = ":call fzf#install()",
            },
        },
    },
}, opts)

vim.cmd([[
colorscheme tokyonight
]])
