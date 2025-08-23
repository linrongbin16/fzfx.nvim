---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("fzfx.cfg.git_live_grep", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local GITHUB_ACTIONS = os.getenv("GITHUB_ACTIONS") == "true"

  local tbl = require("fzfx.commons.tbl")
  local constants = require("fzfx.lib.constants")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local git_live_grep_cfg = require("fzfx.cfg.git_live_grep")
  require("fzfx").setup()

  describe("_provider", function()
    it("case-1: without extra options", function()
      local actual = git_live_grep_cfg._provider("", git_live_grep_cfg._context_maker())
      print(string.format("_provider-1:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      local n = #git_live_grep_cfg._GIT_GREP
      for i = 1, n do
        assert_eq(actual[i], git_live_grep_cfg._GIT_GREP[i])
      end
    end)
    it("case-2: with 'fzfx -- -v'", function()
      local actual = git_live_grep_cfg._provider("fzfx -- -v", git_live_grep_cfg._context_maker())
      print(string.format("_provider-2:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      local n = #git_live_grep_cfg._GIT_GREP
      for i = 1, n do
        assert_eq(actual[i], git_live_grep_cfg._GIT_GREP[i])
      end
      assert_true(tbl.List:move(actual):some(function(a)
        return a == "fzfx"
      end))
      assert_true(tbl.List:move(actual):some(function(a)
        return a == "-v"
      end))
    end)
    it("case-3: with 'fzfx -- -v -E  ' options", function()
      local actual =
        git_live_grep_cfg._provider("fzfx -- -v  -E  ", git_live_grep_cfg._context_maker())
      print(string.format("_provider-3:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      local n = #git_live_grep_cfg._GIT_GREP
      for i = 1, n do
        assert_eq(actual[i], git_live_grep_cfg._GIT_GREP[i])
      end
      assert_true(tbl.List:move(actual):some(function(a)
        return a == "fzfx"
      end))
      assert_true(tbl.List:move(actual):some(function(a)
        return a == "-v"
      end))
      assert_true(tbl.List:move(actual):some(function(a)
        return a == "-E"
      end))
    end)
  end)
end)
