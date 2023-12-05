---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("helper.providers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local tbls = require("fzfx.lib.tables")
  local consts = require("fzfx.lib.constants")
  local strs = require("fzfx.lib.strings")
  local paths = require("fzfx.lib.paths")
  local colors = require("fzfx.lib.colors")

  local contexts = require("fzfx.helper.contexts")
  local providers = require("fzfx.helper.providers")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")

  describe("[files]", function()
    it("test", function()
      assert_true(tbls.tbl_not_empty(providers.RESTRICTED_FD))
      assert_true(tbls.tbl_not_empty(providers.RESTRICTED_FIND))
      assert_true(tbls.tbl_not_empty(providers.UNRESTRICTED_FD))
      assert_true(tbls.tbl_not_empty(providers.UNRESTRICTED_FIND))
    end)
  end)

  describe("[live_grep]", function()
    it("_make_provide_live_grep restricted", function()
      local f = providers._make_provide_live_grep()
      local actual = f("hello", {})
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if actual[1] == "rg" then
        assert_eq(actual[1], "rg")
        assert_eq(actual[2], "--column")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "--no-heading")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "-H")
        assert_eq(actual[7], "-S")
        assert_eq(actual[8], "hello")
      else
        assert_eq(actual[1], consts.GREP)
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "-H")
        assert_eq(actual[5], "-r")
        assert_eq(
          actual[6],
          "--exclude-dir=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]])
        )
        assert_eq(
          actual[7],
          "--exclude=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]])
        )
        assert_eq(actual[8], "hello")
      end
    end)
    it("_make_live_grep_provider unrestricted", function()
      local f = providers._make_provide_live_grep({ unrestricted = true })
      local actual = f("hello", {})
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if actual[1] == "rg" then
        assert_eq(actual[1], "rg")
        assert_eq(actual[2], "--column")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "--no-heading")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "-H")
        assert_eq(actual[7], "-S")
        assert_eq(actual[8], "-uu")
        assert_eq(actual[9], "hello")
      else
        assert_eq(actual[1], consts.GREP)
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "-H")
        assert_eq(actual[5], "-r")
        assert_eq(actual[6], "hello")
      end
    end)
    it("_make_live_grep_provider buffer", function()
      local f = providers._make_provide_live_grep({ buffer = true })
      local actual = f("hello", contexts.make_pipeline_context())
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if actual[1] == "rg" then
        assert_eq(actual[1], "rg")
        assert_eq(actual[2], "--column")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "--no-heading")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "-H")
        assert_eq(actual[7], "-S")
        assert_eq(actual[8], "-uu")
        assert_eq(actual[9], "hello")
        assert_eq(actual[10], "README.md")
      else
        assert_eq(actual[1], consts.GREP)
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "-H")
        assert_eq(actual[5], "-r")
        assert_eq(actual[6], "hello")
        assert_eq(actual[7], "README.md")
      end
    end)
  end)
end)