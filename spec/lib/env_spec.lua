local cwd = vim.fn.getcwd()

describe("lib.env", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local env = require("fzfx.lib.env")
  describe("[debug_enable]", function()
    it("is enabled", function()
      vim.env._FZFX_NVIM_DEBUG_ENABLE = 1
      assert_true(env.debug_enabled())
    end)
    it("is disabled", function()
      vim.env._FZFX_NVIM_DEBUG_ENABLE = 0
      assert_false(env.debug_enabled())
    end)
  end)

  describe("[icon_enable]", function()
    it("is enabled", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = "lazy/nvim-web-devicons"
      assert_true(env.icon_enabled())
    end)
    it("is disabled", function()
      vim.env._FZFX_NVIM_DEVICONS_PATH = nil
      assert_false(env.icon_enabled())
    end)
  end)
end)
