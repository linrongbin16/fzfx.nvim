---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.paths", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local ps = require("fzfx.lib.paths")
  describe("[normalize]", function()
    it("unix", function()
      local expect1 = "~/github/linrongbin16/fzfx.nvim/lua/tests"
      local actual1 = ps.normalize(expect1)
      local expect2 = "~/github/linrongbin16/fzfx.nvim/lua/tests/test_path.lua"
      local actual2 = ps.normalize(expect2)
      assert_eq(actual1, expect1)
      assert_eq(actual2, expect2)
    end)
    it("windows", function()
      local actual1 = ps.normalize(
        [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests]]
      )
      local expect1 =
        [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests]]
      assert_eq(actual1, expect1)
      local actual2 = ps.normalize(
        [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests]],
        { backslash = true }
      )
      local expect2 =
        [[C:/Users/linrongbin/github/linrongbin16/fzfx.nvim/lua/tests]]
      assert_eq(actual2, expect2)
      local actual3 = ps.normalize(
        [[C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\lua\\tests\test_path.lua]]
      )
      local expect3 =
        [[C:\Users\linrongbin\github\linrongbin16\fzfx.nvim\lua\tests\test_path.lua]]
      assert_eq(actual3, expect3)
      local actual4 = ps.normalize(
        [[C:\\Users\\linrongbin\\github\\linrongbin16\\fzfx.nvim\\lua\\tests\\test_path.lua]],
        { backslash = true }
      )
      local expect4 =
        [[C:/Users/linrongbin/github/linrongbin16/fzfx.nvim/lua/tests/test_path.lua]]
      assert_eq(actual4, expect4)
    end)
  end)
  describe("[join]", function()
    it("test", function()
      local actual1 = ps.join("a", "b", "c")
      local expect1 = "a/b/c"
      assert_eq(actual1, expect1)
      local actual2 = ps.join("a")
      local expect2 = "a"
      assert_eq(actual2, expect2)
    end)
  end)
  describe("[shorten]", function()
    it("test", function()
      local expect1 = "~/.config/nvim/lazy/fzfx.nvim/test/path_spec.lua"
      local actual1 = ps.shorten(expect1)
      print(string.format("expect(%s) shorten: %s\n", expect1, actual1))
      assert_eq(type(actual1), "string")
      assert_true(string.len(actual1) < string.len(expect1))
    end)
  end)
  describe("[reduce]", function()
    it("test", function()
      local expect1 = "~/.config/nvim/lazy/fzfx.nvim/test/path_spec.lua"
      local actual1 = ps.reduce(expect1)
      print(string.format("expect(%s) reduce: %s\n", expect1, actual1))
      assert_eq(type(actual1), "string")
      assert_eq(expect1, actual1)
    end)
  end)
  describe("[reduce2home]", function()
    it("test", function()
      local expect1 = "~/.config/nvim/lazy/fzfx.nvim/test/path_spec.lua"
      local actual1 = ps.reduce2home(expect1)
      print(string.format("expect(%s) reduce2home: %s\n", expect1, actual1))
      assert_eq(type(actual1), "string")
      assert_eq(expect1, actual1)
    end)
  end)
  describe("[make_pipe_name]", function()
    it("test", function()
      local tmp = ps.make_pipe_name()
      assert_true(string.len(tmp) > 0)
    end)
  end)
end)
