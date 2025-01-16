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

  describe("[_shellescape_posix]", function()
    it("case-1", function()
      local input = "hello world"
      local expect = [['hello world']]
      local actual = shells._shellescape_posix(input)
      print(
        string.format(
          "case-1 input:%s, expect:%s, actual:%s\n",
          vim.inspect(input),
          vim.inspect(expect),
          vim.inspect(actual)
        )
      )
      assert_eq(expect, actual)
    end)
    it("case-2", function()
      local input = "'hello world'"
      local expect = [[''\''hello world'\''']]
      local actual = shells._shellescape_posix(input)
      print(
        string.format(
          "case-2 input:%s, expect:%s, actual:%s\n",
          vim.inspect(input),
          vim.inspect(expect),
          vim.inspect(actual)
        )
      )
      assert_eq(expect, actual)
    end)
    it("case-3", function()
      local input = [['"hello world'"]]
      local expect = [[''\''"hello world'\''"']]
      local actual = shells._shellescape_posix(input)
      print(
        string.format(
          "normal-case-3 input:%s, expect:%s, actual:%s\n",
          vim.inspect(input),
          vim.inspect(expect),
          vim.inspect(actual)
        )
      )
      assert_eq(expect, actual)
    end)
  end)
end)
