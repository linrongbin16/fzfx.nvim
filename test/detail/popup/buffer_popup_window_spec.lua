local cwd = vim.fn.getcwd()

describe("detail.popup.buffer_popup_window", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
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
    end)
  end)
end)
