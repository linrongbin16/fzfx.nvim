local cwd = vim.fn.getcwd()

describe("lib.constants", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local consts = require("fzfx.lib.constants")

  describe("[test]", function()
    it("os", function()
      assert_eq(type(consts.IS_WINDOWS), "boolean")
      assert_false(consts.IS_WINDOWS)
      assert_eq(type(consts.IS_MACOS), "boolean")
      assert_eq(type(consts.IS_LINUX), "boolean")
      assert_eq(type(consts.IS_BSD), "boolean")
    end)
    it("cli", function()
      -- bat/cat
      assert_eq(type(consts.HAS_BAT), "boolean")
      assert_true(consts.BAT == "bat" or consts.BAT == "batcat")
      assert_eq(type(consts.HAS_CAT), "boolean")
      assert_true(consts.CAT == "cat")

      -- rg/grep
      assert_eq(type(consts.HAS_RG), "boolean")
      assert_true(consts.RG == "rg")
      assert_eq(type(consts.HAS_GNU_GREP), "boolean")
      assert_true(consts.GNU_GREP == "grep" or consts.GNU_GREP == "ggrep")
      assert_eq(type(consts.HAS_GREP), "boolean")
      assert_true(consts.GREP == "grep" or consts.GREP == "ggrep")

      -- fd/find
      assert_eq(type(consts.HAS_FD), "boolean")
      assert_true(consts.FD == "fd" or consts.FD == "fdfind")
      assert_eq(type(consts.HAS_GNU_GREP), "boolean")
      assert_true(consts.GNU_GREP == "grep" or consts.GNU_GREP == "ggrep")
      assert_eq(type(consts.HAS_GREP), "boolean")
      assert_true(consts.GREP == "grep" or consts.GREP == "ggrep")

      -- ls/lsd/eza
      assert_eq(type(consts.HAS_LS), "boolean")
      assert_true(consts.LS == "ls")
      assert_eq(type(consts.HAS_LSD), "boolean")
      assert_true(consts.LSD == "lsd")
      assert_eq(type(consts.HAS_EZA), "boolean")
      assert_true(consts.EZA == "eza" or consts.EZA == "exa")

      -- git/delta
      assert_eq(type(consts.HAS_GIT), "boolean")
      assert_true(consts.GIT == "git")
      assert_eq(type(consts.HAS_DELTA), "boolean")
      assert_true(consts.DELTA == "delta")

      -- echo
      assert_eq(type(consts.HAS_ECHO), "boolean")
      assert_true(consts.ECHO == "echo")

      -- curl
      assert_eq(type(consts.HAS_CURL), "boolean")
      assert_true(consts.CURL == "curl")
    end)
  end)
end)
