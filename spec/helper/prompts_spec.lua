---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("helper.prompts", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local prompts = require("fzfx.helper.prompts")
  describe("[confirm_discard_modified]", function()
    it("confirm", function()
      vim.fn.feedkeys("i", "m")
      vim.fn.feedkeys("i", "m")
      vim.fn.feedkeys("i", "m")
      vim.fn.feedkeys("i", "m")
      prompts.confirm_discard_modified(0, function()
        assert_true(true)
      end)
      vim.fn.feedkeys("y", "m")
    end)
    it("cancelled", function()
      vim.fn.feedkeys("i", "m")
      vim.fn.feedkeys("i", "m")
      vim.fn.feedkeys("i", "m")
      vim.fn.feedkeys("i", "m")
      prompts.confirm_discard_modified(0, function()
        assert_true(true)
      end)
      vim.fn.feedkeys("n", "m")
    end)
  end)
end)
