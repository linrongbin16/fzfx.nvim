local cwd = vim.fn.getcwd()

describe("lib.switches", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local switches = require("fzfx.lib.switches")
  describe("[_convert_boolean]", function()
    it("test", function()
      assert_true(switches._convert_boolean(1))
      assert_true(switches._convert_boolean(true))
      assert_false(switches._convert_boolean("true"))
      assert_false(switches._convert_boolean(nil))
      assert_false(switches._convert_boolean())
      assert_false(switches._convert_boolean(false))
      assert_false(switches._convert_boolean("false"))
      assert_false(switches._convert_boolean(0))
    end)
  end)
  describe("[fzfx_disable_buffer_previewer]", function()
    it("test", function()
      vim.g.fzfx_disable_buffer_previewer = 1
      assert_true(switches.buffer_previewer_disabled())
      vim.g.fzfx_disable_buffer_previewer = true
      assert_true(switches.buffer_previewer_disabled())
    end)
  end)
  describe("[fzfx_enable_bat_theme_autogen]", function()
    it("test", function()
      vim.g.fzfx_enable_bat_theme_autogen = 1
      assert_true(switches.bat_theme_autogen_enabled())
      vim.g.fzfx_enable_bat_theme_autogen = true
      assert_true(switches.bat_theme_autogen_enabled())
    end)
  end)
end)
