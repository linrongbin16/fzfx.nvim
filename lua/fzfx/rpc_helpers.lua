-- local log = require("fzfx.log")
local rpcserver = require("fzfx.rpcserver")

--- @param registry_id integer
--- @param params any
--- @return any
local function request(registry_id, params)
  local cb = rpcserver.get_rpc_server():get(registry_id)
  -- log.debug(
  --     "|fzfx.rpc_helpers - request| global_rpc_server:%s",
  --     vim.inspect(server.get_rpc_server())
  -- )
  -- log.debug(
  --     "|fzfx.rpc_helpers - request| registry_id:%s, params:%s, registry:%s",
  --     vim.inspect(registry_id),
  --     vim.inspect(params),
  --     vim.inspect(callback)
  -- )
  return cb(params)
end

--- @param registry_id integer
--- @param params any
local function notify(registry_id, params)
  local cb = rpcserver.get_rpc_server():get(registry_id)
  -- log.debug(
  --     "|fzfx.rpc_helpers - notify| global_rpc_server:%s",
  --     vim.inspect(server.get_rpc_server())
  -- )
  -- log.debug(
  --     "|fzfx.rpc_helpers - notify| registry_id:%s, params:%s, registry:%s",
  --     vim.inspect(registry_id),
  --     vim.inspect(params),
  --     vim.inspect(callback)
  -- )
  cb(params)
end

local M = {
  request = request,
  notify = notify,
}

return M
