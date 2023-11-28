---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("lib.nvim", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local libtbl = require("fzfx.lib.tables")
  local libvi = require("fzfx.lib.nvims")

  describe("[get_buf_option/set_buf_option]", function()
    it("get filetype", function()
      local ft = libvi.get_buf_option(0, "filetype")
      print(string.format("filetype get buf option:%s\n", vim.inspect(ft)))
      assert_eq(type(ft), "string")
    end)
    it("set filetype", function()
      libvi.set_buf_option(0, "filetype", "lua")
      local ft = libvi.get_buf_option(0, "filetype")
      print(string.format("filetype set buf option:%s\n", vim.inspect(ft)))
      assert_eq(ft, "lua")
    end)
  end)
  describe("[buf_is_valid]", function()
    it("valid", function()
      assert_false(libvi.buf_is_valid())
      assert_false(libvi.buf_is_valid(nil))
    end)
  end)
  describe("[get_win_option/set_win_option]", function()
    it("get spell", function()
      libvi.set_win_option(0, "spell", true)
      local s = libvi.get_win_option(0, "spell")
      print(string.format("spell get win option:%s\n", vim.inspect(s)))
      assert_eq(type(s), "boolean")
      assert_true(s)
    end)
    it("set spell", function()
      libvi.set_win_option(0, "spell", false)
      local s = libvi.get_win_option(0, "spell")
      print(string.format("spell set win option:%s\n", vim.inspect(s)))
      assert_false(s)
    end)
  end)
  describe("[ShellOptsContext]", function()
    it("save", function()
      local ctx = libvi.ShellOptsContext:save()
      assert_eq(type(ctx), "table")
      assert_false(libtbl.tbl_empty(ctx))
      assert_true(ctx.shell ~= nil)
    end)
    it("restore", function()
      local ctx = libvi.ShellOptsContext:save()
      assert_eq(type(ctx), "table")
      assert_false(libtbl.tbl_empty(ctx))
      assert_true(ctx.shell ~= nil)
      ctx:restore()
    end)
  end)
  describe("[WindowOptsContext]", function()
    it("save", function()
      local ctx = libvi.WindowOptsContext:save()
      assert_eq(type(ctx), "table")
      assert_false(libtbl.tbl_empty(ctx))
      assert_true(ctx.bufnr ~= nil)
    end)
    it("restore", function()
      local ctx = libvi.WindowOptsContext:save()
      assert_eq(type(ctx), "table")
      assert_false(libtbl.tbl_empty(ctx))
      assert_true(ctx.bufnr ~= nil)
      ctx:restore()
    end)
  end)
  describe("[RingBuffer]", function()
    it("creates", function()
      local rb = libvi.RingBuffer:new(10)
      assert_eq(type(rb), "table")
      assert_eq(#rb.queue, 0)
    end)
    it("loop", function()
      local rb = libvi.RingBuffer:new(10)
      assert_eq(type(rb), "table")
      for i = 1, 10 do
        rb:push(i)
      end
      local p = rb:begin()
      while p do
        local actual = rb:get(p)
        assert_eq(actual, p)
        p = rb:next(p)
      end
      rb = libvi.RingBuffer:new(10)
      for i = 1, 15 do
        rb:push(i)
      end
      p = rb:begin()
      while p do
        local actual = rb:get(p)
        if p <= 5 then
          assert_eq(actual, p + 10)
        else
          assert_eq(actual, p)
        end
        p = rb:next(p)
      end
      rb = libvi.RingBuffer:new(10)
      for i = 1, 20 do
        rb:push(i)
      end
      p = rb:begin()
      while p do
        local actual = rb:get(p)
        assert_eq(actual, p + 10)
        p = rb:next(p)
      end
    end)
    it("get latest", function()
      local rb = libvi.RingBuffer:new(10)
      for i = 1, 50 do
        rb:push(i)
        assert_eq(rb:get(), i)
      end
      local p = rb:begin()
      print(string.format("|utils_spec| begin, p:%s\n", vim.inspect(p)))
      while p do
        local actual = rb:get(p)
        print(
          string.format(
            "|utils_spec| get, p:%s, actual:%s\n",
            vim.inspect(p),
            vim.inspect(actual)
          )
        )
        assert_eq(actual, p + 40)
        p = rb:next(p)
        print(string.format("|utils_spec| next, p:%s\n", vim.inspect(p)))
      end
      p = rb:rbegin()
      print(
        string.format(
          "|utils_spec| rbegin, p:%s, rb:%s\n",
          vim.inspect(p),
          vim.inspect(rb)
        )
      )
      while p do
        local actual = rb:get(p)
        print(
          string.format(
            "|utils_spec| rget, p:%s, actual:%s, rb:%s\n",
            vim.inspect(p),
            vim.inspect(actual),
            vim.inspect(rb)
          )
        )
        assert_eq(actual, p + 40)
        p = rb:rnext(p)
        print(
          string.format(
            "|utils_spec| rnext, p:%s, rb:%s\n",
            vim.inspect(p),
            vim.inspect(rb)
          )
        )
      end
    end)
  end)
end)
