---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("config", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.env._FZFX_NVIM_DEVICONS_PATH = nil
    vim.cmd([[noautocmd edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local tbl = require("fzfx.commons.tbl")
  local consts = require("fzfx.lib.constants")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local config = require("fzfx.config")

  describe("[get/set]", function()
    it("get", function()
      config.setup()
      assert_eq(type(config.get()), "table")
      assert_false(tbl.tbl_empty(config.get()))
      assert_eq(type(config.get().live_grep), "table")
      assert_eq(type(config.get().debug), "table")
      assert_eq(type(config.get().debug.enable), "boolean")
      assert_false(config.get().debug.enable)
      assert_eq(type(config.get().popup), "table")
      assert_eq(type(config.get().icons), "table")
      assert_eq(type(config.get().fzf_opts), "table")
      local actual = fzf_helpers.make_fzf_opts(config.get().fzf_opts)
      -- print(
      --     string.format(
      --         "make fzf opts with default configs:%s\n",
      --         vim.inspect(actual)
      --     )
      -- )
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
    end)
    it("set", function()
      config.setup()
      local actual1 = config.get()
      actual1.files = "files"
      config.set(actual1)
      local actual2 = config.get()
      assert_eq(actual1.files, actual2.files)
    end)
  end)
  describe("[get_defaults]", function()
    it("test", function()
      config.setup()
      assert_eq(type(config.defaults()), "table")
      assert_false(tbl.tbl_empty(config.defaults()))
      assert_eq(type(config.defaults().live_grep), "table")
      assert_eq(type(config.defaults().debug), "table")
      assert_eq(type(config.defaults().debug.enable), "boolean")
      assert_false(config.defaults().debug.enable)
      assert_eq(type(config.defaults().popup), "table")
      assert_eq(type(config.defaults().icons), "table")
      assert_eq(type(config.defaults().fzf_opts), "table")
      local actual = fzf_helpers.make_fzf_opts(config.defaults().fzf_opts)
      -- print(
      --     string.format(
      --         "make fzf opts with default configs:%s\n",
      --         vim.inspect(actual)
      --     )
      -- )
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
    end)
  end)
end)
