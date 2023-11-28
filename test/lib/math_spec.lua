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
    it("bound", function()
      assert_eq(maths.bound(5, 1, 3), 3)
      assert_eq(maths.bound(2, 1, 13), 2)
      assert_eq(maths.bound(77), 77)
      assert_eq(maths.bound(77, nil, 29), 29)
    end)
  end)
end)
