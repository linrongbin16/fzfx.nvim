local cwd = vim.fn.getcwd()

describe("fzfx.cfg.buf_live_grep", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local tbl = require("fzfx.commons.tbl")
  local consts = require("fzfx.lib.constants")
  local buf_live_grep_cfg = require("fzfx.cfg.buf_live_grep")
  local _grep = require("fzfx.cfg._grep")
  require("fzfx").setup()

  --- @return fzfx.PipelineContext
  local function make_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  describe("[_provider_rg]", function()
    it("test", function()
      local ctx = make_context()
      local n = #_grep.UNRESTRICTED_RG

      local actual1 = buf_live_grep_cfg._provider_rg("", ctx)
      print(string.format("_provider_rg-1:%s, ctx:%s\n", vim.inspect(actual1), vim.inspect(ctx)))
      assert_eq(type(actual1), "table")
      for i = 1, n do
        assert_eq(actual1[i], _grep.UNRESTRICTED_RG[i])
      end

      local actual2 = buf_live_grep_cfg._provider_rg("fzfx", ctx)
      print(string.format("_provider_rg-2:%s, ctx:%s\n", vim.inspect(actual2), vim.inspect(ctx)))
      for i = 1, n do
        assert_eq(actual2[i], _grep.UNRESTRICTED_RG[i])
      end
      assert_true(tbl.List:move(actual2):some(function(a)
        return a == "fzfx"
      end))
    end)
  end)
  describe("[_provider_grep]", function()
    it("test", function()
      local ctx = make_context()
      local n = #_grep.UNRESTRICTED_GREP

      local actual1 = buf_live_grep_cfg._provider_grep("", ctx)
      print(string.format("_provider_grep-1:%s, ctx:%s\n", vim.inspect(actual1), vim.inspect(ctx)))
      assert_eq(type(actual1), "table")
      for i = 1, n do
        assert_eq(actual1[i], _grep.UNRESTRICTED_GREP[i])
      end

      local actual2 = buf_live_grep_cfg._provider_grep("fzfx", ctx)
      print(string.format("_provider_grep-2:%s, ctx:%s\n", vim.inspect(actual2), vim.inspect(ctx)))
      for i = 1, n do
        assert_eq(actual2[i], _grep.UNRESTRICTED_GREP[i])
      end
      assert_true(tbl.List:move(actual2):some(function(a)
        return a == "fzfx"
      end))
    end)
  end)
  describe("[_make_provider]", function()
    it("without context", function()
      local f = buf_live_grep_cfg._make_provider()
      local actual = f("hello", {})
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(actual, nil)
    end)
    it("with context", function()
      local ctx = make_context()
      local f = buf_live_grep_cfg._make_provider()
      local actual = f("hello", ctx)
      print(string.format("_make_provider-1:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if consts.HAS_RG then
        local n = #_grep.UNRESTRICTED_RG
        for i = 1, n do
          assert_eq(actual[i], _grep.UNRESTRICTED_RG[i])
        end
        assert_true(tbl.List:move(actual):some(function(a)
          return a == "-I"
        end))
        assert_true(tbl.List:move(actual):some(function(a)
          return a == "hello"
        end))
      else
        local n = #_grep.UNRESTRICTED_GREP
        for i = 1, n do
          assert_eq(actual[i], _grep.UNRESTRICTED_GREP[i])
        end
        assert_true(tbl.List:move(actual):some(function(a)
          return a == "-h"
        end))
        assert_true(tbl.List:move(actual):some(function(a)
          return a == "hello"
        end))
      end
    end)
  end)
end)
