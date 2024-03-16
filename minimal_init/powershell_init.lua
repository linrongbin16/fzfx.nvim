if vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0 then
  vim.o.shell = "powershell.exe"
  vim.o.shellslash = true
  vim.o.shellxquote = ""
  vim.o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command "
  vim.o.shellquote = ""
  vim.o.shellpipe = "| Out-File -Encoding UTF8 %s"
  vim.o.shellredir = "| Out-File -Encoding UTF8 %s"
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

require("lazy").setup({
  "folke/tokyonight.nvim",
  "nvim-tree/nvim-web-devicons",
  {
    "junegunn/fzf",
    build = ":call fzf#install()",
  },
  {
    -- "linrongbin16/fzfx.nvim",
    dir = "~/github/linrongbin16/fzfx.nvim",
    dev = true,
    opts = {
      env = {
        nvim = "nvim",
      },
      debug = {
        enable = false,
        file_log = true,
        console_log = false,
      },
    },
    dependencies = {
      "folke/tokyonight.nvim",
      "nvim-tree/nvim-web-devicons",
      "junegunn/fzf",
    },
  },
}, { dev = { path = "~/github/linrongbin16" }, defaults = { lazy = false } })

require("lazy").sync({ wait = true, show = false })

vim.cmd([[
colorscheme tokyonight
]])
