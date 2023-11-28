local cwd = vim.fn.getcwd()

describe("lib.constants", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local constants = require("fzfx.lib.constants")

  describe("[test]", function()
    it("os", function()
      assert_eq(type(constants.IS_WINDOWS), "boolean")
      assert_false(constants.IS_WINDOWS)
      assert_eq(type(constants.IS_MACOS), "boolean")
      assert_eq(type(constants.IS_LINUX), "boolean")
      assert_eq(type(constants.IS_BSD), "boolean")
    end)
    it("cli", function()
      -- bat/cat
      assert_eq(type(constants.HAS_BAT), "boolean")
      assert_true(constants.BAT == "bat" or constants.BAT == "batcat")
      assert_eq(type(constants.HAS_CAT), "boolean")
      assert_true(constants.CAT == "cat")

      -- rg/grep
      assert_eq(type(constants.HAS_RG), "boolean")
      assert_true(constants.RG == "rg")
      assert_eq(type(constants.HAS_GNU_GREP), "boolean")
      assert_true(constants.GNU_GREP == "grep" or constants.GNU_GREP == "ggrep")
      assert_eq(type(constants.HAS_GREP), "boolean")
      assert_true(constants.GREP == "grep" or constants.GREP == "ggrep")

      -- fd/find
      assert_eq(type(constants.HAS_FD), "boolean")
      assert_true(constants.FD == "fd" or constants.FD == "fdfind")
      assert_eq(type(constants.HAS_GNU_GREP), "boolean")
      assert_true(constants.GNU_GREP == "grep" or constants.GNU_GREP == "ggrep")
      assert_eq(type(constants.HAS_GREP), "boolean")
      assert_true(constants.GREP == "grep" or constants.GREP == "ggrep")

      -- ls/lsd/eza
      assert_eq(type(constants.HAS_LS), "boolean")
      assert_true(constants.LS == "ls")
      assert_eq(type(constants.HAS_LSD), "boolean")
      assert_true(constants.LSD == "lsd")
      assert_eq(type(constants.HAS_EZA), "boolean")
      assert_true(constants.EZA == "eza" or constants.EZA == "exa")

      -- git/delta
      assert_eq(type(constants.HAS_GIT), "boolean")
      assert_true(constants.GIT == "git")
      assert_eq(type(constants.HAS_DELTA), "boolean")
      assert_true(constants.DELTA == "delta")

      -- echo
      assert_eq(type(constants.HAS_ECHO), "boolean")
      assert_true(constants.ECHO == "echo")

      -- curl
      assert_eq(type(constants.HAS_CURL), "boolean")
      assert_true(constants.CURL == "curl")
    end)
  end)
end)
