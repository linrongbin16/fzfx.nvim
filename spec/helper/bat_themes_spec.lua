local cwd = vim.fn.getcwd()

describe("helper.bat_themes", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
  end)

  local str = require("fzfx.commons.str")
  local constants = require("fzfx.lib.constants")
  local bat_themes_helper = require("fzfx.helper.bat_themes")
  require("fzfx").setup()

  describe("[get_theme_dir]", function()
    it("test", function()
      if constants.HAS_BAT then
        local actual = bat_themes_helper.get_theme_dir()
        assert_true(type(actual) == "string" or actual == nil)
      end
    end)
  end)
  describe("[_upper_first]", function()
    it("test", function()
      local inputs = {
        "a",
        "b",
        "c",
        "test",
        "rose-pine",
      }
      local actual = bat_themes_helper._upper_first(inputs)
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
      assert_eq(bat_themes_helper._normalize_by("rose-pine", "-"), "RosePine")
    end)
    it("ayu", function()
      assert_eq(bat_themes_helper._normalize_by("ayu", "-"), "Ayu")
    end)
    it("solarized8_high", function()
      assert_eq(bat_themes_helper._normalize_by("solarized8_high", "-"), "Solarized8_high")
      assert_eq(bat_themes_helper._normalize_by("solarized8_high", "_"), "Solarized8High")
    end)
    it("asdf qwer", function()
      assert_eq(bat_themes_helper._normalize_by("asdf qwer", " "), "AsdfQwer")
      assert_eq(bat_themes_helper._normalize_by("solarized8_high", "_"), "Solarized8High")
    end)
  end)
  describe("[get_theme_name]", function()
    it("test", function()
      local inputs = {
        "material-lighter",
        "rose-pine",
        "slate",
        "solarized8_high",
        "gruvbox-baby",
        "vim-material",
        "PaperColor",
        "OceanicNext",
      }
      local expects = {
        "FzfxNvimMaterialLighter",
        "FzfxNvimRosePine",
        "FzfxNvimSlate",
        "FzfxNvimSolarized8High",
        "FzfxNvimGruvboxBaby",
        "FzfxNvimVimMaterial",
        "FzfxNvimPaperColor",
        "FzfxNvimOceanicNext",
      }

      for i, v in ipairs(inputs) do
        local actual = bat_themes_helper.get_theme_name(v)
        assert_eq(actual, expects[i])
      end
    end)
  end)
  describe("[get_theme_config_file]", function()
    it("test", function()
      local inputs = {
        "material-lighter",
        "rose-pine",
        "slate",
        "solarized8_high",
        "gruvbox-baby",
        "vim-material",
        "PaperColor",
        "OceanicNext",
      }
      local expects = {
        "FzfxNvimMaterialLighter.tmTheme",
        "FzfxNvimRosePine.tmTheme",
        "FzfxNvimSlate.tmTheme",
        "FzfxNvimSolarized8High.tmTheme",
        "FzfxNvimGruvboxBaby.tmTheme",
        "FzfxNvimVimMaterial.tmTheme",
        "FzfxNvimPaperColor.tmTheme",
        "FzfxNvimOceanicNext.tmTheme",
      }

      if constants.HAS_BAT then
        for i, v in ipairs(inputs) do
          local actual = bat_themes_helper.get_theme_config_file(v) --[[@as string]]
          print(
            string.format(
              "get bat theme file, actual:%s, expects[%d]:%s\n",
              vim.inspect(actual),
              vim.inspect(i),
              vim.inspect(expects[i])
            )
          )
          if actual then
            assert_true(str.endswith(actual, expects[i]))
          end
        end
      end
    end)
  end)
end)
