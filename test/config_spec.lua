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

  local tbls = require("fzfx.lib.tables")
  local consts = require("fzfx.lib.constants")
  local strs = require("fzfx.lib.strings")
  local paths = require("fzfx.lib.paths")
  local colors = require("fzfx.lib.colors")

  local fzf_helpers = require("fzfx.detail.fzf_helpers")

  local conf = require("fzfx.config")

  describe("[get_config]", function()
    it("test", function()
      conf.setup()
      assert_eq(type(conf.get_config()), "table")
      assert_false(tbls.tbl_empty(conf.get_config()))
      assert_eq(type(conf.get_config().live_grep), "table")
      assert_eq(type(conf.get_config().debug), "table")
      assert_eq(type(conf.get_config().debug.enable), "boolean")
      assert_false(conf.get_config().debug.enable)
      assert_eq(type(conf.get_config().popup), "table")
      assert_eq(type(conf.get_config().icons), "table")
      assert_eq(type(conf.get_config().fzf_opts), "table")
      local actual = fzf_helpers.make_fzf_opts(conf.get_config().fzf_opts)
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
      conf.setup()
      assert_eq(type(conf.get_defaults()), "table")
      assert_false(tbls.tbl_empty(conf.get_defaults()))
      assert_eq(type(conf.get_defaults().live_grep), "table")
      assert_eq(type(conf.get_defaults().debug), "table")
      assert_eq(type(conf.get_defaults().debug.enable), "boolean")
      assert_false(conf.get_defaults().debug.enable)
      assert_eq(type(conf.get_defaults().popup), "table")
      assert_eq(type(conf.get_defaults().icons), "table")
      assert_eq(type(conf.get_defaults().fzf_opts), "table")
      local actual = fzf_helpers.make_fzf_opts(conf.get_defaults().fzf_opts)
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
