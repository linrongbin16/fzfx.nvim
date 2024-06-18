---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
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
    it("_git_status_previewer", function()
      local lines = {
        " M fzfx/config.lua",
        " D fzfx/constants.lua",
        " M fzfx/line_helpers.lua",
        " M ../test/line_helpers_spec.lua",
        "?? ../hello",
      }
      for _, line in ipairs(lines) do
        local actual = git_status_cfg._git_status_previewer(line)
        assert_eq(type(actual), "string")
        assert_true(str.find(actual, "git diff") > 0)
        if vim.fn.executable("delta") > 0 then
          assert_true(str.find(actual, "delta") > 0)
        else
          assert_true(str.find(actual, "delta") == nil)
        end
      end
    end)
    it("_make_git_status_provider", function()
      local actual1 = git_status_cfg._make_git_status_provider({})()
      local actual2 = git_status_cfg._make_git_status_provider({ current_folder = true })()
      -- print(
      --     string.format("git status provider1:%s\n", vim.inspect(actual1))
      -- )
      -- print(
      --     string.format("git status provider2:%s\n", vim.inspect(actual2))
      -- )
      assert_true(actual1 == nil or vim.deep_equal(actual1, {
        "git",
        "-c",
        "color.status=always",
        "status",
        "--short",
      }))
      assert_true(actual2 == nil or vim.deep_equal(actual2, {
        "git",
        "-c",
        "color.status=always",
        "status",
        "--short",
        ".",
      }))
    end)
  end)
end)
