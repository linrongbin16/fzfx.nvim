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
  local numbers = require("fzfx.commons.numbers")
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
  }
  describe("[BufferPopupWindow]", function()
    it("new right,50%", function()
      local pw_opts = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "right,50%",
        },
      })
      local builtin_opts = {
        fzf_preview_window_opts = pw_opts,
        fzf_border_opts = "rounded",
      }
      local actual =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
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
      assert_true(actual:previewer_is_valid())
      assert_true(actual:handle() > 0)

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
    it("new down,50%", function()
      local pw_opts = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "down,50%",
        },
      })
      local builtin_opts = {
        fzf_preview_window_opts = pw_opts,
        fzf_border_opts = "rounded",
      }
      local actual =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      print(
        string.format(
          "BufferPopupWindow:new down,50%%:%s\n",
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
      assert_true(actual:previewer_is_valid())
      assert_true(actual:handle() > 0)

      local provider_height = vim.api.nvim_win_get_height(provider_winnr)
      local provider_width = vim.api.nvim_win_get_width(provider_winnr)
      local previewer_height = vim.api.nvim_win_get_height(previewer_winnr)
      local previewer_width = vim.api.nvim_win_get_width(previewer_winnr)

      local expect_total_height = vim.o.lines * WIN_OPTS.height
      local expect_total_width = vim.o.columns * WIN_OPTS.width
      print(
        string.format(
          "BufferPopupWindow:new down,50%%, provider:%s/%s, previewer:%s/%s, epxect total:%s/%s\n",
          vim.inspect(provider_height),
          vim.inspect(provider_width),
          vim.inspect(previewer_height),
          vim.inspect(previewer_width),
          vim.inspect(expect_total_height),
          vim.inspect(expect_total_width)
        )
      )
      assert_eq(provider_width, previewer_width)
      assert_true(
        expect_total_height - 10 <= (provider_height + previewer_height)
          and (provider_height + previewer_height) <= expect_total_height + 10
      )
      assert_true(
        expect_total_width - 10 <= provider_width
          and provider_width <= expect_total_width + 10
      )
    end)
    it("close", function()
      local pw_opts = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "left,50",
        },
      })
      local builtin_opts = {
        fzf_preview_window_opts = pw_opts,
        fzf_border_opts = "rounded",
      }
      local actual =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      print(
        string.format("BufferPopupWindow:new left,50:%s\n", vim.inspect(actual))
      )
      local provider_winnr = actual.provider_winnr
      local previewer_winnr = actual.previewer_winnr
      local provider_bufnr = actual.provider_winnr
      local previewer_bufnr = actual.previewer_winnr
      assert_true(provider_winnr > 0)
      assert_true(previewer_winnr > 0)
      assert_true(provider_bufnr > 0)
      assert_true(previewer_bufnr > 0)
      assert_true(actual:previewer_is_valid())
      assert_true(actual:handle() > 0)

      actual:close()
      assert_eq(actual.provider_winnr, nil)
      assert_eq(actual.previewer_winnr, nil)
      assert_eq(actual.provider_bufnr, nil)
      assert_eq(actual.previewer_bufnr, nil)
      assert_false(actual:previewer_is_valid())
      assert_eq(actual:handle(), nil)
    end)
    it("preview_files_queue", function()
      local pw_opts =
        fzf_helpers.parse_fzf_preview_window_opts({ "--preview-window=up,50" })
      local builtin_opts = {
        fzf_preview_window_opts = pw_opts,
        fzf_border_opts = "rounded",
      }
      local actual =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      assert_true(actual:preview_files_queue_empty())
      table.insert(actual.preview_files_queue, 1)
      assert_false(actual:preview_files_queue_empty())
      assert_eq(actual:preview_files_queue_last(), 1)
      actual:preview_files_queue_clear()
      assert_true(actual:preview_files_queue_empty())
    end)
    it("preview_file_contents_queue", function()
      local pw_opts = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=right,50",
      })
      local builtin_opts = {
        fzf_preview_window_opts = pw_opts,
        fzf_border_opts = "rounded",
      }
      local actual =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      assert_true(actual:preview_file_contents_queue_empty())
      table.insert(actual.preview_file_contents_queue, 1)
      assert_false(actual:preview_file_contents_queue_empty())
      assert_eq(actual:preview_file_contents_queue_last(), 1)
      actual:preview_file_contents_queue_clear()
      assert_true(actual:preview_file_contents_queue_empty())
    end)
    it("preview_file", function()
      local pw_opts = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=right,50",
      })
      local builtin_opts = {
        fzf_preview_window_opts = pw_opts,
        fzf_border_opts = "rounded",
      }
      local actual =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      actual:preview_file(
        numbers.auto_incremental_id(),
        { filename = "README.md" }
      )
      vim.wait(10000, function()
        return actual:preview_files_queue_empty()
          and actual:preview_file_contents_queue_empty()
      end)
    end)
    it("preview_action", function()
      local pw_opts = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=right,50",
      })
      local builtin_opts = {
        fzf_preview_window_opts = pw_opts,
        fzf_border_opts = "rounded",
      }
      local actual =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      actual:preview_file(
        numbers.auto_incremental_id(),
        { filename = "README.md" }
      )
      vim.wait(10000, function()
        return actual:preview_files_queue_empty()
          and actual:preview_file_contents_queue_empty()
      end)
      actual:preview_action("preview-half-page-down")
      actual:preview_action("preview-half-page-up")
      actual:preview_action("preview-page-down")
      actual:preview_action("preview-page-up")
    end)
  end)
  describe("[scroll_by]", function()
    local pw_opts = fzf_helpers.parse_fzf_preview_window_opts({
      {
        "--preview-window",
        "right,50%",
      },
    })
    local builtin_opts = {
      fzf_preview_window_opts = pw_opts,
      fzf_border_opts = "rounded",
    }
    it("scroll up 100%", function()
      local bpw =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      buffer_popup_window.scroll_by(
        bpw.previewer_winnr,
        bpw.previewer_bufnr,
        100,
        true
      )
    end)
    it("scroll down 100%", function()
      local bpw =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      buffer_popup_window.scroll_by(
        bpw.previewer_winnr,
        bpw.previewer_bufnr,
        100,
        false
      )
    end)
    it("scroll up 50%", function()
      local bpw =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      buffer_popup_window.scroll_by(
        bpw.previewer_winnr,
        bpw.previewer_bufnr,
        50,
        true
      )
    end)
    it("scroll down 100%", function()
      local bpw =
        buffer_popup_window.BufferPopupWindow:new(WIN_OPTS, builtin_opts)
      buffer_popup_window.scroll_by(
        bpw.previewer_winnr,
        bpw.previewer_bufnr,
        50,
        false
      )
    end)
  end)
end)
