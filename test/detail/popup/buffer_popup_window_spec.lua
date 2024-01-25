local cwd = vim.fn.getcwd()

describe("detail.popup.buffer_popup_window", function()
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
  local buffer_popup_window = require("fzfx.detail.popup.buffer_popup_window")
  local popup_helpers = require("fzfx.detail.popup.popup_helpers")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
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
    border = "none",
    zindex = 51,
  }
  describe("[BufferPopupWindow]", function()
    it("new right,50%", function()
      local pw_opts1 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window",
        "right,50%",
      })
      local actual =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, pw_opts1)
      print(
        string.format(
          "BufferPopupWindow:new right,50%%:%s\n",
          vim.inspect(actual)
        )
      )
      local provider_winnr = actual.provider_winnr
      local previewer_winnr = actual.previewer_winnr
      local provider_bufnr = actual.provider_winnr
      local previewer_bufnr = actual.previewer_winnr
      assert_true(provider_winnr > 0)
      assert_true(previewer_winnr > 0)
      assert_true(provider_bufnr > 0)
      assert_true(previewer_bufnr > 0)

      local provider_height = vim.api.nvim_win_get_height(provider_winnr)
      local provider_width = vim.api.nvim_win_get_width(provider_winnr)
      local previewer_height = vim.api.nvim_win_get_height(previewer_winnr)
      local previewer_width = vim.api.nvim_win_get_width(previewer_winnr)

      local expect_total_height = vim.o.lines * WIN_OPTS.height
      local expect_total_width = vim.o.columns * WIN_OPTS.width
      print(
        string.format(
          "BufferPopupWindow:new right,50%%, provider:%s/%s, previewer:%s/%s, epxect total:%s/%s\n",
          vim.inspect(provider_height),
          vim.inspect(provider_width),
          vim.inspect(previewer_height),
          vim.inspect(previewer_width),
          vim.inspect(expect_total_height),
          vim.inspect(expect_total_width)
        )
      )
      assert_eq(provider_height, previewer_height)
      assert_true(
        expect_total_height - 10 <= provider_height
          and provider_height <= expect_total_height + 10
      )
      assert_true(
        expect_total_width - 10 <= provider_width + previewer_width
          and provider_width + previewer_width <= expect_total_width + 10
      )
    end)
  end)
end)
