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

  local tables = require("fzfx.commons.tables")
  local strings = require("fzfx.commons.strings")
  local paths = require("fzfx.commons.paths")
  local bat_themes_helper = require("fzfx.helper.bat_themes")
  require("fzfx").setup()

  describe("[bat themes dir]", function()
    it("cached_theme_dir", function()
      assert_true(
        type(bat_themes_helper.cached_theme_dir()) == "string"
          or bat_themes_helper.cached_theme_dir() == nil
      )
    end)
    it("_dump_theme_dir", function()
      bat_themes_helper._dump_theme_dir(
        paths.normalize("~/.config/bat/themes", { expand = true })
      )
    end)
  end)
  describe("[get_bat_themes_config_dir]", function()
    it("test", function()
      local actual = bat_themes_helper.get_bat_themes_config_dir()
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
      local actual = bat_themes_helper._upper_first_chars(inputs)
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
      assert_eq(
        bat_themes_helper._normalize_by("solarized8_high", "-"),
        "Solarized8_high"
      )
      assert_eq(
        bat_themes_helper._normalize_by("solarized8_high", "_"),
        "Solarized8High"
      )
    end)
    it("asdf qwer", function()
      assert_eq(bat_themes_helper._normalize_by("asdf qwer", " "), "AsdfQwer")
      assert_eq(
        bat_themes_helper._normalize_by("solarized8_high", "_"),
        "Solarized8High"
      )
    end)
  end)
  describe("[get_custom_theme_name]", function()
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
        local actual = bat_themes_helper.get_custom_theme_name(v)
        assert_eq(actual, expects[i])
      end
    end)
  end)
  describe("[get_custom_theme_template_file]", function()
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

      for i, v in ipairs(inputs) do
        local actual = bat_themes_helper.get_custom_theme_template_file(v) --[[@as string]]
        print(
          string.format(
            "get bat theme file, actual:%s, expects[%d]:%s\n",
            vim.inspect(actual),
            vim.inspect(i),
            vim.inspect(expects[i])
          )
        )
        assert_true(strings.endswith(actual, expects[i]))
      end
    end)
  end)
  describe("[calculate_custom_theme]", function()
    it("test", function()
      local actual = bat_themes_helper.calculate_custom_theme(vim.g.colors_name)
      assert_true(tables.tbl_not_empty(actual))
    end)
  end)
end)
