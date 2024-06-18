---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("fzfx.cfg.git_files", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  require("fzfx").setup()
  local contexts = require("fzfx.helper.contexts")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")

  local git_files_cfg = require("fzfx.cfg.git_files")

  describe("git_files", function()
    it("_make_git_files_provider repo", function()
      local f = git_files_cfg._make_git_files_provider()
      local actual = f()
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(vim.deep_equal(actual, { "git", "ls-files", ":/" }))
      end
    end)
    it("_make_git_files_provider current folder", function()
      local f = git_files_cfg._make_git_files_provider({ current_folder = true })
      local actual = f()
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(vim.deep_equal(actual, { "git", "ls-files" }))
      end
    end)
  end)
end)
