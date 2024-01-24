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
  describe("[_make_cursor_config]", function()
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
end)
