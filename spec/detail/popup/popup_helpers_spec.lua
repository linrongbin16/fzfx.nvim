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
    local function isclose(a, b)
      return a >= math.floor(b) and a <= math.ceil(b)
    end

    it("test1 without fzf_preview_window_opts", function()
      local actual = popup_helpers.make_layout({
        relative = "editor",
        height = 0.75,
        width = 0.85,
        row = 0,
        col = 0,
      })
      print(string.format("make_layout-1:%s\n", vim.inspect(actual)))
      local total_width = vim.o.columns
      local total_height = vim.o.lines
      local center_row = vim.o.lines / 2
      local center_col = vim.o.columns / 2
      assert_true(isclose(actual.width, total_width * 0.85))
      assert_true(isclose(actual.height, total_height * 0.75))
      assert_true(isclose(2 * (center_row - actual.start_row), total_height))
      assert_true(isclose(2 * (actual.end_row - center_row), total_height))
      assert_true(isclose(2 * (center_col - actual.start_col), total_width))
      assert_true(isclose(2 * (actual.end_col - center_col), total_width))
    end)
    it("test2 without fzf_preview_window_opts", function()
      local actual = popup_helpers.make_layout({
        relative = "win",
        height = 0.47,
        width = 0.71,
        row = -1,
        col = 2,
      })
      print(string.format("make_layout-2:%s\n", vim.inspect(actual)))
      local total_height = vim.api.nvim_win_get_height(0)
      local total_width = vim.api.nvim_win_get_width(0)
      local center_row = vim.o.lines / 2
      local center_col = vim.o.columns / 2
      assert_true(isclose(actual.width, total_width * 0.85))
      assert_true(isclose(actual.height, total_height * 0.75))
      assert_true(isclose(2 * (center_row - actual.start_row), total_height))
      assert_true(isclose(2 * (actual.end_row - center_row), total_height))
      assert_true(isclose(2 * (center_col - actual.start_col), total_width))
      assert_true(isclose(2 * (actual.end_col - center_col), total_width))
    end)
    it("test with fzf_preview_window_opts", function() end)
  end)
end)
