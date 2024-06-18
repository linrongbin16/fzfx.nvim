local cwd = vim.fn.getcwd()

describe("lib.lsp", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local lsp = require("fzfx.lib.lsp")

  describe("[get_clients]", function()
    it("is callable", function()
      assert_true(vim.is_callable(lsp.get_clients))
    end)
  end)
end)
