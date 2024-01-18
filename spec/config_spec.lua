---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("config", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.env._FZFX_NVIM_DEVICONS_PATH = nil
    vim.cmd([[edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local function make_default_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  local tables = require("fzfx.commons.tables")
  local consts = require("fzfx.lib.constants")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local config = require("fzfx.config")

  describe("[get]", function()
    it("test", function()
      config.setup()
      assert_eq(type(config.get()), "table")
      assert_false(tables.tbl_empty(config.get()))
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
  end)
  describe("[get_defaults]", function()
    it("get defaults", function()
      config.setup()
      assert_eq(type(config.get_defaults()), "table")
      assert_false(tables.tbl_empty(config.get_defaults()))
      assert_eq(type(config.get_defaults().live_grep), "table")
      assert_eq(type(config.get_defaults().debug), "table")
      assert_eq(type(config.get_defaults().debug.enable), "boolean")
      assert_false(config.get_defaults().debug.enable)
      assert_eq(type(config.get_defaults().popup), "table")
      assert_eq(type(config.get_defaults().icons), "table")
      assert_eq(type(config.get_defaults().fzf_opts), "table")
      local actual = fzf_helpers.make_fzf_opts(config.get_defaults().fzf_opts)
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
