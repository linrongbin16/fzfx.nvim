local cwd = vim.fn.getcwd()

describe("health", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.health = {
      start = function() end,
      ok = function() end,
      error = function() end,
      warn = function() end,
    }
  end)

  local health = require("fzfx.health")

  describe("[check]", function()
    it("run", function()
      health.check()
    end)
  end)
end)
