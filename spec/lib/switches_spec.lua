local cwd = vim.fn.getcwd()

describe("lib.switches", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local switches = require("fzfx.lib.switches")
  describe("[fzfx_disable_buffer_previewer]", function()
    it("disabled", function()
      vim.g.fzfx_disable_buffer_previewer = 1
      assert_true(switches.buffer_previewer_disabled())
      vim.g.fzfx_disable_buffer_previewer = true
      assert_true(switches.buffer_previewer_disabled())
      vim.g.fzfx_disable_buffer_previewer = "true"
      assert_false(switches.buffer_previewer_disabled())
      vim.g.fzfx_disable_buffer_previewer = nil
      assert_false(switches.buffer_previewer_disabled())
    end)
    it("enabled", function()
      vim.g.fzfx_disable_buffer_previewer = 0
      assert_false(switches.buffer_previewer_disabled())
      vim.g.fzfx_disable_buffer_previewer = false
      assert_false(switches.buffer_previewer_disabled())
      vim.g.fzfx_disable_buffer_previewer = "false"
      assert_false(switches.buffer_previewer_disabled())
      vim.g.fzfx_disable_buffer_previewer = nil
      assert_false(switches.buffer_previewer_disabled())
    end)
  end)
end)
