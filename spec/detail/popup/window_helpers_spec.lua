local cwd = vim.fn.getcwd()

describe("detail.popup.window_helpers", function()
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

  local popup_window_helpers = require("fzfx.detail.popup.window_helpers")
  require("fzfx").setup({
    debug = {
      enable = true,
      file_log = true,
    },
  })

  describe("[WindowContext]", function()
    it("save", function()
      local ctx = popup_window_helpers.WindowContext:save()
      assert_eq(type(ctx), "table")
    end)
    it("restore", function()
      local ctx = popup_window_helpers.WindowContext:save()
      assert_eq(type(ctx), "table")
      ctx:restore()
    end)
  end)
end)
