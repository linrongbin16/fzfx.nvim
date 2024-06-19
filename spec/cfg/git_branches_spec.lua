---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("fzfx.cfg.git_branches", function()
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
  local git_branches_cfg = require("fzfx.cfg.git_branches")
  require("fzfx").setup()

  describe("git_branches", function()
    it("_make_provider local", function()
      local f = git_branches_cfg._make_provider()
      local actual = f("", nil)
      assert_true(actual == nil or type(actual) == "table")
    end)
    it("_make_provider remotes", function()
      local f = git_branches_cfg._make_provider({ remote_branch = true })
      local actual = f()
      assert_true(actual == nil or type(actual) == "table")
    end)
    it("_previewer", function()
      local lines = {
        "main",
        "my-plugin-dev",
        "remotes/origin/HEAD -> origin/main",
        "remotes/origin/main",
        "remotes/origin/my-plugin-dev",
        "remotes/origin/ci-fix-create-tags",
        "remotes/origin/ci-verbose",
      }
      for i, line in ipairs(lines) do
        local actual = git_branches_cfg._previewer(line, nil)
        assert_true(str.find(actual, "git log --pretty") == 1)
      end
    end)
  end)
end)
