---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
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

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local str = require("fzfx.commons.str")
  local consts = require("fzfx.lib.constants")
  local contexts = require("fzfx.helper.contexts")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local lsp_diagnostics_cfg = require("fzfx.cfg.lsp_diagnostics")
  require("fzfx").setup()

  describe("lsp_diagnostics", function()
    it("_make_lsp_diagnostic_signs", function()
      local actual = lsp_diagnostics_cfg._make_lsp_diagnostic_signs()
      assert_eq(type(actual), "table")
      assert_eq(#actual, 4)
      for i, sign_item in ipairs(actual) do
        assert_eq(type(sign_item), "table")
        assert_true(sign_item.severity >= 1 and sign_item.severity <= 4)
        assert_true(
          string.len(sign_item.name) > 0 and str.startswith(sign_item.name, "DiagnosticSign")
        )
        assert_true(
          str.endswith(sign_item.name, "Error")
            or str.endswith(sign_item.name, "Warn")
            or str.endswith(sign_item.name, "Info")
            or str.endswith(sign_item.name, "Hint")
        )
      end
    end)
    it("_process_lsp_diagnostic_item", function()
      local diags = {
        { bufnr = 0, lnum = 1, col = 1, message = "a", severity = 1 },
        { bufnr = 1, lnum = 1, col = 1, message = "b", severity = 2 },
        { bufnr = 2, lnum = 1, col = 1, message = "c", severity = 3 },
        { bufnr = 3, lnum = 1, col = 1, message = "d", severity = 4 },
        { bufnr = 5, lnum = 1, col = 1, message = "e" },
      }
      for _, diag in ipairs(diags) do
        local actual = lsp_diagnostics_cfg._process_lsp_diagnostic_item(diag)
        if actual ~= nil then
          assert_eq(actual.bufnr, diag.bufnr)
          assert_eq(actual.lnum, diag.lnum + 1)
          assert_eq(actual.col, diag.col + 1)
          assert_eq(actual.severity, diag.severity or 1)
        end
      end
    end)
    it("_make_lsp_diagnostics_provider", function()
      local f = lsp_diagnostics_cfg._make_lsp_diagnostics_provider()
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
