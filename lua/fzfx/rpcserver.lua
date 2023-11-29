local consts = require("fzfx.lib.constants")
local paths = require("fzfx.lib.paths")
local nums = require("fzfx.lib.numbers")
local log = require("fzfx.log")

--- @alias fzfx.RpcCallback fun(params:any):string?
--- @class fzfx.RpcServer
--- @field address string
--- @field registry table<integer, fzfx.RpcCallback>
local RpcServer = {}

--- @return fzfx.RpcServer
function RpcServer:new()
  local address = consts.IS_WINDOWS
      and vim.fn.serverstart(paths.make_pipe_name())
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
  -- log.debug("|fzfx.server - RpcServer:close| self: %s!", vim.inspect(self))
  local address = self.address
  if type(self.address) == "string" and string.len(self.address) > 0 then
    ---@diagnostic disable-next-line: unused-local
    local result = vim.fn.serverstop(self.address)
    -- log.debug(
    --     "|fzfx.server - RpcServer:close| stop result(valid): %s!",
    --     vim.inspect(result)
    -- )
  end
  self.address = nil
  return address
end

--- @param callback fzfx.RpcCallback
--- @return integer
function RpcServer:register(callback)
  log.ensure(
    type(callback) == "function",
    "|fzfx.server - RpcServer:register| callback f(%s) must be function! %s",
    type(callback),
    vim.inspect(callback)
  )
  local registry_id = nums.inc_id()
  self.registry[registry_id] = callback
  return registry_id
end

--- @param registry_id integer
--- @return fzfx.RpcCallback
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

--- @param registry_id integer
--- @return fzfx.RpcCallback
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

--- @type fzfx.RpcServer?
local RpcServerInstance = nil

--- @return fzfx.RpcServer
local function get_rpc_server()
  return RpcServerInstance --[[@as fzfx.RpcServer]]
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
}

return M
