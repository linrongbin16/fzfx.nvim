local consts = require("fzfx.lib.constants")
local paths = require("fzfx.lib.paths")
local nums = require("fzfx.lib.numbers")
local log = require("fzfx.log")

local M = {}

--- @alias fzfx.RpcCallback fun(params:any):string?
--- @class fzfx.RpcServer
--- @field address string
--- @field registry table<string, fzfx.RpcCallback>
local RpcServer = {}

--- @return fzfx.RpcServer
function RpcServer:new()
  local address = consts.IS_WINDOWS
      and vim.fn.serverstart(paths.make_pipe_name())
    or vim.fn.serverstart() --[[@as string]]
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
--- @return string
function RpcServer:register(callback)
  log.ensure(
    type(callback) == "function",
    "|fzfx.rpcserver - RpcServer:register| callback f(%s) must be function! %s",
    type(callback),
    vim.inspect(callback)
  )
  local registry_id = tostring(nums.inc_id())
  self.registry[registry_id] = callback
  return registry_id
end

--- @param registry_id string
--- @return fzfx.RpcCallback
function RpcServer:unregister(registry_id)
  log.ensure(
    type(registry_id) == "string",
    "|fzfx.rpcserver - RpcServer:unregister| registry_id(%s) must be string! %s",
    type(registry_id),
    vim.inspect(registry_id)
  )
  local callback = self.registry[registry_id]
  log.ensure(
    type(callback) == "function",
    "|fzfx.rpcserver - RpcServer:unregister| registered callback(%s) must be function! %s",
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
    "|fzfx.rpcserver - RpcServer:get| registry_id(%s) must be string ! %s",
    type(registry_id),
    vim.inspect(registry_id)
  )
  local callback = self.registry[registry_id]
  log.ensure(
    type(callback) == "function",
    "|fzfx.rpcserver - RpcServer:get| registered callback(%s) must be function! %s",
    type(callback),
    vim.inspect(callback)
  )
  return callback
end

--- @type fzfx.RpcServer?
M._RpcServerInstance = nil

--- @return fzfx.RpcServer
M.get_instance = function()
  return M._RpcServerInstance --[[@as fzfx.RpcServer]]
end

M.setup = function()
  M._RpcServerInstance = RpcServer:new()
  -- log.debug(
  --     "|fzfx.rpcserver - setup| RpcServerInstance:%s",
  --     vim.inspect(RpcServerInstance)
  -- )
end

return M
