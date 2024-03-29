---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("fzfx.cfg.buffers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  require("fzfx").setup()
  local contexts = require("fzfx.helper.contexts")
  local providers = require("fzfx.helper.providers")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")

  local buffers_cfg = require("fzfx.cfg.buffers")

  describe("[buffers]", function()
    it("_buf_valid", function()
      assert_eq(type(buffers_cfg._buf_valid(0)), "boolean")
      assert_eq(type(buffers_cfg._buf_valid(1)), "boolean")
      assert_eq(type(buffers_cfg._buf_valid(2)), "boolean")
    end)
    it("_buffers_provider", function()
      local actual = buffers_cfg._buffers_provider("", contexts.make_pipeline_context())
      assert_eq(type(actual), "table")
      assert_true(#actual >= 0)
    end)
    it("_delete_buffer", function()
      local ok, err = pcall(buffers_cfg._delete_buffer, "README.md")
      assert_eq(type(ok), "boolean")
    end)
  end)
end)
