local cwd = vim.fn.getcwd()

describe("lib.shells", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local shells = require("fzfx.lib.shells")

  describe("[ShellContext]", function()
    it("save", function()
      local ctx = shells.ShellContext:save()
      assert_eq(type(ctx), "table")
    end)
    it("restore", function()
      local ctx = shells.ShellContext:save()
      assert_eq(type(ctx), "table")
      ctx:restore()
    end)
  end)
end)
