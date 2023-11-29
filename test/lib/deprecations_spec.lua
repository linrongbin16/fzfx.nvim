---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.deprecations", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local deprecations = require("fzfx.lib.deprecations")
  describe("[notify]", function()
    it("test without parameters", function()
      deprecations.notify(
        "deprecated 'GroupConfig', please use pure lua table!"
      )
      assert_true(true)
    end)
    it("test with parameters", function()
      deprecations.notify("notify with parameters: %s, %d, %f", "asdf", 2, 3.14)
      assert_true(true)
    end)
  end)
end)
