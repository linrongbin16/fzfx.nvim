local cwd = vim.fn.getcwd()

describe("lib.constants", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local constants = require("fzfx.lib.constants")

  describe("[test]", function()
    it("os", function()
      assert_eq(type(constants.IS_WINDOWS), "boolean")
      assert_false(constants.IS_WINDOWS)
      assert_eq(type(constants.IS_MACOS), "boolean")
      assert_eq(type(constants.IS_LINUX), "boolean")
      assert_eq(type(constants.IS_BSD), "boolean")
    end)
    it("cli", function()
      -- bat/cat
      assert_eq(type(constants.HAS_BAT), "boolean")
      assert_true(constants.BAT == "bat" or constants.BAT == "batcat")
      assert_eq(type(constants.HAS_CAT), "boolean")
      assert_true(constants.CAT == "cat")

      -- rg/grep
      assert_eq(type(constants.HAS_RG), "boolean")
      assert_true(constants.RG == "rg")
      assert_eq(type(constants.HAS_GNU_GREP), "boolean")
      assert_true(constants.GNU_GREP == "grep" or constants.GNU_GREP == "ggrep")
      assert_eq(type(constants.HAS_GREP), "boolean")
      assert_true(constants.GREP == "grep" or constants.GREP == "ggrep")

      -- fd/find
      assert_eq(type(constants.HAS_FD), "boolean")
      assert_true(constants.FD == "fd" or constants.FD == "fdfind")
      assert_eq(type(constants.HAS_GNU_GREP), "boolean")
      assert_true(constants.GNU_GREP == "grep" or constants.GNU_GREP == "ggrep")
      assert_eq(type(constants.HAS_GREP), "boolean")
      assert_true(constants.GREP == "grep" or constants.GREP == "ggrep")
    end)
  end)
  describe("[Cmd]", function()
    it("echo", function()
      local c = Cmd:run({ "echo", "1" })
      print(string.format("cmd(echo 1):%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_eq(#c.result.stdout, 1)
      assert_eq(c.result.stdout[1], "1")
      assert_eq(type(c.result.stderr), "table")
      assert_eq(#c.result.stderr, 0)
      assert_eq(c.result.code, 0)
      assert_false(c:wrong())
      assert_false(c.result:wrong())
    end)
    it("wrong", function()
      local c = Cmd:run({ "cat", "non_exists.txt" })
      print(string.format("cmd(cat non_exists.txt):%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_eq(#c.result.stdout, 0)
      assert_eq(type(c.result.stderr), "table")
      assert_eq(#c.result.stderr, 1)
      assert_eq(c.result.code, 1)
      assert_true(c:wrong())
      assert_true(c.result:wrong())
    end)
  end)
  local cmd = require("fzfx.cmd")
  describe("[GitRootCmd]", function()
    it("print git repo root", function()
      local c = cmd.GitRootCmd:run()
      print(string.format("cmd.GitRootCmd:%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_eq(#c.result.stdout, 1)
      assert_false(c:wrong())
      assert_eq(type(c:value()), "string")
      print(string.format("git root:%s\n", c:value()))
      assert_true(string.len(c:value() --[[@as string]]) > 0)
    end)
  end)
  describe("[GitBranchCmd]", function()
    it("echo git branches", function()
      local c = cmd.GitBranchCmd:run()
      print(string.format("cmd.GitBranchCmd:%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_true(#c.result.stdout > 0)
      assert_false(c:wrong())
      assert_eq(type(c:value()), "table")
      print(string.format("git branches:%s\n", vim.inspect(c:value())))
      assert_true(#c:value() > 0)
      assert_true(string.len(c:value()[1]) > 0)
    end)
  end)
  describe("[GitCurrentBranchCmd]", function()
    it("echo git current branch", function()
      local c = cmd.GitCurrentBranchCmd:run()
      print(string.format("cmd.GitCurrentBranchCmd:%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_eq(#c.result.stdout, 1)
      assert_false(c:wrong())
      assert_eq(type(c:value()), "string")
      print(string.format("git current branch:%s\n", c:value()))
      assert_true(string.len(c:value() --[[@as string]]) > 0)
    end)
  end)
end)
