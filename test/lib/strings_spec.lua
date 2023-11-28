---@diagnostic disable: undefined-field
local cwd = vim.fn.getcwd()

describe("lib.strings", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local libstr = require("fzfx.lib.strings")

  describe("strings", function()
    it("uuid", function()
      assert_true(string.len(libstr.uuid()) > 0)
      assert_true(string.len(libstr.uuid(".")) > 0)
    end)
  end)
end)
