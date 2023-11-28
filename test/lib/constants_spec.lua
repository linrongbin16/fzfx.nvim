---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.constants", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local libconst = require("fzfx.lib.constants")

  describe("[test]", function()
    it("os", function()
      assert_eq(type(libconst.IS_WINDOWS), "boolean")
      assert_false(libconst.IS_WINDOWS)
      assert_eq(type(libconst.IS_MACOS), "boolean")
      assert_eq(type(libconst.IS_LINUX), "boolean")
      assert_eq(type(libconst.IS_BSD), "boolean")
    end)
    it("cli", function()
      -- bat/cat
      assert_eq(type(libconst.HAS_BAT), "boolean")
      assert_true(libconst.BAT == "bat" or libconst.BAT == "batcat")
      assert_eq(type(libconst.HAS_CAT), "boolean")
      assert_true(libconst.CAT == "cat")

      -- rg/grep
      assert_eq(type(libconst.HAS_RG), "boolean")
      assert_true(libconst.RG == "rg")
      assert_eq(type(libconst.HAS_GNU_GREP), "boolean")
      assert_true(libconst.GNU_GREP == "grep" or libconst.GNU_GREP == "ggrep")
      assert_eq(type(libconst.HAS_GREP), "boolean")
      assert_true(libconst.GREP == "grep" or libconst.GREP == "ggrep")

      -- fd/find
      assert_eq(type(libconst.HAS_FD), "boolean")
      assert_true(libconst.FD == "fd" or libconst.FD == "fdfind")
      assert_eq(type(libconst.HAS_GNU_GREP), "boolean")
      assert_true(libconst.GNU_GREP == "grep" or libconst.GNU_GREP == "ggrep")
      assert_eq(type(libconst.HAS_GREP), "boolean")
      assert_true(libconst.GREP == "grep" or libconst.GREP == "ggrep")

      -- ls/lsd/eza
      assert_eq(type(libconst.HAS_LS), "boolean")
      assert_true(libconst.LS == "ls")
      assert_eq(type(libconst.HAS_LSD), "boolean")
      assert_true(libconst.LSD == "lsd")
      assert_eq(type(libconst.HAS_EZA), "boolean")
      assert_true(libconst.EZA == "eza" or libconst.EZA == "exa")

      -- git/delta
      assert_eq(type(libconst.HAS_GIT), "boolean")
      assert_true(libconst.GIT == "git")
      assert_eq(type(libconst.HAS_DELTA), "boolean")
      assert_true(libconst.DELTA == "delta")

      -- echo
      assert_eq(type(libconst.HAS_ECHO), "boolean")
      assert_true(libconst.ECHO == "echo")

      -- curl
      assert_eq(type(libconst.HAS_CURL), "boolean")
      assert_true(libconst.CURL == "curl")
    end)
  end)
end)
