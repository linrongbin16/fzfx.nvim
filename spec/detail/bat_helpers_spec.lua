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

  describe("[_indent]", function()
    it("_indent", function()
      for i = 1, 10 do
        local actual = bat_helpers._indent(i, "abcd")
        assert_true(str.startswith(actual, string.rep(" ", i)))
        assert_true(str.endswith(actual, "abcd"))
      end
    end)
  end)

  describe("[_BatThemeGlobalRenderer]", function()
    it("render", function()
      local r = bat_helpers._BatThemeGlobalRenderer:new(
        { "Normal", "NormalFloat", "Search", "IncSearch" },
        "foreground",
        "fg"
      )
      local actual = r:render() --[[@as string[] ]]
      assert_eq(type(actual), "table")
      assert_true(tbl.List:copy(actual):every(function(a)
        return type(a) == "string"
      end))
      assert_true(tbl.List:copy(actual):some(function(a)
        local p1 = string.find(a, "<key>")
        local p2 = str.find(a, "</key>")
        return type(p1) == "number" and p1 > 0 and type(p2) == "number" and p2 > p1
      end))
      assert_true(tbl.List:copy(actual):some(function(a)
        local p1 = string.find(a, "<string>")
        local p2 = string.find(a, "</string>")
        return type(p1) == "number" and p1 > 0 and type(p2) == "number" and p2 > p1
      end))
    end)
  end)

  describe("[_BatThemeScopeRenderer]", function()
    local RENDERERS = {
      bat_helpers._BatThemeScopeRenderer:new({ "@comment", "Comment" }, "comment"),
      bat_helpers._BatThemeScopeRenderer:new({ "@number", "Number" }, "constant.numeric"),
      bat_helpers._BatThemeScopeRenderer:new(
        { "@number.float", "Float" },
        "constant.numeric.float"
      ),
      bat_helpers._BatThemeScopeRenderer:new({ "@boolean", "Boolean" }, "constant.language"),
      bat_helpers._BatThemeScopeRenderer:new(
        { "@character", "Character" },
        { "constant.character" }
      ),
      bat_helpers._BatThemeScopeRenderer:new(
        { "@string.escape" },
        { "constant.character.escaped", "constant.character.escape" }
      ),
    }

    it("render", function()
      for _, r in ipairs(RENDERERS) do
        local actual = r:render()
        assert_true(type(actual) == "table" or actual == nil)
        if actual then
          assert_true(tbl.List:copy(actual):every(function(a)
            return type(a) == "string"
          end))
          assert_true(tbl.List:copy(actual):some(function(a)
            local p1 = string.find(a, "</dict>")
            return type(p1) == "number" and p1 > 0
          end))
          assert_true(tbl.List:copy(actual):some(function(a)
            local p1 = string.find(a, "<dict>")
            return type(p1) == "number" and p1 > 0
          end))
          assert_true(tbl.List:copy(actual):some(function(a)
            local p1 = string.find(a, "<key>")
            local p2 = str.find(a, "</key>")
            return type(p1) == "number" and p1 > 0 and type(p2) == "number" and p2 > p1
          end))
          assert_true(tbl.List:copy(actual):some(function(a)
            local p1 = string.find(a, "<string>")
            local p2 = string.find(a, "</string>")
            return type(p1) == "number" and p1 > 0 and type(p2) == "number" and p2 > p1
          end))
          assert_true(tbl.List:copy(actual):some(function(a)
            local p1 = string.find(a, "<key>foreground</key>")
            return type(p1) == "number" and p1 > 0
          end))
        end
      end
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
