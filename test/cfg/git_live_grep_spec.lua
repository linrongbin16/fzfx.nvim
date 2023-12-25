---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("cfg.git_live_grep", function()
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
  local git_live_grep_cfg = require("fzfx.cfg.git_live_grep")
  require("fzfx").setup()

  describe("git_live_grep", function()
    it("_git_live_grep_provider", function()
      local actual = git_live_grep_cfg._git_live_grep_provider("", {})
      print(string.format("git live grep:%s\n", vim.inspect(actual)))
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_eq(actual[1], "git")
        assert_eq(actual[2], "grep")
      end
    end)
    it("_git_live_grep_provider with -- flag", function()
      local actual = git_live_grep_cfg._git_live_grep_provider("fzfx -- -v", {})
      print(string.format("git live grep:%s\n", vim.inspect(actual)))
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_eq(actual[1], "git")
        assert_eq(actual[2], "grep")
      end
    end)
  end)
end)
