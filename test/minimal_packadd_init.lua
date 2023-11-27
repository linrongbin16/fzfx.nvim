vim.o.number = true
vim.o.autoread = true
vim.o.autowrite = true
vim.o.swapfile = false
vim.o.confirm = true

vim.cmd([[packadd fzfx.nvim]])
require("fzfx").setup()
