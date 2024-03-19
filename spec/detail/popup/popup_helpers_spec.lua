local cwd = vim.fn.getcwd()

describe("detail.popup.popup_helpers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local min_test_height = 30
  local max_test_height = 40
  local min_test_width = 130
  local max_test_width = 140
  local test_height = min_test_height
  local test_width = min_test_width

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.cmd([[edit README.md]])
    if github_actions then
      vim.cmd(string.format("set lines=%d", test_height))
      vim.cmd(string.format("set columns=%d", test_width))
      vim.api.nvim_win_set_height(0, test_height)
      vim.api.nvim_win_set_width(0, test_width)
    end
  end)

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
  describe("[make_center_layout]", function()
    for i = min_test_height, max_test_height, 2 do
      for j = min_test_width, max_test_width, 3 do
        test_height = i
        test_width = j
        local function isclose(a, b)
          if github_actions then
            return math.abs(math.abs(a) - math.abs(b)) <= 3.5
          else
            return math.abs(a - b) <= 2.5
          end
        end

        it("test1 without fzf_preview_window_opts", function()
          local actual = popup_helpers.make_center_layout({
            relative = "editor",
            height = 0.75,
            width = 0.85,
            row = 0,
            col = 0,
          })
          print(string.format("make_center_layout-1:%s\n", vim.inspect(actual)))
          local total_width = vim.o.columns
          local total_height = vim.o.lines
          local width = total_width * 0.85
          local height = total_height * 0.75
          local center_row = total_height * 0.5 - 1
          local center_col = total_width * 0.5 - 1
          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))
          assert_true(isclose((actual.end_row + actual.start_row) / 2, center_row))
          assert_true(isclose((actual.end_col + actual.start_col) / 2, center_col))
        end)
        it("test2 without fzf_preview_window_opts", function()
          local actual = popup_helpers.make_center_layout({
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
          local center_row = total_height * 0.5 - 1
          local center_col = total_width * 0.5 - 1
          print(
            string.format(
              "make_center_layout-2:%s, total(height/width):%s/%s, center row/col:%s/%s\n",
              vim.inspect(actual),
              vim.inspect(total_height),
              vim.inspect(total_width),
              vim.inspect(center_row),
              vim.inspect(center_col)
            )
          )
          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))
          assert_true(isclose((actual.end_row + actual.start_row) / 2, center_row))
          assert_true(isclose((actual.end_col + actual.start_col) / 2, center_col))
        end)
        it("test3 without fzf_preview_window_opts", function()
          local actual = popup_helpers.make_center_layout({
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
          local center_row = total_height * 0.5 - 1
          local center_col = total_width * 0.5 - 1
          print(
            string.format(
              "make_center_layout-3:%s, total(height/width):%s/%s, center row/col:%s/%s\n",
              vim.inspect(actual),
              vim.inspect(total_height),
              vim.inspect(total_width),
              vim.inspect(center_row),
              vim.inspect(center_col)
            )
          )
          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))
          assert_true(isclose((actual.end_row + actual.start_row) / 2, center_row))
          assert_true(isclose((actual.end_col + actual.start_col) / 2, center_col))
        end)
        it("test4 with fzf_preview_window_opts", function()
          local actual = popup_helpers.make_center_layout({
            relative = "editor",
            height = 0.75,
            width = 0.85,
            row = 0,
            col = 0,
          }, { position = "left", size = 35, size_is_percent = true })
          local total_width = vim.o.columns
          local total_height = vim.o.lines
          local width = total_width * 0.85
          local height = total_height * 0.75
          local center_row = total_height / 2
          local center_col = total_width / 2

          print(
            string.format(
              "make_center_layout-4, actual:%s, total(height/width):%s/%s, center(row/col):%s/%s, height/width:%s/%s\n",
              vim.inspect(actual),
              vim.inspect(total_height),
              vim.inspect(total_width),
              vim.inspect(center_row),
              vim.inspect(center_col),
              vim.inspect(height),
              vim.inspect(width)
            )
          )

          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))
          assert_true(isclose(2 * (center_row - actual.start_row), height))
          assert_true(isclose(2 * (actual.end_row - center_row), height))
          assert_true(isclose(2 * (center_col - actual.start_col), width))
          assert_true(isclose(2 * (actual.end_col - center_col), width))

          assert_true(isclose(actual.provider.width, width * 0.65 - 1))
          assert_true(isclose(actual.provider.height, height))
          assert_eq(actual.provider.start_row, actual.start_row)
          assert_eq(actual.provider.end_row, actual.end_row)
          assert_eq(actual.provider.start_col, actual.start_col + actual.previewer.width + 2)
          assert_eq(actual.provider.end_col, actual.end_col)

          assert_true(isclose(actual.previewer.width, width * 0.35 - 1))
          assert_true(isclose(actual.previewer.height, height))
          assert_eq(actual.previewer.start_row, actual.start_row)
          assert_eq(actual.previewer.end_row, actual.end_row)
          assert_eq(actual.previewer.start_col, actual.start_col)
          assert_eq(actual.previewer.end_col, actual.start_col + actual.previewer.width)
        end)
        it("test5 with fzf_preview_window_opts", function()
          local actual = popup_helpers.make_center_layout({
            relative = "editor",
            height = 1,
            width = 1,
            row = 0,
            col = 0,
          }, { position = "up", size = 15 })
          local total_height = vim.o.lines
          local total_width = vim.o.columns
          local width = total_width
          local height = total_height
          local center_row = total_height / 2
          local center_col = total_width / 2
          print(
            string.format(
              "make_center_layout-5:%s, total(height/width):%s/%s,center(row/col):%s/%s\n",
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

          assert_true(isclose(actual.provider.height, height - 15 - 1))
          assert_eq(actual.provider.width, width)
          assert_eq(actual.provider.start_row, actual.start_row + actual.previewer.height + 1)
          assert_eq(actual.provider.end_row, actual.end_row)
          assert_eq(actual.provider.start_col, actual.start_col)
          assert_eq(actual.provider.end_col, actual.end_col)

          assert_true(isclose(actual.previewer.height, 15 - 1))
          assert_eq(actual.previewer.width, width)
          assert_eq(actual.previewer.start_row, actual.start_row)
          assert_eq(actual.previewer.end_row, actual.start_row + actual.previewer.height)
          assert_eq(actual.previewer.start_col, actual.start_col)
          assert_eq(actual.previewer.end_col, actual.end_col)
        end)
        it("test6 with fzf_preview_window_opts", function()
          local actual = popup_helpers.make_center_layout({
            relative = "win",
            height = 0.9,
            width = 0.85,
            row = 1,
            col = -2,
          }, { position = "up", size = 15 })
          local total_height = vim.api.nvim_win_get_height(0)
          local total_width = vim.api.nvim_win_get_width(0)
          local width = total_width * 0.85
          local height = total_height * 0.9
          local center_row = total_height / 2 + 1
          local center_col = total_width / 2 - 2
          print(
            string.format(
              "make_center_layout-6:%s, total(height/width):%s/%s, height/width:%s/%s, center(row/col):%s/%s\n",
              vim.inspect(actual),
              vim.inspect(total_height),
              vim.inspect(total_width),
              vim.inspect(height),
              vim.inspect(width),
              vim.inspect(center_row),
              vim.inspect(center_col)
            )
          )

          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))
          assert_true(isclose(2 * (center_row - actual.start_row), height))
          print(
            string.format(
              "make_center_layout-6, (end_row(%s) - center_row(%s)) * 2 (%s) == height:%s: %s",
              vim.inspect(actual.end_row),
              vim.inspect(center_row),
              vim.inspect(2 * (actual.end_row - center_row)),
              vim.inspect(height),
              vim.inspect(isclose(2 * (actual.end_row - center_row), height))
            )
          )
          assert_true(isclose(2 * (actual.end_row - center_row), height))
          assert_true(isclose(2 * (center_col - actual.start_col), width))
          assert_true(isclose(2 * (actual.end_col - center_col), width))

          if total_height > 20 then
            assert_true(isclose(actual.provider.height, height - 15 - 1))
          end
          assert_true(isclose(actual.provider.width, width))
          assert_true(
            isclose(actual.provider.start_row, actual.start_row + actual.previewer.height + 1)
          )
          assert_eq(actual.provider.end_row, actual.end_row)
          assert_eq(actual.provider.start_col, actual.start_col)
          assert_eq(actual.provider.end_col, actual.end_col)

          if total_height > 20 then
            assert_true(isclose(actual.previewer.height, 15 - 1))
          end
          assert_true(isclose(actual.previewer.width, width))
          assert_eq(actual.previewer.start_row, actual.start_row)
          assert_true(isclose(actual.previewer.end_row, actual.start_row + actual.previewer.height))
          assert_eq(actual.previewer.start_col, actual.start_col)
          assert_eq(actual.previewer.end_col, actual.end_col)
        end)
      end
    end
  end)
  describe("[make_cursor_layout]", function()
    for i = min_test_height, max_test_height, 2 do
      for j = min_test_width, max_test_width, 3 do
        test_height = i
        test_width = j
        local function isclose(a, b)
          if github_actions then
            return math.abs(math.abs(a) - math.abs(b)) <= 3.5
          else
            return math.abs(a - b) <= 2.5
          end
        end

        it("test1 without fzf_preview_window_opts", function()
          local actual = popup_helpers.make_cursor_layout({
            height = 0.75,
            width = 0.85,
            row = 0,
            col = 0,
          })
          print(string.format("make_cursor_layout-1:%s\n", vim.inspect(actual)))
          local total_width = vim.api.nvim_win_get_width(0)
          local total_height = vim.api.nvim_win_get_height(0)
          local width = total_width * 0.85
          local height = total_height * 0.75
          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))
        end)
        it("test2 without fzf_preview_window_opts", function()
          local actual = popup_helpers.make_cursor_layout({
            height = 0.47,
            width = 0.71,
            row = 0,
            col = 0,
          })
          local total_height = vim.api.nvim_win_get_height(0)
          local total_width = vim.api.nvim_win_get_width(0)
          local width = total_width * 0.71
          local height = total_height * 0.47
          print(
            string.format(
              "make_cursor_layout-2:%s, total(height/width):%s/%s\n",
              vim.inspect(actual),
              vim.inspect(total_height),
              vim.inspect(total_width)
            )
          )
          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))
        end)
        it("test3 without fzf_preview_window_opts", function()
          local actual = popup_helpers.make_cursor_layout({
            height = 0.77,
            width = 0.81,
            row = -1,
            col = 2,
          })
          local total_height = vim.api.nvim_win_get_height(0)
          local total_width = vim.api.nvim_win_get_width(0)
          local width = total_width * 0.81
          local height = total_height * 0.77
          print(
            string.format(
              "make_cursor_layout-3:%s, total(height/width):%s/%s\n",
              vim.inspect(actual),
              vim.inspect(total_height),
              vim.inspect(total_width)
            )
          )
          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))
        end)
        it("test4 with fzf_preview_window_opts", function()
          local actual = popup_helpers.make_cursor_layout({
            height = 0.75,
            width = 0.85,
            row = 0,
            col = 0,
          }, { position = "left", size = 35, size_is_percent = true })
          local total_height = vim.api.nvim_win_get_height(0)
          local total_width = vim.api.nvim_win_get_width(0)
          local width = total_width * 0.85
          local height = total_height * 0.75

          print(
            string.format(
              "make_cursor_layout-4, actual:%s, total(height/width):%s/%s, height/width:%s/%s\n",
              vim.inspect(actual),
              vim.inspect(total_height),
              vim.inspect(total_width),
              vim.inspect(height),
              vim.inspect(width)
            )
          )

          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))
          assert_true(isclose(actual.provider.width, width * 0.65 - 1))
          assert_true(isclose(actual.provider.height, height))
          assert_eq(actual.provider.start_row, actual.start_row)
          assert_eq(actual.provider.end_row, actual.end_row)
          assert_eq(actual.provider.start_col, actual.start_col + actual.previewer.width + 2)
          assert_eq(actual.provider.end_col, actual.end_col)

          assert_true(isclose(actual.previewer.width, width * 0.35 - 1))
          assert_true(isclose(actual.previewer.height, height))
          assert_eq(actual.previewer.start_row, actual.start_row)
          assert_eq(actual.previewer.end_row, actual.end_row)
          assert_eq(actual.previewer.start_col, actual.start_col)
          assert_eq(actual.previewer.end_col, actual.start_col + actual.previewer.width)
        end)
        it("test5 with fzf_preview_window_opts", function()
          local actual = popup_helpers.make_cursor_layout({
            height = 1,
            width = 1,
            row = 0,
            col = 0,
          }, { position = "up", size = 15 })
          local total_height = vim.api.nvim_win_get_height(0)
          local total_width = vim.api.nvim_win_get_width(0)
          local width = total_width
          local height = total_height
          print(
            string.format(
              "make_cursor_layout-5:%s, total(height/width):%s/%s\n",
              vim.inspect(actual),
              vim.inspect(total_height),
              vim.inspect(total_width)
            )
          )

          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))

          assert_true(isclose(actual.provider.height, height - 15 - 1))
          assert_eq(actual.provider.width, width)
          assert_eq(actual.provider.start_row, actual.start_row + actual.previewer.height + 1)
          assert_eq(actual.provider.end_row, actual.end_row)
          assert_eq(actual.provider.start_col, actual.start_col)
          assert_eq(actual.provider.end_col, actual.end_col)

          assert_true(isclose(actual.previewer.height, 15 - 1))
          assert_eq(actual.previewer.width, width)
          assert_eq(actual.previewer.start_row, actual.start_row)
          assert_eq(actual.previewer.end_row, actual.start_row + actual.previewer.height)
          assert_eq(actual.previewer.start_col, actual.start_col)
          assert_eq(actual.previewer.end_col, actual.end_col)
        end)
        it("test6 with fzf_preview_window_opts", function()
          local actual = popup_helpers.make_cursor_layout({
            height = 0.9,
            width = 0.85,
            row = 1,
            col = -2,
          }, { position = "up", size = 15 })
          local total_height = vim.api.nvim_win_get_height(0)
          local total_width = vim.api.nvim_win_get_width(0)
          local width = total_width * 0.85
          local height = total_height * 0.9
          print(
            string.format(
              "make_cursor_layout-6:%s, total(height/width):%s/%s, height/width:%s/%s\n",
              vim.inspect(actual),
              vim.inspect(total_height),
              vim.inspect(total_width),
              vim.inspect(height),
              vim.inspect(width)
            )
          )

          assert_true(isclose(actual.width, width))
          assert_true(isclose(actual.height, height))

          if total_height > 20 then
            assert_true(isclose(actual.provider.height, height - 15 - 1))
          end
          assert_true(isclose(actual.provider.width, width))
          assert_true(
            isclose(actual.provider.start_row, actual.start_row + actual.previewer.height + 1)
          )
          assert_eq(actual.provider.end_row, actual.end_row)
          assert_eq(actual.provider.start_col, actual.start_col)
          assert_eq(actual.provider.end_col, actual.end_col)

          if total_height > 20 then
            assert_true(isclose(actual.previewer.height, 15 - 1))
          end
          assert_true(isclose(actual.previewer.width, width))
          assert_eq(actual.previewer.start_row, actual.start_row)
          assert_true(isclose(actual.previewer.end_row, actual.start_row + actual.previewer.height))
          assert_eq(actual.previewer.start_col, actual.start_col)
          assert_eq(actual.previewer.end_col, actual.end_col)
        end)
      end
    end
  end)
end)
