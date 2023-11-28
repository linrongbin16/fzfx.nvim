local cwd = vim.fn.getcwd()

describe("lib.filesystem", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local strings = require("fzfx.lib.strings")
  local fs = require("fzfx.lib.filesystem")

  describe("[readfile/readlines]", function()
    it("readfile and FileLineReader", function()
      local content = fs.readfile("README.md")
      local reader = fs.FileLineReader:open("README.md") --[[@as FileLineReader]]
      local buffer = nil
      assert_eq(type(reader), "table")
      while reader:has_next() do
        local line = reader:next() --[[@as string]]
        assert_eq(type(line), "string")
        assert_true(string.len(line) >= 0)
        buffer = buffer and (buffer .. line .. "\n") or (line .. "\n")
      end
      reader:close()
      assert_eq(strings.rtrim(buffer --[[@as string]]), content)
    end)
    it("readfile and readlines", function()
      local content = fs.readfile("README.md")
      local lines = fs.readlines("README.md")
      local buffer = nil
      for _, line in
        ipairs(lines --[[@as table]])
      do
        assert_eq(type(line), "string")
        assert_true(string.len(line) >= 0)
        buffer = buffer and (buffer .. line .. "\n") or (line .. "\n")
      end
      assert_eq(strings.rtrim(buffer --[[@as string]]), content)
    end)
  end)
end)
