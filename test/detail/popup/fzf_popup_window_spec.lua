local cwd = vim.fn.getcwd()

describe("detail.popup.fzf_popup_window", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
  end)

  local tables = require("fzfx.commons.tables")
  local strings = require("fzfx.commons.strings")
  local fzf_popup_window = require("fzfx.detail.popup.fzf_popup_window")
  local popup_helpers = require("fzfx.detail.popup.popup_helpers")

  local WIN_OPTS = {
    height = 0.85,
    width = 0.85,
    row = 0,
    col = 0,
    border = "none",
    zindex = 51,
  }
  describe("[_make_cursor_opts]", function()
    it("test", function()
      local actual = fzf_popup_window._make_cursor_opts(WIN_OPTS)
      print(
        string.format(
          "fzf_popup_window._make_cursor_opts:%s\n",
          vim.inspect(actual)
        )
      )
      local win_width = vim.api.nvim_win_get_width(0)
      local win_height = vim.api.nvim_win_get_height(0)
      local expect_width =
        popup_helpers.get_window_size(WIN_OPTS.width, win_width)
      local expect_height =
        popup_helpers.get_window_size(WIN_OPTS.height, win_height)
      assert_eq(actual.anchor, "NW")
      assert_eq(actual.border, WIN_OPTS.border)
      assert_eq(actual.zindex, WIN_OPTS.zindex)
      assert_eq(type(actual.height), "number")
      assert_eq(actual.height, expect_height)
      assert_eq(type(actual.width), "number")
      assert_eq(actual.width, expect_width)
      assert_eq(type(actual.row), "number")
      assert_eq(actual.row, 0)
      assert_eq(type(actual.col), "number")
      assert_eq(actual.col, 0)
    end)
  end)
  describe("[_make_center_opts]", function()
    it("test", function()
      local actual = fzf_popup_window._make_center_opts(WIN_OPTS)
      print(
        string.format(
          "fzf_popup_window._make_center_opts:%s\n",
          vim.inspect(actual)
        )
      )
      local total_width = vim.o.columns
      local total_height = vim.o.lines
      local expect_width =
        popup_helpers.get_window_size(WIN_OPTS.width, total_width)
      local expect_height =
        popup_helpers.get_window_size(WIN_OPTS.height, total_height)
      local expect_row = popup_helpers.shift_window_pos(
        total_height,
        expect_height,
        WIN_OPTS.row
      )
      local expect_col =
        popup_helpers.shift_window_pos(total_width, expect_width, WIN_OPTS.col)
      assert_eq(actual.anchor, "NW")
      assert_eq(actual.border, WIN_OPTS.border)
      assert_eq(actual.zindex, WIN_OPTS.zindex)
      assert_eq(type(actual.height), "number")
      assert_eq(actual.height, expect_height)
      assert_eq(type(actual.width), "number")
      assert_eq(actual.width, expect_width)
      assert_eq(type(actual.row), "number")
      assert_eq(actual.row, expect_row)
      assert_eq(type(actual.col), "number")
      assert_eq(actual.col, expect_col)
    end)
  end)
  describe("[make_opts]", function()
    it("test", function()
      local actual1 = fzf_popup_window.make_opts(WIN_OPTS)
      local actual2 = fzf_popup_window._make_center_opts(WIN_OPTS)
      print(
        string.format("fzf_popup_window.make_opts:%s\n", vim.inspect(actual1))
      )
      assert_eq(actual1.anchor, "NW")
      assert_eq(actual1.border, WIN_OPTS.border)
      assert_eq(actual1.zindex, WIN_OPTS.zindex)
      assert_eq(type(actual1.height), "number")
      assert_eq(type(actual2.height), "number")
      assert_eq(actual1.height, actual2.height)
      assert_eq(type(actual1.width), "number")
      assert_eq(type(actual2.width), "number")
      assert_eq(actual1.width, actual2.width)
      assert_eq(type(actual1.row), "number")
      assert_eq(type(actual2.row), "number")
      assert_eq(actual1.row, actual2.row)
      assert_eq(type(actual1.col), "number")
      assert_eq(type(actual2.col), "number")
      assert_eq(actual1.col, actual2.col)
    end)
  end)
end)
