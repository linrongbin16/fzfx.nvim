local cwd = vim.fn.getcwd()

describe("rpc_helpers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  require("fzfx.config").setup()
  local server = require("fzfx.server")
  server.setup()
  local rpc_helpers = require("fzfx.rpc_helpers")
  describe("[call]", function()
    it("calls", function()
      local rid = server.get_rpc_server():register(function()
        assert_true(true)
        return "rpc"
      end)
      assert_eq(rpc_helpers.call(rid), "rpc")
    end)
  end)
end)
