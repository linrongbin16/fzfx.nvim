local cwd = vim.fn.getcwd()

describe("deprecated", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local deprecated = require("fzfx.deprecated")
  describe("[notify]", function()
    it("notify without parameters", function()
      deprecated.notify("deprecated 'GroupConfig', please use pure lua table!")
      assert_true(true)
    end)
    it("notify with parameters", function()
      deprecated.notify("notify with parameters: %s, %d, %f", "asdf", 2, 3.14)
      assert_true(true)
    end)
  end)
end)
