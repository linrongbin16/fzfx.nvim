---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("fzfx.cfg.git_blame", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local GITHUB_ACTIONS = os.getenv("GITHUB_ACTIONS") == "true"

  local str = require("fzfx.commons.str")
  local consts = require("fzfx.lib.constants")
  local contexts = require("fzfx.helper.contexts")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local git_blame_cfg = require("fzfx.cfg.git_blame")

  require("fzfx").setup()

  describe("git_blame", function()
    it("_provider", function()
      local actual = git_blame_cfg._provider("", contexts.make_pipeline_context())
      -- if actual ~= nil then
      assert_eq(type(actual), "string")
      assert_true(str.find(actual, "git blame") > 0)
      if consts.HAS_DELTA then
        assert_true(str.find(actual, "delta") > 0)
      else
        assert_true(str.find(actual, "delta") == nil)
      end
      -- end
    end)
  end)
end)
