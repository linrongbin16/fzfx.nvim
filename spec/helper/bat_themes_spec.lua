local cwd = vim.fn.getcwd()

describe("detail.bats_helper", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.cmd("noautocmd colorscheme darkblue")
  end)

  local str = require("fzfx.commons.str")
  local path = require("fzfx.commons.path")
  local consts = require("fzfx.lib.constants")
  local bat_themes_helper = require("fzfx.helper.bat_themes")
  require("fzfx").setup()

  describe("[_create_dir_if_not_exist]", function()
    it("test", function()
      local tmp = vim.fn.tempname()
      assert_false(path.isdir(tmp))
      assert_false(path.isfile(tmp))

      local actual1 = bat_themes_helper._create_dir_if_not_exist(tmp)
      assert_true(actual1)
      local actual2 = bat_themes_helper._create_dir_if_not_exist(tmp)
      assert_false(actual2)
    end)
  end)

  describe("[get_theme_dir]", function()
    it("test", function()
      if consts.HAS_BAT then
        local actual = bat_themes_helper.get_theme_dir()
        assert_true(type(actual) == "string" or actual == nil)
      end
    end)
  end)

  describe("[async_get_theme_dir]", function()
    it("test", function()
      if consts.HAS_BAT then
        bat_themes_helper.async_get_theme_dir(function(theme_dir)
          assert_true(type(theme_dir) == "string")
        end)
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

  describe("[get_theme_config_filename]", function()
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
      if consts.HAS_BAT then
        for i, v in ipairs(inputs) do
          local actual = bat_themes_helper.get_theme_config_filename(v) --[[@as string]]
          local expect = expects[i]
          print(
            string.format(
              "get_theme_config_filename-%d, actual:%s, expect:%s\n",
              i,
              vim.inspect(actual),
              vim.inspect(expect)
            )
          )
          if actual then
            assert_true(str.endswith(actual, expect))
          end
        end
      end
    end)
  end)
end)
