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
      return math.abs(a - b) <= 1.5
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
      local width = total_width * 0.85
      local height = total_height * 0.75
      local center_row = total_height / 2
      local center_col = total_width / 2
      assert_true(isclose(actual.width, width))
      assert_true(isclose(actual.height, height))
      assert_true(isclose(2 * (center_row - actual.start_row), height))
      assert_true(isclose(2 * (actual.end_row - center_row), height))
      assert_true(isclose(2 * (center_col - actual.start_col), width))
      assert_true(isclose(2 * (actual.end_col - center_col), width))
    end)
    it("test2 without fzf_preview_window_opts", function()
      local actual = popup_helpers.make_layout({
        relative = "win",
        height = 0.47,
        width = 0.71,
        row = 0,
        col = 0,
      })
      local total_height = vim.api.nvim_win_get_height(0)
      local total_width = vim.api.nvim_win_get_width(0)
      local width = total_width * 0.71
      local height = total_height * 0.47
      local center_row = total_height / 2
      local center_col = total_width / 2
      print(
        string.format(
          "make_layout-2:%s, total(height/width):%s/%s,center(row/col):%s/%s\n",
          vim.inspect(actual),
          vim.inspect(total_height),
          vim.inspect(total_width),
          vim.inspect(center_row),
          vim.inspect(center_col)
        )
      )
      assert_true(isclose(actual.width, width))
      assert_true(isclose(actual.height, height))
      assert_true(isclose(2 * (center_row - actual.start_row), height))
      assert_true(isclose(2 * (actual.end_row - center_row), height))
      assert_true(isclose(2 * (center_col - actual.start_col), width))
      assert_true(isclose(2 * (actual.end_col - center_col), width))
    end)
    it("test3 without fzf_preview_window_opts", function()
      local actual = popup_helpers.make_layout({
        relative = "editor",
        height = 0.77,
        width = 0.81,
        row = -1,
        col = 2,
      })
      local total_width = vim.o.columns
      local total_height = vim.o.lines
      local width = total_width * 0.81
      local height = total_height * 0.77
      local center_row = total_height / 2 - 1
      local center_col = total_width / 2 + 2
      print(
        string.format(
          "make_layout-3:%s, total(height/width):%s/%s,center(row/col):%s/%s\n",
          vim.inspect(actual),
          vim.inspect(total_height),
          vim.inspect(total_width),
          vim.inspect(center_row),
          vim.inspect(center_col)
        )
      )
      assert_true(isclose(actual.width, width))
      assert_true(isclose(actual.height, height))
      assert_true(isclose(2 * (center_row - actual.start_row), height))
      assert_true(isclose(2 * (actual.end_row - center_row), height))
      assert_true(isclose(2 * (center_col - actual.start_col), width))
      assert_true(isclose(2 * (actual.end_col - center_col), width))
    end)
    it("test4 with fzf_preview_window_opts", function()
      local actual = popup_helpers.make_layout({
        relative = "editor",
        height = 0.75,
        width = 0.85,
        row = 0,
        col = 0,
      }, { position = "left", size = 35, size_is_percent = true })
      print(string.format("make_layout-4:%s\n", vim.inspect(actual)))
      local total_width = vim.o.columns
      local total_height = vim.o.lines
      local width = total_width * 0.85
      local height = total_height * 0.75
      local center_row = total_height / 2
      local center_col = total_width / 2
      assert_true(isclose(actual.width, width))
      assert_true(isclose(actual.height, height))
      assert_true(isclose(2 * (center_row - actual.start_row), height))
      assert_true(isclose(2 * (actual.end_row - center_row), height))
      assert_true(isclose(2 * (center_col - actual.start_col), width))
      assert_true(isclose(2 * (actual.end_col - center_col), width))

      assert_true(isclose(actual.provider.width, width * 0.65 - 1))
      assert_eq(actual.provider.height, height)
      assert_eq(actual.provider.start_row, actual.start_row)
      assert_eq(actual.provider.end_row, actual.end_row)
      assert_eq(actual.provider.start_col, actual.start_col + actual.previewer.width + 2)
      assert_eq(actual.provider.end_col, actual.end_col)

      assert_true(isclose(actual.previewer.width, width * 0.35 - 1))
      assert_eq(actual.previewer.height, height)
      assert_eq(actual.previewer.start_row, actual.start_row)
      assert_eq(actual.previewer.end_row, actual.end_row)
      assert_eq(actual.previewer.start_col, actual.start_col)
      assert_eq(actual.previewer.end_col, actual.start_col + actual.previewer.width)
    end)
    it("test5 with fzf_preview_window_opts", function()
      local actual = popup_helpers.make_layout({
        relative = "win",
        height = 1,
        width = 1,
        row = 1,
        col = -2,
      }, { position = "up", size = 15 })
      local total_height = vim.api.nvim_win_get_height(0)
      local total_width = vim.api.nvim_win_get_width(0)
      local width = total_width
      local height = total_height
      local center_row = total_height / 2
      local center_col = total_width / 2
      print(string.format("make_layout-5:%s\n", vim.inspect(actual)))

      assert_true(isclose(actual.width, width))
      assert_true(isclose(actual.height, height))
      assert_true(isclose(2 * (center_row - actual.start_row), height))
      assert_true(isclose(2 * (actual.end_row - center_row), height))
      assert_true(isclose(2 * (center_col - actual.start_col), width))
      assert_true(isclose(2 * (actual.end_col - center_col), width))

      assert_true(isclose(actual.provider.width, width * 0.65 - 1))
      assert_eq(actual.provider.height, height)
      assert_eq(actual.provider.start_row, actual.start_row)
      assert_eq(actual.provider.end_row, actual.end_row)
      assert_eq(actual.provider.start_col, actual.start_col + actual.previewer.width + 2)
      assert_eq(actual.provider.end_col, actual.end_col)

      assert_true(isclose(actual.previewer.width, width * 0.35 - 1))
      assert_eq(actual.previewer.height, height)
      assert_eq(actual.previewer.start_row, actual.start_row)
      assert_eq(actual.previewer.end_row, actual.end_row)
      assert_eq(actual.previewer.start_col, actual.start_col)
      assert_eq(actual.previewer.end_col, actual.start_col + actual.previewer.width)
    end)
  end)
end)
