local cwd = vim.fn.getcwd()

describe("fzfx.cfg.live_grep", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  require("fzfx").setup()
  local tbl = require("fzfx.commons.tbl")
  local consts = require("fzfx.lib.constants")
  local live_grep_cfg = require("fzfx.cfg.live_grep")
  local _grep = require("fzfx.cfg._grep")

  --- @return fzfx.PipelineContext
  local function make_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  describe("[_make_provider]", function()
    it("restricted", function()
      local f = live_grep_cfg._make_provider()
      local actual = f("hello", {})
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if consts.HAS_RG then
        local n = #_grep.RESTRICTED_RG
        for i = 1, n do
          assert_eq(actual[i], _grep.RESTRICTED_RG[i])
        end
        assert_eq(actual[#actual], "hello")
      else
        local n = #_grep.RESTRICTED_GREP
        for i = 1, n do
          assert_eq(actual[i], _grep.RESTRICTED_GREP[i])
        end
        assert_eq(actual[#actual], "hello")
      end
    end)
    it("unrestricted", function()
      local f = live_grep_cfg._make_provider({ unrestricted = true })
      local actual = f("hello", {})
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if consts.HAS_RG then
        local n = #_grep.UNRESTRICTED_RG
        for i = 1, n do
          assert_eq(actual[i], _grep.UNRESTRICTED_RG[i])
        end
        assert_eq(actual[#actual], "hello")
      else
        local n = #_grep.UNRESTRICTED_GREP
        for i = 1, n do
          assert_eq(actual[i], _grep.UNRESTRICTED_GREP[i])
        end
        assert_eq(actual[#actual], "hello")
      end
    end)
    it("buffer", function()
      local f = live_grep_cfg._make_provider({ buffer = true })
      local actual = f("hello", make_context())
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if consts.HAS_RG then
        local n = #_grep.UNRESTRICTED_RG
        for i = 1, n do
          assert_eq(actual[i], _grep.UNRESTRICTED_RG[i])
        end
        assert_true(tbl.List:move(actual):some(function(a)
          return a == "hello"
        end))
      else
        local n = #_grep.UNRESTRICTED_GREP
        for i = 1, n do
          assert_eq(actual[i], _grep.UNRESTRICTED_GREP[i])
        end
        assert_true(tbl.List:move(actual):some(function(a)
          return a == "hello"
        end))
      end
    end)
  end)
end)
