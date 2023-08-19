if vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0 then
    vim.opt.shell = "powershell.exe"
    vim.opt.shellslash = true
    vim.opt.shellxquote = ""
    vim.opt.shellcmdflag =
        "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command "
    vim.opt.shellquote = ""
    vim.opt.shellpipe = "| Out-File -Encoding UTF8 %s"
    vim.opt.shellredir = "| Out-File -Encoding UTF8 %s"
end

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
        opts = {},
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
