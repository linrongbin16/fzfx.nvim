local consts = require("fzfx.lib.constants")
local paths = require("fzfx.commons.paths")
local numbers = require("fzfx.commons.numbers")
local log = require("fzfx.lib.log")

local M = {}

--- @alias fzfx.RpcCallback fun(params:any):string?
--- @class fzfx.RpcServer
--- @field address string
--- @field registry table<string, fzfx.RpcCallback>
local RpcServer = {}

--- @return fzfx.RpcServer
function RpcServer:new()
  local address = consts.IS_WINDOWS and vim.fn.serverstart(paths.pipename()) or vim.fn.serverstart() --[[@as string]]
  -- log.debug(
  --     "|fzfx.rpcserver - RpcServer:new| start server on socket address:%s",
  --     vim.inspect(address)
  -- )
  log.ensure(
    type(address) == "string" and string.len(address) > 0,
    "failed to start socket server!"
  )

  -- export socket address as environment variable
  vim.env._FZFX_NVIM_RPC_SERVER_ADDRESS = address

  local o = {
    address = address,
    registry = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return string?
function RpcServer:close()
  -- log.debug("|fzfx.rpcserver - RpcServer:close| self: %s!", vim.inspect(self))
  local address = self.address
  if type(self.address) == "string" and string.len(self.address) > 0 then
    ---@diagnostic disable-next-line: unused-local
    local result = vim.fn.serverstop(self.address)
    -- log.debug(
    --     "|fzfx.rpcserver - RpcServer:close| stop result(valid): %s!",
    --     vim.inspect(result)
    -- )
  end
  self.address = nil
  return address
end

--- @param callback fzfx.RpcCallback
--- @param name string?
--- @return string
function RpcServer:register(callback, name)
  log.ensure(
    type(callback) == "function",
    "|RpcServer:register| callback f(%s) must be function! %s",
    type(callback),
    vim.inspect(callback)
  )
  local registry_id = tostring(numbers.auto_incremental_id())
  self.registry[registry_id] = function(params)
    -- log.debug(
    --   "|RpcServer:register| invoke rpc (%s-%s) with param:%s",
    --   vim.inspect(registry_id),
    --   vim.inspect(name),
    --   vim.inspect(params)
    -- )
    local ok, err = pcall(callback, params)
    -- log.debug(
    --   "|RpcServer:register| invoke rpc (%s-%s) with param:%s, result(%s):%s",
    --   vim.inspect(registry_id),
    --   vim.inspect(name),
    --   vim.inspect(params),
    --   vim.inspect(ok),
    --   vim.inspect(err)
    -- )
    if not ok then
      log.err(
        "failed to invoke rpc (%s-%s) with param:%s, error:%s",
        vim.inspect(registry_id),
        vim.inspect(name),
        vim.inspect(params),
        vim.inspect(err)
      )
    end
  end
  return registry_id
end

--- @param registry_id string
--- @return fzfx.RpcCallback
function RpcServer:unregister(registry_id)
  log.ensure(
    type(registry_id) == "string",
    "|RpcServer:unregister| registry_id(%s) must be string! %s",
    type(registry_id),
    vim.inspect(registry_id)
  )
  local callback = self.registry[registry_id]
  log.ensure(
    type(callback) == "function",
    "|RpcServer:unregister| registered callback(%s) must be function! %s",
    type(callback),
    vim.inspect(callback)
  )
  self.registry[registry_id] = nil
  return callback
end

--- @param registry_id string
--- @return fzfx.RpcCallback
function RpcServer:get(registry_id)
  log.ensure(
    type(registry_id) == "string",
    "|RpcServer:get| registry_id(%s) must be string ! %s",
    type(registry_id),
    vim.inspect(registry_id)
  )
  local callback = self.registry[registry_id]
  log.ensure(
    type(callback) == "function",
    "|RpcServer:get| registered callback(%s) must be function! %s",
    type(callback),
    vim.inspect(callback)
  )
  return callback
end

--- @type fzfx.RpcServer?
M._RpcServerInstance = nil

--- @return fzfx.RpcServer
M.get_instance = function()
  assert(M._RpcServerInstance ~= nil)
  return M._RpcServerInstance
end

M.setup = function()
  M._RpcServerInstance = RpcServer:new()
  -- log.debug(
  --     "|fzfx.rpcserver - setup| RpcServerInstance:%s",
  --     vim.inspect(RpcServerInstance)
  -- )
end

return M
