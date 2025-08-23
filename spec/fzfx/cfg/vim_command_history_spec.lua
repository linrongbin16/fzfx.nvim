local cwd = vim.fn.getcwd()

describe("fzfx.cfg.vim_command_history", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local GITHUB_ACTIONS = os.getenv("GITHUB_ACTIONS") == "true"

  local str = require("fzfx.commons.str")
  local tbl = require("fzfx.commons.tbl")
  local consts = require("fzfx.lib.constants")
  local vim_command_history_cfg = require("fzfx.cfg.vim_command_history")
  -- require("fzfx").setup()

  describe("[commands]", function()
    it("_provider", function()
      local command_history = vim_command_history_cfg._provider()
      if command_history then
        assert_eq(type(command_history), "table")
        for i, ch in ipairs(command_history) do
          assert_eq(type(ch), "string")
          assert_true(string.len(ch) > 0)
          print(string.format("_provider [%d]:%s\n", i, vim.inspect(ch)))
        end
      end
    end)
  end)
end)
