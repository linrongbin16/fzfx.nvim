---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("cfg.git_commits", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local tbls = require("fzfx.lib.tables")
  local consts = require("fzfx.lib.constants")
  local strs = require("fzfx.lib.strings")
  local paths = require("fzfx.lib.paths")
  local colors = require("fzfx.lib.colors")

  local contexts = require("fzfx.helper.contexts")
  local providers = require("fzfx.helper.providers")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")

  local git_commits_cfg = require("fzfx.cfg.git_commits")

  describe("[_git_commits_previewer]", function()
    it("test", function()
      local lines = {
        "44ee80e 2023-10-11 linrongbin16 (HEAD -> origin/feat_git_status) docs: wording",
        "706e1d6 2023-10-10 linrongbin16 chore",
        "                                | 1:2| fzfx.nvim",
      }
      for _, line in ipairs(lines) do
        local actual = git_commits_cfg._git_commits_previewer(line)
        if actual ~= nil then
          assert_eq(type(actual), "string")
          assert_true(strs.find(actual, "git show") > 0)
          if vim.fn.executable("delta") > 0 then
            assert_true(strs.find(actual, "delta") > 0)
          else
            assert_true(strs.find(actual, "delta") == nil)
          end
        end
      end
    end)
  end)

  describe("[_make_git_commits_provider]", function()
    it("all commits", function()
      local f = git_commits_cfg._make_git_commits_provider()
      local actual = f("", {})
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_eq(actual[1], "git")
        assert_eq(actual[2], "log")
        assert_true(strs.startswith(actual[3], "--pretty="))
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
        assert_true(strs.startswith(actual[3], "--pretty="))
        assert_eq(actual[4], "--date=short")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "--")
        assert_true(strs.endswith(actual[7], "README.md"))
      end
    end)
  end)
end)
