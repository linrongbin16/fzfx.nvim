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
  local numbers = require("fzfx.commons.numbers")
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
      local width_floor = math.floor(vim.o.columns * 0.85)
      local width_ceil = math.ceil(vim.o.columns * 0.85)
      local height_floor = math.floor(vim.o.lines * 0.75)
      local height_ceil = math.ceil(vim.o.lines * 0.75)
      assert_true(actual1.width >= width_floor)
      assert_true(actual1.width <= width_ceil)
      assert_true(actual1.height >= height_floor)
      assert_true(actual1.height <= height_ceil)
      local center_row = vim.o.lines / 2
      local center_col = vim.o.columns / 2
      assert_true(2 * (center_row - actual1.start_row) >= height_floor)
      assert_true(2 * (center_row - actual1.start_row) <= height_ceil)
      assert_true(2 * (actual1.end_row - center_row) >= height_floor)
      assert_true(2 * (actual1.end_row - center_row) <= height_ceil)
      assert_true(2 * (center_col - actual1.start_col) >= width_floor)
      assert_true(2 * (center_col - actual1.start_col) <= width_ceil)
      assert_true(2 * (actual1.end_col - center_col) >= width_floor)
      assert_true(2 * (actual1.end_col - center_col) <= width_ceil)
    end)
    it("test with fzf_preview_window_opts", function() end)
  end)
end)
