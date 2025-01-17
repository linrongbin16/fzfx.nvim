---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch, duplicate-set-field
local cwd = vim.fn.getcwd()

describe("detail.child_process_helpers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  vim.env._FZFX_NVIM_DEVICONS_PATH = nil
  local child_process_helpers = require("fzfx.detail.child_process_helpers")
  child_process_helpers.setup("test")

  describe("[log]", function()
    it("debug", function()
      assert_true(child_process_helpers.log_debug("logs without params") == nil)
      assert_true(child_process_helpers.log_debug("logs with params 1, %d") == nil)
      assert_true(child_process_helpers.log_debug("logs with params 2, %d, %s") == nil)
    end)
    it("err", function()
      assert_true(child_process_helpers.log_err("logs without params") == nil)
      assert_true(child_process_helpers.log_err("logs with params 1, %d") == nil)
      assert_true(child_process_helpers.log_err("logs with params 2, %d, %s") == nil)
    end)
    it("ensure", function()
      assert_true(child_process_helpers.log_ensure(true, "logs without params") == nil)
      local ok, err = pcall(child_process_helpers.log_ensure, false, "logs with params 1, %d")
      assert_false(ok)
      assert_eq(type(err), "string")
      assert_true(string.len(err --[[@as string]]) > 0)
    end)
    it("throw", function()
      local ok, err = pcall(child_process_helpers.log_throw, "logs with params 1, %d")
      assert_false(ok)
      assert_eq(type(err), "string")
      assert_true(string.len(err --[[@as string]]) > 0)
    end)
  end)
end)
