---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("fzfx.cfg.git_files", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.env._FZFX_NVIM_DEVICONS_PATH = nil
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local GITHUB_ACTIONS = os.getenv("GITHUB_ACTIONS") == "true"

  require("fzfx").setup()
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local git_files_cfg = require("fzfx.cfg.git_files")

  describe("_make_provider", function()
    it("workspace", function()
      local f = git_files_cfg._make_provider()
      local actual = f()
      assert_eq(type(actual), "table")
      local n = #git_files_cfg._GIT_LS_WORKSPACE
      for i = 1, n do
        assert_eq(actual[i], git_files_cfg._GIT_LS_WORKSPACE[i])
      end
    end)
    it("current_folder", function()
      local f = git_files_cfg._make_provider({ current_folder = true })
      local actual = f()
      assert_eq(type(actual), "table")
      local n = #git_files_cfg._GIT_LS_CWD
      for i = 1, n do
        assert_eq(actual[i], git_files_cfg._GIT_LS_CWD[i])
      end
    end)
  end)
end)
