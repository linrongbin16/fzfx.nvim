local log = require("fzfx.log")
local constants = require("fzfx.constants")
local utils = require("fzfx.utils")

--- @return string?
local function _make_windows_pipe_name()
  log.ensure(
    constants.is_windows,
    "|fzfx.server - get_windows_pipe_name| must use this function in Windows!"
  )
  local result = string.format([[\\.\pipe\nvim-pipe-%s]], utils.make_uuid())
  return result
end

--- @alias RpcRegistryId string
--- @alias RpcCallback fun(params:any):string?
--- @class RpcServer
--- @field address string
--- @field registry table<RpcRegistryId, RpcCallback>
local RpcServer = {}

--- @return RpcServer
function RpcServer:new()
  local address = constants.is_windows
      and vim.fn.serverstart(_make_windows_pipe_name())
    or vim.fn.serverstart() --[[@as string]]
  -- log.debug(
  --     "|fzfx.server - RpcServer:new| start server on socket address:%s",
  --     vim.inspect(address)
  -- )
  log.ensure(
    type(address) == "string" and string.len(address) > 0,
    "failed to start socket server!"
  )

  -- export socket address as environment variable
  vim.env._FZFX_NVIM_SOCKET_ADDRESS = address

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
  -- log.debug("|fzfx.server - RpcServer:close| self: %s!", vim.inspect(self))
  local address = self.address
  if type(self.address) == "string" and string.len(self.address) > 0 then
    local result = vim.fn.serverstop(self.address)
    -- log.debug(
    --     "|fzfx.server - RpcServer:close| stop result(valid): %s!",
    --     vim.inspect(result)
    -- )
  end
  self.address = nil
  return address
end

--- @param callback RpcCallback
--- @return RpcRegistryId
function RpcServer:register(callback)
  log.ensure(
    type(callback) == "function",
    "|fzfx.server - RpcServer:register| callback f(%s) must be function! %s",
    type(callback),
    vim.inspect(callback)
  )
  local registry_id = utils.make_unique_id()
  self.registry[registry_id] = callback
  return registry_id
end

--- @param registry_id RpcRegistryId
--- @return RpcCallback
function RpcServer:unregister(registry_id)
  log.ensure(
    type(registry_id) == "string",
    "|fzfx.server - RpcServer:unregister| registry_id(%s) must be string! %s",
    type(registry_id),
    vim.inspect(registry_id)
  )
  local callback = self.registry[registry_id]
  log.ensure(
    type(callback) == "function",
    "|fzfx.server - RpcServer:unregister| registered callback(%s) must be function! %s",
    type(callback),
    vim.inspect(callback)
  )
  self.registry[registry_id] = nil
  return callback
end

--- @param registry_id RpcRegistryId
--- @return RpcCallback
function RpcServer:get(registry_id)
  log.ensure(
    type(registry_id) == "string",
    "|fzfx.server - RpcServer:get| registry_id(%s) must be string! %s",
    type(registry_id),
    vim.inspect(registry_id)
  )
  local callback = self.registry[registry_id]
  log.ensure(
    type(callback) == "function",
    "|fzfx.server - RpcServer:get| registered callback(%s) must be function! %s",
    type(callback),
    vim.inspect(callback)
  )
  return callback
end

--- @type RpcServer?
local RpcServerInstance = nil

--- @return RpcServer
local function get_rpc_server()
  return RpcServerInstance --[[@as RpcServer]]
end

local function setup()
  RpcServerInstance = RpcServer:new()
  -- log.debug(
  --     "|fzfx.server - setup| RpcServerInstance:%s",
  --     vim.inspect(RpcServerInstance)
  -- )
  return RpcServerInstance
end

local M = {
  setup = setup,
  get_rpc_server = get_rpc_server,
  _make_windows_pipe_name = _make_windows_pipe_name,
}

return M
