local cwd = vim.fn.getcwd()

describe("fzfx.cfg.lsp_diagnostics", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local str = require("fzfx.commons.str")
  local lsp_diagnostics_cfg = require("fzfx.cfg.lsp_diagnostics")
  require("fzfx").setup()

  describe("lsp_diagnostics", function()
    it("_make_signs", function()
      local actual = lsp_diagnostics_cfg._make_signs()
      assert_eq(type(actual), "table")
      assert_eq(#actual, 4)
      for i, sign in ipairs(actual) do
        assert_eq(type(sign), "table")
        assert_true(sign.severity >= 1 and sign.severity <= 4)
        assert_true(string.len(sign.name) > 0 and str.startswith(sign.name, "DiagnosticSign"))
        assert_true(
          str.endswith(sign.name, "Error")
            or str.endswith(sign.name, "Warn")
            or str.endswith(sign.name, "Info")
            or str.endswith(sign.name, "Hint")
        )
      end
    end)
    it("_process_diag", function()
      local diags = {
        { bufnr = 0, lnum = 1, col = 1, message = "a", severity = 1 },
        { bufnr = 1, lnum = 1, col = 1, message = "b", severity = 2 },
        { bufnr = 2, lnum = 1, col = 1, message = "c", severity = 3 },
        { bufnr = 3, lnum = 1, col = 1, message = "d", severity = 4 },
        { bufnr = 5, lnum = 1, col = 1, message = "e" },
      }
      for _, diag in ipairs(diags) do
        local actual = lsp_diagnostics_cfg._process_diag(diag)
        if actual ~= nil then
          assert_eq(actual.bufnr, diag.bufnr)
          assert_eq(actual.lnum, diag.lnum + 1)
          assert_eq(actual.col, diag.col + 1)
          assert_eq(actual.severity, diag.severity or 1)
        end
      end
    end)
    it("_render_diag_to_line", function()
      local inputs = {
        {
          bufnr = 0,
          filename = "lua/fzfx/config.lua",
          lnum = 10,
          col = 13,
          text = "Unused local `query`",
          severity = 1,
        },
        {
          bufnr = 0,
          filename = "lua/fzfx/config.lua",
          lnum = 1,
          col = 2,
          text = "Unused local `query`",
          severity = 2,
        },
        {
          bufnr = 0,
          filename = "lua/fzfx/config.lua",
          lnum = 5000,
          col = 500,
          text = "Unused local `query`",
          severity = 3,
        },
        {
          bufnr = 0,
          filename = "lua/fzfx/config.lua",
          lnum = 30,
          col = 12,
          text = "Unused local `query`",
          severity = 4,
        },
        {
          bufnr = 0,
          filename = "lua/fzfx/config.lua",
          lnum = 30,
          col = 12,
          text = "Unused local `query`",
        },
      }
      for _, input in ipairs(inputs) do
        local actual = lsp_diagnostics_cfg._render_diag_to_line(input)
        assert_eq(type(actual), "string")
        assert_true(str.find(actual, input.text) > 0)
        assert_true(str.find(actual, tostring(input.filename)) > 0)
        assert_true(str.find(actual, tostring(input.lnum)) > 0)
        assert_true(str.find(actual, tostring(input.col)) > 0)
      end
    end)
    it("_make_provider", function()
      local f = lsp_diagnostics_cfg._make_provider()
      local actual = f("", {})
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(#actual >= 0)
        for _, act in ipairs(actual) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) >= 0)
        end
      end
    end)
  end)
end)
