local cwd = vim.fn.getcwd()

describe("fzfx.cfg.buf_live_grep", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local consts = require("fzfx.lib.constants")
  local contexts_help = require("fzfx.helper.contexts")
  local buf_live_grep_cfg = require("fzfx.cfg.buf_live_grep")
  require("fzfx").setup()

  describe("[_buf_path]", function()
    it("test", function()
      local bufs = vim.api.nvim_list_bufs()
      for _, bufnr in ipairs(bufs) do
        local actual1 = buf_live_grep_cfg._buf_path(bufnr)
        assert_eq(type(actual1), "string")
        -- assert_true(type(actual1) == "string" or actual1 == nil)
      end

      local actual2 = buf_live_grep_cfg._buf_path(nil)
      assert_true(actual2 == nil)
    end)
  end)
  describe("[_append_options]", function()
    it("test", function()
      local actual1 = buf_live_grep_cfg._append_options({}, "-w -g")
      assert_eq(actual1[1], "-w")
      assert_eq(actual1[2], "-g")

      local actual2 = buf_live_grep_cfg._append_options({}, nil)
      assert_eq(#actual2, 0)
    end)
  end)
  describe("[_make_provider]", function()
    it("test without context", function()
      local f = buf_live_grep_cfg._make_provider()
      local actual = f("hello", {})
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(actual, nil)
    end)
    it("test with context", function()
      local f = buf_live_grep_cfg._make_provider()
      local ctx = contexts_help.make_pipeline_context()
      local actual = f("hello", ctx)
      print(string.format("buf_live_grep make_provider-1, actual:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if actual[1] == "rg" then
        assert_eq(actual[1], "rg")
        assert_eq(actual[2], "--column")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "--no-heading")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "-H")
        assert_eq(actual[7], "-S")
        assert_eq(actual[8], "-uu")
        assert_eq(actual[9], "-I")
        assert_eq(actual[10], "hello")
      else
        assert_eq(actual[1], consts.GREP)
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "-H")
        assert_eq(actual[5], "-r")
        assert_eq(actual[6], "-h")
        assert_eq(actual[7], "hello")
      end
    end)
  end)
end)
