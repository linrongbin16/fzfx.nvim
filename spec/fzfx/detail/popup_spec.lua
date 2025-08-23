local cwd = vim.fn.getcwd()

describe("detail.popup", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.fn["fzf#exec"] = function()
      return "fzf"
    end
  end)

  local tbl = require("fzfx.commons.tbl")
  local str = require("fzfx.commons.str")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local popup = require("fzfx.detail.popup")
  require("fzfx").setup()

  describe("[_make_expect_keys]", function()
    it("make --expect options", function()
      local input = {
        ["ctrl-d"] = function(lines) end,
        ["ctrl-r"] = function(lines) end,
      }
      local actual = popup._make_expect_keys(input)
      assert_eq(type(actual), "table")
      assert_eq(#actual, 2)
      for _, a in ipairs(actual) do
        assert_eq(a[1], "--expect")
        assert_true(a[2] == "ctrl-d" or a[2] == "ctrl-r")
      end
    end)
  end)
  describe("[_merge_fzf_actions]", function()
    it("merge fzf actions", function()
      local input = {
        ["ctrl-d"] = function(lines) end,
        ["ctrl-r"] = function(lines) end,
      }
      local actual = popup._merge_fzf_actions({}, input)
      assert_eq(type(actual), "table")
      assert_eq(#actual, 2)
      for _, a in ipairs(actual) do
        assert_eq(a[1], "--expect")
        assert_true(a[2] == "ctrl-d" or a[2] == "ctrl-r")
      end
      local actual2 = popup._make_expect_keys(input)
      assert_true(vim.deep_equal(actual, actual2))
    end)
  end)
  describe("[_make_fzf_command]", function()
    it("merge fzf command", function()
      local input = {
        ["ctrl-d"] = function(lines) end,
        ["ctrl-r"] = function(lines) end,
      }
      local tmpname = vim.fn.tempname()
      local fzfopts = fzf_helpers.make_fzf_default_opts()
      local actual = popup._make_fzf_command({ fzfopts }, input, tmpname)
      print(string.format("make fzf command:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(string.len(actual) > 0)
      assert_true(str.startswith(actual, "fzf "))
      assert_eq(str.find(actual, fzfopts), 5)
      assert_true(str.find(actual, "--expect") > string.len(fzfopts))
    end)
  end)
end)
