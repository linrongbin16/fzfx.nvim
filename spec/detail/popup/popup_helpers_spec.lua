local cwd = vim.fn.getcwd()

describe("detail.popup.popup_helpers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.cmd([[edit README.md]])
  end)

  local tables = require("fzfx.commons.tables")
  local strings = require("fzfx.commons.strings")
  local popup_helpers = require("fzfx.detail.popup.popup_helpers")
  require("fzfx").setup({
    debug = {
      enable = true,
      file_log = true,
    },
  })

  describe("[WindowOptsContext]", function()
    it("save", function()
      local ctx = popup_helpers.WindowOptsContext:save()
      assert_eq(type(ctx), "table")
    end)
    it("restore", function()
      local ctx = popup_helpers.WindowOptsContext:save()
      assert_eq(type(ctx), "table")
      ctx:restore()
    end)
  end)
  describe("[ShellOptsContext]", function()
    it("save", function()
      local ctx = popup_helpers.ShellOptsContext:save()
      assert_eq(type(ctx), "table")
    end)
    it("restore", function()
      local ctx = popup_helpers.ShellOptsContext:save()
      assert_eq(type(ctx), "table")
      ctx:restore()
    end)
  end)
  describe("[make_layout]", function()
    it("test without fzf_preview_window_opts", function()
      local actual1 = popup_helpers.make_layout({
        relative = "editor",
        height = 0.75,
        width = 0.85,
        row = 0,
        col = 0,
      })
      print(string.format("make_layout-1:%s\n", vim.inspect(actual1)))
      assert_true(actual1.width >= math.floor(vim.o.columns * 0.85))
      assert_true(actual1.width <= math.ceil(vim.o.columns * 0.85))
      assert_true(actual1.height >= math.floor(vim.o.lines * 0.75))
      assert_true(actual1.height <= math.ceil(vim.o.lines * 0.75))
      local center_row = vim.o.lines / 2
      local center_col = vim.o.columns / 2
      -- assert_eq(center_row - actual1.start_row, )
    end)
    it("test with fzf_preview_window_opts", function() end)
  end)
end)
