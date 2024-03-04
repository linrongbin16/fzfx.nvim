---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("detail.rpcserver", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
  end)

  local num = require("fzfx.commons.num")
  local rpcserver = require("fzfx.detail.rpcserver")
  rpcserver.setup()

  describe("[RpcServer]", function()
    it("create server", function()
      local s = rpcserver.get_instance()
      assert_eq(type(s), "table")
      local sockaddr = vim.env._FZFX_NVIM_RPC_SERVER_ADDRESS
      print(string.format("rpc server socket:%s\n", vim.inspect(sockaddr)))
      assert_eq(type(sockaddr), "string")
      assert_true(string.len(sockaddr) > 0)
    end)
    it("register/unregister", function()
      local s = rpcserver.get_instance()
      local f = function(x) end
      local rid = s:register(f)
      assert_eq(type(rid), "string")
      assert_true(tonumber(rid) == num.auto_incremental_id() - 1)
      local actual1 = s:get(rid)
      assert_eq(type(actual1), "function")
      assert_eq(vim.inspect(f), vim.inspect(actual1))
      local actual2 = s:unregister(rid)
      assert_eq(type(actual2), "function")
      assert_eq(vim.inspect(f), vim.inspect(actual2))
      assert_eq(vim.inspect(actual1), vim.inspect(actual2))
    end)
  end)
end)
