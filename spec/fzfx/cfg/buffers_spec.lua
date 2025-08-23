---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("fzfx.cfg.buffers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.env._FZFX_NVIM_DEVICONS_PATH = nil
    vim.cmd([[noautocmd edit README.md]])
  end)

  local GITHUB_ACTIONS = os.getenv("GITHUB_ACTIONS") == "true"

  require("fzfx").setup()
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local buffers_cfg = require("fzfx.cfg.buffers")

  --- @return fzfx.PipelineContext
  local function make_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  describe("[buffers]", function()
    it("_provider", function()
      local actual = buffers_cfg._provider("", make_context())
      assert_eq(type(actual), "table")
      assert_true(#actual >= 0)
    end)
    it("_delete_buffer", function()
      local ok, err = pcall(buffers_cfg._delete_buffer, "README.md")
      assert_true(ok)
    end)
  end)
end)
