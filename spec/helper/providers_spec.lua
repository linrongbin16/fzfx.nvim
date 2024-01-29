---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("helper.providers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local tables = require("fzfx.commons.tables")
  local consts = require("fzfx.lib.constants")
  local contexts = require("fzfx.helper.contexts")
  local providers = require("fzfx.helper.providers")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")

  describe("[files]", function()
    it("test", function()
      assert_true(tables.tbl_not_empty(providers.RESTRICTED_FD))
      assert_true(tables.tbl_not_empty(providers.RESTRICTED_FIND))
      assert_true(tables.tbl_not_empty(providers.UNRESTRICTED_FD))
      assert_true(tables.tbl_not_empty(providers.UNRESTRICTED_FIND))
    end)
  end)

  describe("[live_grep]", function()
    it("test", function()
      assert_true(tables.tbl_not_empty(providers.RESTRICTED_RG))
      assert_true(tables.tbl_not_empty(providers.RESTRICTED_GREP))
      assert_true(tables.tbl_not_empty(providers.UNRESTRICTED_RG))
      assert_true(tables.tbl_not_empty(providers.UNRESTRICTED_GREP))
    end)
  end)
end)
