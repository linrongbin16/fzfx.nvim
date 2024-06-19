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

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local str = require("fzfx.commons.str")
  local consts = require("fzfx.lib.constants")
  local contexts = require("fzfx.helper.contexts")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local git_status_cfg = require("fzfx.cfg.git_status")
  require("fzfx").setup()

  describe("[git_status]", function()
    it("_previewer", function()
      local lines = {
        " M fzfx/config.lua",
        " D fzfx/constants.lua",
        " M fzfx/line_helpers.lua",
        " M ../test/line_helpers_spec.lua",
        "?? ../hello",
      }
      for _, line in ipairs(lines) do
        local actual = git_status_cfg._previewer(line)
        assert_eq(type(actual), "string")
        assert_true(str.find(actual, "git diff") > 0)
        if vim.fn.executable("delta") > 0 then
          assert_true(str.find(actual, "delta") > 0)
        else
          assert_true(str.find(actual, "delta") == nil)
        end
      end
    end)
    it("_make_provider", function()
      local actual1 = git_status_cfg._make_provider()()
      local n1 = #git_status_cfg._GIT_STATUS_WORKSPACE
      assert_eq(type(actual1), "table")
      for i = 1, n1 do
        assert_eq(actual1[i], git_status_cfg._GIT_STATUS_WORKSPACE[i])
      end

      local actual2 = git_status_cfg._make_provider({ current_folder = true })()
      local n2 = #git_status_cfg._GIT_STATUS_CURRENT_DIR
      assert_eq(type(actual2), "table")
      for i = 1, n2 do
        assert_eq(actual2[i], git_status_cfg._GIT_STATUS_CURRENT_DIR[i])
      end
    end)
  end)
end)
