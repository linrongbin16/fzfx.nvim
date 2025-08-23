local cwd = vim.fn.getcwd()

describe("fzfx.cfg.git_status", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local str = require("fzfx.commons.str")
  local consts = require("fzfx.lib.constants")
  local git_status_cfg = require("fzfx.cfg.git_status")
  -- require("fzfx").setup()

  describe("[git_status]", function()
    it("_make_provider", function()
      local actual1 = git_status_cfg._make_provider()("", git_status_cfg._context_maker())
      local n1 = #git_status_cfg._GIT_STATUS_WORKSPACE
      assert_eq(type(actual1), "table")
      for i = 1, n1 do
        assert_eq(actual1[i], git_status_cfg._GIT_STATUS_WORKSPACE[i])
      end

      local actual2 = git_status_cfg._make_provider({ current_folder = true })(
        "",
        git_status_cfg._context_maker()
      )
      local n2 = #git_status_cfg._GIT_STATUS_CURRENT_DIR
      assert_eq(type(actual2), "table")
      for i = 1, n2 do
        assert_eq(actual2[i], git_status_cfg._GIT_STATUS_CURRENT_DIR[i])
      end
    end)
  end)
end)
