local cwd = vim.fn.getcwd()

describe("lib.bufs", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local bufs = require("fzfx.lib.bufs")
  describe("[buf_is_valid]", function()
    it("test", function()
      local bufnrs = vim.api.nvim_list_bufs()
      for _, bn in ipairs(bufnrs) do
        bufs.buf_is_valid(bn)
      end
    end)
  end)
end)
