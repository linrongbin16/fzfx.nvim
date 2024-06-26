local cwd = vim.fn.getcwd()

describe("detail.bat_helpers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.cmd("noautocmd colorscheme darkblue")
  end)

  local tbl = require("fzfx.commons.tbl")
  local str = require("fzfx.commons.str")
  local consts = require("fzfx.lib.constants")
  local bat_helpers = require("fzfx.detail.bat_helpers")
  require("fzfx").setup()

  describe("[_BatThemeGlobalRenderer]", function()
    it("render", function()
      local r = bat_helpers._BatThemeGlobalRenderer:new(
        { "Normal", "NormalFloat", "Search", "IncSearch" },
        "foreground",
        "fg"
      )
      local actual = r:render()
      assert_eq(type(actual), "string")
      assert_true(str.find(actual, "<key>") > 0)
      assert_true(str.find(actual, "<string>") > 0)
    end)
  end)

  describe("[_BatThemeRenderer]", function()
    it("test", function()
      local r = bat_helpers._BatThemeRenderer:new()
      local actual = r:render(vim.g.colors_name)
      assert_true(tbl.tbl_not_empty(actual))
    end)
  end)

  describe("[_build_theme]", function()
    it("test", function()
      if consts.HAS_BAT then
        bat_helpers._build_theme(vim.g.colors_name)
      end
    end)
  end)
end)
