---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.commands", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  require("fzfx").setup()
  local CommandResult = require("fzfx.lib.commands").CommandResult
  local Command = require("fzfx.lib.commands").Command
  local cmds = require("fzfx.lib.commands")
  local tbls = require("fzfx.lib.tables")

  describe("[CommandResult]", function()
    it("new result is empty", function()
      local cr = CommandResult:new()
      assert_true(tbls.tbl_empty(cr.stdout))
      assert_true(tbls.tbl_empty(cr.stderr))
      assert_true(cr.code == nil)
    end)
    it("new result is not failed", function()
      local cr = CommandResult:new()
      assert_false(cr:failed())
    end)
  end)
  describe("[Command]", function()
    it("echo", function()
      local c = Command:run({ "echo", "1" })
      print(string.format("cmd(echo 1):%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_true(#c.result.stdout > 0)
      assert_eq(c.result.stdout[1], "1")
      assert_eq(type(c.result.stderr), "table")
      assert_eq(#c.result.stderr, 0)
      assert_eq(c.result.code, 0)
      assert_false(c:failed())
      assert_false(c.result:failed())
    end)
    it("failed", function()
      local c = Command:run({ "cat", "non_exists.txt" })
      print(string.format("cmd(cat non_exists.txt):%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_eq(#c.result.stdout, 0)
      assert_eq(type(c.result.stderr), "table")
      assert_eq(#c.result.stderr, 1)
      assert_eq(c.result.code, 1)
      assert_true(c:failed())
      assert_true(c.result:failed())
    end)
  end)
  describe("[GitRootCommand]", function()
    it("print git repo root", function()
      local c = cmds.GitRootCommand:run()
      print(string.format("cmd.GitRootCommand:%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_true(#c.result.stdout > 0)
      assert_false(c:failed())
      assert_eq(type(c:output()), "string")
      print(string.format("git root:%s\n", vim.inspect(c:output())))
      assert_true(string.len(c:output() --[[@as string]]) > 0)
    end)
  end)
  describe("[GitBranchesCommand]", function()
    it("echo git branches", function()
      local c = cmds.GitBranchesCommand:run()
      print(string.format("cmd.GitBranchesCommand:%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_true(#c.result.stdout > 0)
      assert_false(c:failed())
      assert_eq(type(c:output()), "table")
      print(string.format("git branches:%s\n", vim.inspect(c:output())))
      assert_true(#c:output() > 0)
      assert_true(string.len(c:output()[1]) > 0)
    end)
  end)
  describe("[GitCurrentBranchCommand]", function()
    it("echo git current branch", function()
      local c = cmds.GitCurrentBranchCommand:run()
      print(string.format("cmd.GitCurrentBranchCommand:%s\n", vim.inspect(c)))
      assert_eq(type(c), "table")
      assert_eq(type(c.result), "table")
      assert_eq(type(c.result.stdout), "table")
      assert_true(#c.result.stdout > 0)
      assert_false(c:failed())
      assert_eq(type(c:output()), "string")
      assert_true(string.len(c:output() --[[@as string]]) > 0)
      print(string.format("git current branch:%s\n", c:output()))
    end)
  end)
end)
