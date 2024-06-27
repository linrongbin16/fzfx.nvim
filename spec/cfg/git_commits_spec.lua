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
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local git_commits_cfg = require("fzfx.cfg.git_commits")
  require("fzfx").setup()

  --- @return fzfx.PipelineContext
  local function make_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  describe("[_make_provider]", function()
    it("workspace", function()
      local f = git_commits_cfg._make_provider()
      local actual = f("", {})
      -- if actual ~= nil then
      assert_eq(type(actual), "table")
      local n = #git_commits_cfg._GIT_LOG_WORKSPACE
      for i = 1, n do
        assert_eq(actual[i], git_commits_cfg._GIT_LOG_WORKSPACE[i])
      end
      -- end
    end)
    it("current buffer", function()
      local f = git_commits_cfg._make_provider({ buffer = true })
      local actual = f("", make_context())
      if actual ~= nil then
        assert_eq(type(actual), "table")
        local n = #git_commits_cfg._GIT_LOG_CURRENT_BUFFER
        for i = 1, n do
          assert_eq(actual[i], git_commits_cfg._GIT_LOG_CURRENT_BUFFER[i])
        end
        assert_true(str.find(actual[#actual], "README.md") > 0)
      end
    end)
  end)
end)
