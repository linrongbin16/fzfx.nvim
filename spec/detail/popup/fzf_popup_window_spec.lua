local cwd = vim.fn.getcwd()

describe("detail.popup.fzf_popup_window", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local min_test_height = 25
  local max_test_height = 35
  local min_test_width = 130
  local max_test_width = 140
  local test_height = min_test_height
  local test_width = min_test_width

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.cmd("edit README.md")
    if github_actions then
      vim.cmd(string.format("set lines=%d", test_height))
      vim.cmd(string.format("set columns=%d", test_width))
      vim.api.nvim_win_set_height(0, test_height)
      vim.api.nvim_win_set_width(0, test_width)
    end
  end)

  local num = require("fzfx.commons.num")
  local fzf_popup_window = require("fzfx.detail.popup.fzf_popup_window")
  require("fzfx").setup({
    debug = {
      enable = true,
      file_log = true,
    },
  })

  local WIN_OPTS = {
    height = 0.85,
    width = 0.85,
    row = 0,
    col = 0,
  }
  describe("[_make_cursor_opts]", function()
    for i = min_test_height, max_test_height, 3 do
      for j = min_test_width, max_test_width, 2 do
        test_height = i
        test_width = j
        it("test", function()
          local actual = fzf_popup_window._make_cursor_opts(
            vim.tbl_deep_extend("force", vim.deepcopy(WIN_OPTS), { relative = "cursor" }),
            0,
            1
          )
          print(string.format("fzf_popup_window._make_cursor_opts:%s\n", vim.inspect(actual)))
          local win_width = vim.api.nvim_win_get_width(0)
          local win_height = vim.api.nvim_win_get_height(0)
          local expect_width = num.bound(win_width * 0.85, 1, win_width)
          local expect_height = num.bound(win_height * 0.85, 1, win_height)
          assert_eq(actual.anchor, "NW")
          assert_eq(type(actual.height), "number")
          assert_true(num.eq(actual.height, expect_height, 1, 1))
          assert_eq(type(actual.width), "number")
          assert_true(num.eq(actual.width, expect_width, 0.1, 0.1))
          assert_eq(type(actual.row), "number")
          assert_eq(type(actual.col), "number")
        end)
      end
    end
  end)
  describe("[_make_center_opts]", function()
    for i = min_test_height, max_test_height, 3 do
      for j = min_test_width, max_test_width, 2 do
        test_height = i
        test_width = j
        it("test", function()
          local actual = fzf_popup_window._make_center_opts(
            vim.tbl_deep_extend("force", vim.deepcopy(WIN_OPTS), { relative = "win" }),
            0,
            1
          )
          print(string.format("fzf_popup_window._make_center_opts:%s\n", vim.inspect(actual)))
          local total_width = vim.api.nvim_win_get_width(0)
          local total_height = vim.api.nvim_win_get_height(0)
          local width = total_width * 0.85
          local height = total_height * 0.85
          local start_row = total_height * 0.5 - 1 - (height / 2)
          local start_col = total_width * 0.5 - 1 - (width / 2)
          print(
            string.format(
              "fzf_popup_window._make_center_opts total(height/width):%s/%s, height/width:%s/%s, start(row/col):%s/%s\n",
              vim.inspect(total_height),
              vim.inspect(total_width),
              vim.inspect(height),
              vim.inspect(width),
              vim.inspect(start_row),
              vim.inspect(start_col)
            )
          )
          assert_eq(actual.anchor, "NW")
          assert_true(num.eq(actual.height, height, 1, 1))
          assert_true(num.eq(actual.width, width, 0.1, 0.1))
          assert_true(num.eq(actual.row, start_row, 1, 1))
          assert_true(num.eq(actual.col, start_col, 1, 1))
        end)
      end
    end
  end)
  describe("[make_opts]", function()
    for i = min_test_height, max_test_height, 3 do
      for j = min_test_width, max_test_width, 2 do
        test_height = i
        test_width = j
        it("test", function()
          local actual1 = fzf_popup_window.make_opts(WIN_OPTS, 0, 1)
          local actual2 = fzf_popup_window._make_center_opts(WIN_OPTS, 0, 1)
          print(
            string.format(
              "fzf_popup_window.make_opts:%s, _make_center_opts:%s\n",
              vim.inspect(actual1),
              vim.inspect(actual2)
            )
          )
          assert_eq(actual1.anchor, "NW")
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
      end
    end
  end)
end)
