local cwd = vim.fn.getcwd()

describe("fzfx.cfg._grep", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local _grep = require("fzfx.cfg._grep")
  -- require("fzfx").setup()

  describe("[_buf_path]", function()
    it("test", function()
      local bufs = vim.api.nvim_list_bufs()
      for _, bufnr in ipairs(bufs) do
        local actual1 = _grep.buf_path(bufnr)
        assert_eq(type(actual1), "string")
        -- assert_true(type(actual1) == "string" or actual1 == nil)
      end

      local actual2 = _grep.buf_path(nil)
      assert_true(actual2 == nil)
    end)
  end)
  describe("[append_options]", function()
    it("test", function()
      local actual1 = _grep.append_options({}, "-w -g")
      print(string.format("append_options-1:%s\n", vim.inspect(actual1)))
      assert_eq(#actual1, 2)
      assert_eq(actual1[1], "-w")
      assert_eq(actual1[2], "-g")

      local actual2 = _grep.append_options({}, nil)
      print(string.format("append_options-2:%s\n", vim.inspect(actual2)))
      assert_eq(#actual2, 0)

      local actual3 = _grep.append_options({}, "  -w  ")
      print(string.format("append_options-3:%s\n", vim.inspect(actual3)))
      assert_eq(#actual3, 1)
      assert_eq(actual3[1], "-w")

      local actual4 = _grep.append_options({}, "  \n-w -g -I \n")
      print(string.format("append_options-4:%s\n", vim.inspect(actual4)))
      assert_eq(#actual4, 3)
      assert_eq(actual4[1], "-w")
      assert_eq(actual4[2], "-g")
      assert_eq(actual4[3], "-I")
    end)
  end)

  describe("[parse_query]", function()
    it("without flags", function()
      local actual1 = _grep.parse_query("asdf")
      assert_eq(type(actual1), "table")
      assert_eq(actual1.payload, "asdf")
      assert_eq(actual1.option, nil)

      local actual2 = _grep.parse_query("asdf  ")
      assert_eq(type(actual2), "table")
      assert_eq(actual2.payload, "asdf")
      assert_eq(actual2.option, nil)
    end)
    it("with flags", function()
      local actual1 = _grep.parse_query("asdf --")
      assert_eq(type(actual1), "table")
      assert_eq(actual1.payload, "asdf")
      assert_eq(actual1.option, "")

      local actual2 = _grep.parse_query("asdf --  ")
      assert_eq(type(actual2), "table")
      assert_eq(actual2.payload, "asdf")
      assert_eq(actual2.option, "")

      local actual3 = _grep.parse_query("asdf --  -w")
      assert_eq(type(actual3), "table")
      assert_eq(actual3.payload, "asdf")
      assert_eq(actual3.option, "-w")

      local actual4 = _grep.parse_query("asdf --  -w \n")
      assert_eq(type(actual4), "table")
      assert_eq(actual4.payload, "asdf")
      assert_eq(actual4.option, "-w")
    end)
  end)
end)
