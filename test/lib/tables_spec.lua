---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.tables", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local tbls = require("fzfx.lib.tables")

  describe("strings", function()
    it("tbl_empty/tbl_not_empty", function()
      assert_true(tbls.tbl_empty(nil))
      assert_true(tbls.tbl_empty({}))
      assert_false(tbls.tbl_not_empty(nil))
      assert_false(tbls.tbl_not_empty({}))
      assert_false(tbls.tbl_empty({ 1, 2, 3 }))
      assert_false(tbls.tbl_empty({ a = 1 }))
      assert_true(tbls.tbl_not_empty({ 1, 2, 3 }))
      assert_true(tbls.tbl_not_empty({ a = 1 }))
    end)
    it("tbl_get", function()
      assert_true(tbls.tbl_get({ a = { b = true } }, "a.b"))
      assert_eq(tbls.tbl_get({ a = { b = true } }, "a.b.c"), nil)
      assert_eq(tbls.tbl_get({ a = { b = true } }, "a.c"), nil)
      assert_eq(tbls.tbl_get({ a = { b = true } }, "c"), nil)
      assert_eq(tbls.tbl_get({ c = { d = 1 } }, "c.d"), 1)
      assert_eq(tbls.tbl_get({ c = { d = 1, e = "e" } }, "c.e"), "e")
    end)
    it("list", function()
      assert_true(tbls.list_empty(nil))
      assert_true(tbls.list_empty({}))
      assert_false(tbls.list_empty({ 1, 2, 3 }))
      assert_true(tbls.list_empty({ a = 1 }))
    end)
    it("list index", function()
      assert_eq(tbls.list_index(-1, 10), 10)
      assert_eq(tbls.list_index(-2, 10), 9)
      for i = 1, 10 do
        assert_eq(tbls.list_index(i, 10), i)
        assert_eq(tbls.list_index(-i, 10), 10 - i + 1)
      end
      for i = 1, 10 do
        assert_eq(tbls.list_index(i, 10), i)
      end
      for i = -1, -10, -1 do
        assert_eq(tbls.list_index(i, 10), 10 + i + 1)
      end
      assert_eq(tbls.list_index(-1, 10), 10)
      assert_eq(tbls.list_index(-10, 10), 1)
      assert_eq(tbls.list_index(-3, 10), 8)
      assert_eq(tbls.list_index(-5, 10), 6)
    end)
  end)
end)
