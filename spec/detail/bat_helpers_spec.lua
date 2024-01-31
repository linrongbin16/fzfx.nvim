local cwd = vim.fn.getcwd()

describe("detail.bat_helpers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
  end)

  local jsons = require("fzfx.commons.jsons")
  local fileios = require("fzfx.commons.fileios")
  local tables = require("fzfx.commons.tables")
  local strings = require("fzfx.commons.strings")
  local paths = require("fzfx.commons.paths")
  local env = require("fzfx.lib.env")
  local bat_helpers = require("fzfx.detail.bat_helpers")
  local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum
  require("fzfx").setup({
    debug = {
      enable = true,
      file_log = true,
    },
  })

  describe("[color name cache]", function()
    it("get_color_name_cache", function()
      assert_eq(type(bat_helpers.get_color_name_cache()), "string")
    end)
    it("get_color_name", function()
      assert_true(
        type(bat_helpers.get_color_name()) == "string"
          or bat_helpers.get_color_name() == nil
      )
    end)
    it("dump_color_name", function()
      bat_helpers.dump_color_name(vim.g.colors_name)
    end)
  end)
  describe("[bat themes dir]", function()
    it("get_themes_config_dir_cache", function()
      assert_eq(type(bat_helpers.get_themes_config_dir_cache()), "string")
    end)
    it("cached_theme_dir", function()
      assert_true(
        type(bat_helpers.cached_theme_dir()) == "string"
          or bat_helpers.cached_theme_dir() == nil
      )
    end)
    it("dump_theme_dir_cache", function()
      bat_helpers.dump_theme_dir_cache(
        paths.normalize("~/.config/bat/themes", { expand = true })
      )
    end)
  end)
  describe("[get_bat_themes_config_dir]", function()
    it("test", function()
      local actual = bat_helpers.get_bat_themes_config_dir()
      assert_true(type(actual) == "string" or actual == nil)
    end)
  end)
  describe("[_upper_first_chars]", function()
    it("test", function()
      local inputs = {
        "a",
        "b",
        "c",
        "test",
        "rose-pine",
      }
      local actual = bat_helpers._upper_first_chars(inputs)
      assert_eq(type(actual), "table")
      assert_eq(#actual, #inputs)
      for i, a in ipairs(actual) do
        assert_eq(a:lower(), inputs[i]:lower())
        assert_eq(string.sub(a, 1, 1), string.sub(a:upper(), 1, 1))
        assert_eq(string.sub(a, 2), string.sub(a:lower(), 2))
      end
    end)
  end)
  describe("[_normalize_by]", function()
    it("rose-pine", function()
      assert_eq(bat_helpers._normalize_by("rose-pine", "-"), "RosePine")
    end)
    it("ayu", function()
      assert_eq(bat_helpers._normalize_by("ayu", "-"), "Ayu")
    end)
    it("solarized8_high", function()
      assert_eq(
        bat_helpers._normalize_by("solarized8_high", "-"),
        "Solarized8_high"
      )
      assert_eq(
        bat_helpers._normalize_by("solarized8_high", "_"),
        "Solarized8High"
      )
    end)
    it("asdf qwer", function()
      assert_eq(bat_helpers._normalize_by("asdf qwer", " "), "AsdfQwer")
      assert_eq(
        bat_helpers._normalize_by("solarized8_high", "_"),
        "Solarized8High"
      )
    end)
  end)
end)
