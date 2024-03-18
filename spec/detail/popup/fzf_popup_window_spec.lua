local cwd = vim.fn.getcwd()

describe("detail.popup.fzf_popup_window", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.cmd("edit README.md")
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

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
    it("test", function()
      local actual = fzf_popup_window._make_cursor_opts(
        vim.tbl_deep_extend("force", vim.deepcopy(WIN_OPTS), { relative = "cursor" }),
        0
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
      assert_eq(actual.row, 0)
      assert_eq(type(actual.col), "number")
      assert_eq(actual.col, 0)
    end)
  end)
  describe("[_make_center_opts]", function()
    it("test", function()
      local actual = fzf_popup_window._make_center_opts(
        vim.tbl_deep_extend("force", vim.deepcopy(WIN_OPTS), { relative = "win" }),
        0
      )
      print(string.format("fzf_popup_window._make_center_opts:%s\n", vim.inspect(actual)))
      local total_width = vim.api.nvim_win_get_width(0)
      local total_height = vim.api.nvim_win_get_height(0)
      local expect_width = num.bound(total_width * 0.85, 1, total_width)
      local expect_height = num.bound(total_height * 0.85, 1, total_height)
      local expect_row = math.floor((total_height / 2) - (expect_height / 2))
      local expect_col = math.floor((total_width / 2) - (expect_width / 2))
      print(
        string.format(
          "fzf_popup_window._make_center_opts total(height/width):%s/%s, expect(height/width):%s/%s, expect(row/col):%s/%s\n",
          vim.inspect(total_height),
          vim.inspect(total_width),
          vim.inspect(expect_height),
          vim.inspect(expect_width),
          vim.inspect(expect_row),
          vim.inspect(expect_col)
        )
      )
      assert_eq(actual.anchor, "NW")
      assert_eq(type(actual.height), "number")
      assert_true(num.eq(actual.height, expect_height, 1, 1))
      assert_eq(type(actual.width), "number")
      assert_true(num.eq(actual.width, expect_width, 0.1, 0.1))
      assert_eq(type(actual.row), "number")
      assert_eq(type(actual.col), "number")
      if not github_actions then
        assert_eq(actual.row, expect_row)
        assert_eq(actual.col, expect_col)
      end
    end)
  end)
  describe("[make_opts]", function()
    it("test", function()
      local actual1 = fzf_popup_window.make_opts(WIN_OPTS, 0)
      local actual2 = fzf_popup_window._make_center_opts(WIN_OPTS, 0)
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
  end)
end)
