local cwd = vim.fn.getcwd()

describe("detail.popup.buffer_popup_window_helpers", function()
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
    vim.cmd([[noautocmd edit README.md]])
    if github_actions then
      vim.cmd(string.format("set lines=%d", test_height))
      vim.cmd(string.format("set columns=%d", test_width))
      vim.api.nvim_win_set_height(0, test_height)
      vim.api.nvim_win_set_width(0, test_width)
    end
  end)

  local buffer_popup_window_helpers = require("fzfx.detail.popup.buffer_popup_window_helpers")

  require("fzfx").setup({
    debug = {
      enable = true,
      file_log = true,
    },
  })
  describe("[make_view/adjust_view]", function()
    it("adjust_view", function()
      local actual11, actual12 = buffer_popup_window_helpers.adjust_top_and_bottom(20, 30, 100, 30)
      print(string.format("_adjust_view-1:%s,%s\n", vim.inspect(actual11), vim.inspect(actual12)))
      local actual21, actual22 = buffer_popup_window_helpers.adjust_top_and_bottom(1, 10, 100, 30)
      print(string.format("_adjust_view-2:%s,%s\n", vim.inspect(actual21), vim.inspect(actual22)))
      local actual31, actual32 = buffer_popup_window_helpers.adjust_top_and_bottom(90, 100, 100, 30)
      print(string.format("_adjust_view-3:%s,%s\n", vim.inspect(actual31), vim.inspect(actual32)))
      local actual41, actual42 = buffer_popup_window_helpers.adjust_top_and_bottom(20, 50, 100, 30)
      print(string.format("_adjust_view-4:%s,%s\n", vim.inspect(actual41), vim.inspect(actual42)))
    end)
    it("make_view_by_top", function()
      local actual1 = buffer_popup_window_helpers.make_top_view(10, 50)
      print(string.format("_make_view_by_top-1:%s\n", vim.inspect(actual1)))
      local actual2 = buffer_popup_window_helpers.make_top_view(30, 30)
      print(string.format("_make_view_by_top-2:%s\n", vim.inspect(actual2)))
      local actual3 = buffer_popup_window_helpers.make_top_view(30, 29)
      print(string.format("_make_view_by_top-3:%s\n", vim.inspect(actual3)))
      local actual4 = buffer_popup_window_helpers.make_top_view(40, 41)
      print(string.format("_make_view_by_top-4:%s\n", vim.inspect(actual4)))
    end)
  end)
end)
