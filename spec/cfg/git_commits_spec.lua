---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("fzfx.cfg.git_commits", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local str = require("fzfx.commons.str")
  local consts = require("fzfx.lib.constants")
  local contexts = require("fzfx.helper.contexts")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local git_commits_cfg = require("fzfx.cfg.git_commits")
  require("fzfx").setup()

  describe("[_make_git_commits_provider]", function()
    it("all commits", function()
      local f = git_commits_cfg._make_git_commits_provider()
      local actual = f("", {})
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_eq(actual[1], "git")
        assert_eq(actual[2], "log")
        assert_true(str.startswith(actual[3], "--pretty="))
        assert_eq(actual[4], "--date=short")
        assert_eq(actual[5], "--color=always")
      end
    end)
    it("buffer commits", function()
      local f = git_commits_cfg._make_git_commits_provider({ buffer = true })
      local actual = f("", contexts.make_pipeline_context())
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_eq(actual[1], "git")
        assert_eq(actual[2], "log")
        assert_true(str.startswith(actual[3], "--pretty="))
        assert_eq(actual[4], "--date=short")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "--")
        assert_true(str.endswith(actual[7], "README.md"))
      end
    end)
  end)
end)
