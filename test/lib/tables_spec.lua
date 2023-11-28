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
  end)
end)
