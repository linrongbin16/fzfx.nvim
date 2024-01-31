local cwd = vim.fn.getcwd()

describe("fzfx", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.fn["fzf#exec"] = function()
      return "fzf"
    end
  end)

  describe("[setup]", function()
    it("is enabled", function()
      vim.cmd([[noautocmd edit README.md]])
      local setup = require("fzfx").setup
      local ok, err = pcall(setup)
      assert_eq(type(ok), "boolean")
    end)
  end)
end)
