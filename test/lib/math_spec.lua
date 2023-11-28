local cwd = vim.fn.getcwd()

describe("lib.math", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local maths = require("fzfx.lib.maths")

  describe("[test]", function()
    it("INT32_MIN/INT32_MAX", function()
      assert_eq(maths.INT32_MAX, 2 ^ 31 - 1)
      assert_eq(maths.INT32_MIN, -(2 ^ 31))
    end)
  end)
end)
