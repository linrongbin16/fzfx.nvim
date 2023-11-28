---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.strings", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local libstr = require("fzfx.lib.strings")

  describe("uuid", function()
    it("test", function()
      assert_true(string.len(libstr.uuid()) > 0)
      assert_true(string.len(libstr.uuid(".")) > 0)
    end)
  end)
  describe("[empty/not_empty/blank/not_blank]", function()
    it("empty", function()
      assert_true(libstr.empty())
      assert_true(libstr.empty(nil))
      assert_true(libstr.empty(""))
      assert_false(libstr.not_empty())
      assert_false(libstr.not_empty(nil))
      assert_false(libstr.not_empty(""))
    end)
    it("not empty", function()
      assert_true(libstr.not_empty(" "))
      assert_true(libstr.not_empty(" asdf "))
      assert_false(libstr.empty(" "))
      assert_false(libstr.empty(" asdf "))
    end)
    it("blank", function()
      assert_true(libstr.blank())
      assert_true(libstr.blank(nil))
      assert_true(libstr.blank(" "))
      assert_true(libstr.blank("\n"))
      assert_false(libstr.not_blank())
      assert_false(libstr.not_blank(nil))
      assert_false(libstr.not_blank(""))
    end)
    it("not blank", function()
      assert_true(libstr.not_blank(" x"))
      assert_true(libstr.not_blank(" asdf "))
      assert_false(libstr.blank("y "))
      assert_false(libstr.blank(" asdf "))
    end)
  end)
  describe("[find]", function()
    it("found", function()
      assert_eq(libstr.find("abcdefg", "a"), 1)
      assert_eq(libstr.find("abcdefg", "a", 1), 1)
      assert_eq(libstr.find("abcdefg", "g"), 7)
      assert_eq(libstr.find("abcdefg", "g", 1), 7)
      assert_eq(libstr.find("abcdefg", "g", 7), 7)
      assert_eq(libstr.find("fzfx -- -w -g *.lua", "--"), 6)
      assert_eq(libstr.find("fzfx -- -w -g *.lua", "--", 1), 6)
      assert_eq(libstr.find("fzfx -- -w -g *.lua", "--", 2), 6)
      assert_eq(libstr.find("fzfx -- -w -g *.lua", "--", 3), 6)
      assert_eq(libstr.find("fzfx -- -w -g *.lua", "--", 6), 6)
      assert_eq(libstr.find("fzfx -w -- -g *.lua", "--"), 9)
      assert_eq(libstr.find("fzfx -w -- -g *.lua", "--", 1), 9)
      assert_eq(libstr.find("fzfx -w -- -g *.lua", "--", 2), 9)
      assert_eq(libstr.find("fzfx -w ---g *.lua", "--", 8), 9)
      assert_eq(libstr.find("fzfx -w ---g *.lua", "--", 9), 9)
    end)
    it("not found", function()
      assert_eq(libstr.find("abcdefg", "a", 2), nil)
      assert_eq(libstr.find("abcdefg", "a", 7), nil)
      assert_eq(libstr.find("abcdefg", "g", 8), nil)
      assert_eq(libstr.find("abcdefg", "g", 9), nil)
      assert_eq(libstr.find("fzfx -- -w -g *.lua", "--", 7), nil)
      assert_eq(libstr.find("fzfx -- -w -g *.lua", "--", 8), nil)
      assert_eq(libstr.find("fzfx -w -- -g *.lua", "--", 10), nil)
      assert_eq(libstr.find("fzfx -w -- -g *.lua", "--", 11), nil)
      assert_eq(libstr.find("fzfx -w ---g *.lua", "--", 11), nil)
      assert_eq(libstr.find("fzfx -w ---g *.lua", "--", 12), nil)
      assert_eq(libstr.find("", "--"), nil)
      assert_eq(libstr.find("", "--", 1), nil)
      assert_eq(libstr.find("-", "--"), nil)
      assert_eq(libstr.find("--", "---", 1), nil)
    end)
  end)
  describe("[rfind]", function()
    it("found", function()
      assert_eq(libstr.rfind("abcdefg", "a"), 1)
      assert_eq(libstr.rfind("abcdefg", "a", 1), 1)
      assert_eq(libstr.rfind("abcdefg", "a", 7), 1)
      assert_eq(libstr.rfind("abcdefg", "a", 2), 1)
      assert_eq(libstr.rfind("abcdefg", "g"), 7)
      assert_eq(libstr.rfind("abcdefg", "g", 7), 7)
      assert_eq(libstr.rfind("fzfx -- -w -g *.lua", "--"), 6)
      assert_eq(libstr.rfind("fzfx -- -w -g *.lua", "--", 6), 6)
      assert_eq(libstr.rfind("fzfx -- -w -g *.lua", "--", 7), 6)
      assert_eq(libstr.rfind("fzfx -- -w -g *.lua", "--", 8), 6)
      assert_eq(libstr.rfind("fzfx -w -- -g *.lua", "--"), 9)
      assert_eq(libstr.rfind("fzfx -w -- -g *.lua", "--", 10), 9)
      assert_eq(libstr.rfind("fzfx -w -- -g *.lua", "--", 9), 9)
      assert_eq(libstr.rfind("fzfx -w -- -g *.lua", "--", 10), 9)
      assert_eq(libstr.rfind("fzfx -w -- -g *.lua", "--", 11), 9)
      assert_eq(libstr.rfind("fzfx -w ---g *.lua", "--", 9), 9)
      assert_eq(libstr.rfind("fzfx -w ---g *.lua", "--", 10), 10)
      assert_eq(libstr.rfind("fzfx -w ---g *.lua", "--", 11), 10)
    end)
    it("not found", function()
      assert_eq(libstr.rfind("abcdefg", "a", 0), nil)
      assert_eq(libstr.rfind("abcdefg", "a", -1), nil)
      assert_eq(libstr.rfind("abcdefg", "g", 6), nil)
      assert_eq(libstr.rfind("abcdefg", "g", 5), nil)
      assert_eq(libstr.rfind("fzfx -- -w -g *.lua", "--", 5), nil)
      assert_eq(libstr.rfind("fzfx -- -w -g *.lua", "--", 4), nil)
      assert_eq(libstr.rfind("fzfx -- -w -g *.lua", "--", 1), nil)
      assert_eq(libstr.rfind("fzfx -w -- -g *.lua", "--", 8), nil)
      assert_eq(libstr.rfind("fzfx -w -- -g *.lua", "--", 7), nil)
      assert_eq(libstr.rfind("fzfx -w ---g *.lua", "--", 8), nil)
      assert_eq(libstr.rfind("fzfx -w ---g *.lua", "--", 7), nil)
      assert_eq(libstr.rfind("", "--"), nil)
      assert_eq(libstr.rfind("", "--", 1), nil)
      assert_eq(libstr.rfind("-", "--"), nil)
      assert_eq(libstr.rfind("--", "---", 1), nil)
    end)
  end)
  describe("[ltrim/rtrim]", function()
    it("trim left", function()
      assert_eq(libstr.ltrim("asdf"), "asdf")
      assert_eq(libstr.ltrim(" asdf"), "asdf")
      assert_eq(libstr.ltrim(" \nasdf"), "asdf")
      assert_eq(libstr.ltrim("\tasdf"), "asdf")
      assert_eq(libstr.ltrim(" asdf  "), "asdf  ")
      assert_eq(libstr.ltrim(" \nasdf\n"), "asdf\n")
      assert_eq(libstr.ltrim("\tasdf\t"), "asdf\t")
    end)
    it("trim right", function()
      assert_eq(libstr.rtrim("asdf"), "asdf")
      assert_eq(libstr.rtrim(" asdf "), " asdf")
      assert_eq(libstr.rtrim(" \nasdf"), " \nasdf")
      assert_eq(libstr.rtrim(" \nasdf\n"), " \nasdf")
      assert_eq(libstr.rtrim("\tasdf\t"), "\tasdf")
    end)
  end)
  describe("[split]", function()
    it("splits rg options-1", function()
      local actual = libstr.split("-w -g *.md", " ")
      local expect = { "-w", "-g", "*.md" }
      assert_eq(#actual, #expect)
      for i, v in ipairs(actual) do
        assert_eq(v, expect[i])
      end
    end)
    it("splits rg options-2", function()
      local actual = libstr.split("  -w -g *.md  ", " ")
      local expect = { "-w", "-g", "*.md" }
      assert_eq(#actual, #expect)
      for i, v in ipairs(actual) do
        assert_eq(v, expect[i])
      end
    end)
    it("splits rg options-3", function()
      local actual = libstr.split("  -w -g *.md  ", " ", { trimempty = false })
      local expect = { "", "", "-w", "-g", "*.md", "", "" }
      -- print(string.format("splits rg3, actual:%s", vim.inspect(actual)))
      -- print(string.format("splits rg3, expect:%s", vim.inspect(expect)))
      assert_eq(#actual, #expect)
      for i, v in ipairs(actual) do
        assert_eq(v, expect[i])
      end
    end)
  end)
  describe("[startswith]", function()
    it("start", function()
      assert_true(libstr.startswith("hello world", "hello"))
      assert_false(libstr.startswith("hello world", "ello"))
    end)
  end)
  describe("[endswith]", function()
    it("end", function()
      assert_true(libstr.endswith("hello world", "world"))
      assert_false(libstr.endswith("hello world", "hello"))
    end)
  end)
  describe("[isxxx]", function()
    local function _contains_char(s, c)
      assert(string.len(s) > 0)
      assert(string.len(c) == 1)
      for i = 1, #s do
        if string.byte(s, i) == string.byte(c, 1) then
          return true
        end
      end
      return false
    end

    local function _contains_code(s, c)
      for _, i in ipairs(s) do
        if i == c then
          return true
        end
      end
      return false
    end

    it("isspace", function()
      local whitespaces = "\r\n \t"
      local char_codes = { 11, 12 }
      for i = 1, 255 do
        if
          _contains_char(whitespaces, string.char(i))
          or _contains_code(char_codes, i)
        then
          assert_true(libstr.isspace(string.char(i)))
        else
          print(
            string.format(
              "isspace: %d: %s\n",
              i,
              vim.inspect(libstr.isspace(string.char(i)))
            )
          )
          assert_false(libstr.isspace(string.char(i)))
        end
      end
    end)
    it("isalpha", function()
      local a = "a"
      local z = "z"
      local A = "A"
      local Z = "Z"
      for i = 1, 255 do
        if
          (i >= string.byte(a) and i <= string.byte(z))
          or (i >= string.byte(A) and i <= string.byte(Z))
        then
          assert_true(libstr.isalpha(string.char(i)))
        else
          assert_false(libstr.isalpha(string.char(i)))
        end
      end
    end)
    it("isdigit", function()
      local _0 = "0"
      local _9 = "9"
      for i = 1, 255 do
        if i >= string.byte(_0) and i <= string.byte(_9) then
          assert_true(libstr.isdigit(string.char(i)))
        else
          assert_false(libstr.isdigit(string.char(i)))
        end
      end
    end)
    it("isalnum", function()
      local a = "a"
      local z = "z"
      local A = "A"
      local Z = "Z"
      local _0 = "0"
      local _9 = "9"
      for i = 1, 255 do
        if
          (i >= string.byte(a) and i <= string.byte(z))
          or (i >= string.byte(A) and i <= string.byte(Z))
          or (i >= string.byte(_0) and i <= string.byte(_9))
        then
          assert_true(libstr.isalnum(string.char(i)))
        else
          assert_false(libstr.isalnum(string.char(i)))
        end
      end
    end)
    it("ishex", function()
      local a = "a"
      local f = "f"
      local A = "A"
      local F = "F"
      local _0 = "0"
      local _9 = "9"
      for i = 1, 255 do
        if
          (i >= string.byte(a) and i <= string.byte(f))
          or (i >= string.byte(A) and i <= string.byte(F))
          or (i >= string.byte(_0) and i <= string.byte(_9))
        then
          assert_true(libstr.ishex(string.char(i)))
        else
          print(
            string.format(
              "ishex, %d:%s\n",
              i,
              vim.inspect(libstr.ishex(string.char(i)))
            )
          )
          assert_false(libstr.ishex(string.char(i)))
        end
      end
    end)
    it("islower", function()
      local a = "a"
      local z = "z"
      for i = 1, 255 do
        if i >= string.byte(a) and i <= string.byte(z) then
          assert_true(libstr.islower(string.char(i)))
        else
          assert_false(libstr.islower(string.char(i)))
        end
      end
    end)
    it("isupper", function()
      local A = "A"
      local Z = "Z"
      for i = 1, 255 do
        if i >= string.byte(A) and i <= string.byte(Z) then
          assert_true(libstr.isupper(string.char(i)))
        else
          assert_false(libstr.isupper(string.char(i)))
        end
      end
    end)
  end)
end)
