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
  {
    "linrongbin16/fzfx.nvim",
    dev = true,
    opts = {
      buffers = {
        fzf_opts = {
          "--info=hidden --header= --padding=0",
        },
        win_opts = function()
          local bufs_fn_len = {}
          local max_len = 0
          for _, buf_nr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf_nr) then
              local buf = vim.api.nvim_buf_get_name(buf_nr)
              local buf_nm = vim.fn.expand(buf)
              if buf_nm ~= "" then
                buf_nm = vim.fn.substitute(buf_nm, vim.fn.getcwd(), "", "g")
                buf_nm = vim.fn.substitute(buf_nm, vim.fn.expand("$HOME"), "~", "g")
                buf_nm = vim.fs.basename(buf_nm)
                table.insert(bufs_fn_len, string.len(buf_nm))
              end
            end
          end
          for _, len in ipairs(bufs_fn_len) do
            max_len = math.max(max_len, len)
          end
          return {
            height = #bufs_fn_len + 4,
            width = max_len + 7,
            relative = "win",
            zindex = 51,
          }
        end,
      },
    },
    dependencies = {
      "folke/tokyonight.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "junegunn/fzf",
        build = function()
          vim.fn["fzf#install"]()
        end,
      },
    },
  },
}, { dev = { path = "~/github/linrongbin16" }, defaults = { lazy = false } })

require("lazy").sync({ wait = true, show = false })

vim.cmd([[colorscheme tokyonight]])
