---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.tables", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local libtbl = require("fzfx.lib.tables")

  describe("strings", function()
    it("tbl", function()
      assert_true(libtbl.tbl_empty(nil))
      assert_true(libtbl.tbl_empty({}))
      assert_false(libtbl.tbl_empty({ 1, 2, 3 }))
      assert_false(libtbl.tbl_empty({ a = 1 }))
    end)
    it("list", function()
      assert_true(libtbl.list_empty(nil))
      assert_true(libtbl.list_empty({}))
      assert_false(libtbl.list_empty({ 1, 2, 3 }))
      assert_true(libtbl.list_empty({ a = 1 }))
    end)
    it("list index", function()
      assert_eq(libtbl.list_index(-1, 10), 10)
      assert_eq(libtbl.list_index(-2, 10), 9)
      for i = 1, 10 do
        assert_eq(libtbl.list_index(i, 10), i)
        assert_eq(libtbl.list_index(-i, 10), 10 - i + 1)
      end
      for i = 1, 10 do
        assert_eq(libtbl.list_index(i, 10), i)
      end
      for i = -1, -10, -1 do
        assert_eq(libtbl.list_index(i, 10), 10 + i + 1)
      end
      assert_eq(libtbl.list_index(-1, 10), 10)
      assert_eq(libtbl.list_index(-10, 10), 1)
      assert_eq(libtbl.list_index(-3, 10), 8)
      assert_eq(libtbl.list_index(-5, 10), 6)
    end)
  end)
end)
