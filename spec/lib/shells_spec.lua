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
    it("normal-1", function()
      local input1 = "hello world"
      local expect1 = [['hello world']]
      local actual1 = shells._shellescape_posix(input1)
      print(
        string.format(
          "normal-case-1 input:%s, expect:%s, actual:%s\n",
          vim.inspect(input1),
          vim.inspect(expect1),
          vim.inspect(actual1)
        )
      )
      assert_eq(expect1, actual1)

      local input2 = "'hello world'"
      local expect2 = [[''\''hello world'\''']]
      local actual2 = shells._shellescape_posix(input2)
      print(
        string.format(
          "normal-case-2 input:%s, expect:%s, actual:%s\n",
          vim.inspect(input2),
          vim.inspect(expect2),
          vim.inspect(actual2)
        )
      )
      assert_eq(expect2, actual2)

      local input3 = [['"hello world'"]]
      local expect3 = [[''\''"hello world'\''"']]
      local actual3 = shells._shellescape_posix(input3)
      print(
        string.format(
          "normal-case-3 input:%s, expect:%s, actual:%s\n",
          vim.inspect(input3),
          vim.inspect(expect3),
          vim.inspect(actual3)
        )
      )
      assert_eq(expect3, actual3)
    end)
  end)
end)
