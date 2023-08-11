local log = require("fzfx.log")
local server = require("fzfx.server")

--- @param registry_id RpcRegistryId
--- @return any
local function call(registry_id)
    local registry = server.get_global_rpc_server():get(registry_id)
    log.ensure(
        type(registry) == "table",
        "|fzfx.rpc_helpers - call| error! failed to found registry on registry_id:%s, global_rpc_server:%s",
        vim.inspect(registry_id),
        vim.inspect(server.get_global_rpc_server())
    )
    log.ensure(
        type(registry["callback"]) == "function",
        "|fzfx.rpc_helpers - call| error! registry.callback(%s) must be function:%s, global_rpc_server:%s",
        type(registry["callback"]),
        vim.inspect(registry),
        vim.inspect(server.get_global_rpc_server())
    )
    return registry.callback(registry.user_context)
end

local M = {
    call = call,
}

return M
