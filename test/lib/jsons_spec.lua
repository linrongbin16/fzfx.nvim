---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.jsons", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local jsons = require("fzfx.lib.jsons")
  describe("[encode/decode]", function()
    it("encode1", function()
      local a = jsons.encode({ "a", "b", 1 })
      local b = jsons.decode(a)
      local c = jsons.decode('["a", "b", 1]')
      print(string.format("encode1: %s\n", vim.inspect(a)))
      print(string.format("encode2: %s\n", vim.inspect(b)))
      print(string.format("encode3: %s\n", vim.inspect(c)))
      assert_true(vim.deep_equal(b, c))
    end)
    it("encode2", function()
      local a = jsons.encode({ a = "a", b = { 1, 2, "3" }, c = "c" })
      local b = jsons.decode(a)
      local c = jsons.decode('{"a":"a", "b":[1,2,"3"], "c":"c"}')
      print(string.format("encode1: %s\n", vim.inspect(a)))
      print(string.format("encode2: %s\n", vim.inspect(b)))
      print(string.format("encode3: %s\n", vim.inspect(c)))
      assert_true(vim.deep_equal(b, c))
    end)
    it("decode1", function()
      local a = { "a", "b", { a = "1", b = 2 } }
      local b = jsons.decode('["a", "b", {"a":"1","b":2}]')
      print(string.format("decode1:%s\n", vim.inspect(a)))
      print(string.format("decode2:%s\n", vim.inspect(b)))
      assert_true(vim.deep_equal(a, b))
    end)
    it("decode2", function()
      local a = { a = "a", b = "b", c = { d = 2, e = "5" } }
      local b = jsons.decode('{"a":"a", "b":"b", "c":{"d":2,"e":"5"}}')
      print(string.format("decode1:%s\n", vim.inspect(a)))
      print(string.format("decode2:%s\n", vim.inspect(b)))
      assert_true(vim.deep_equal(a, b))
    end)
  end)
end)
