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

  local constants = require("fzfx.lib.constants")
  local tables = require("fzfx.commons.tables")
  local strings = require("fzfx.commons.strings")
  local paths = require("fzfx.commons.paths")
  local bat_helpers = require("fzfx.detail.bat_helpers")
  require("fzfx").setup()

  describe("[_BatTmRenderer]", function()
    it("test", function()
      local r = bat_helpers._BatTmRenderer:new()
      local actual = r:render(vim.g.colors_name)
      assert_true(tables.tbl_not_empty(actual))
    end)
  end)
  describe("[_build_theme]", function()
    it("test", function()
      if constants.HAS_BAT then
        bat_helpers._build_theme(vim.g.colors_name)
      end
    end)
  end)
end)
