local log = require("fzfx.log")

--- @type integer
local NextRegistryIntegerId = 0

--- @alias RpcRegistryId string

--- @return RpcRegistryId
local function next_registry_id()
    NextRegistryIntegerId = NextRegistryIntegerId + 1
    return tostring(NextRegistryIntegerId)
end

--- @alias RpcCallback fun(user_context:any):string?

--- @class RpcRegistry
--- @field callback RpcCallback?
--- @field user_context any?
local RpcRegistry = {
    callback = nil,
    user_context = nil,
}

--- @param callback RpcCallback?
--- @param user_context any?
--- @return RpcRegistry
function RpcRegistry:new(callback, user_context)
    return vim.tbl_deep_extend(
        "force",
        vim.deepcopy(RpcRegistry),
        { callback = callback, user_context = user_context }
    )
end

--- @class RpcServer
--- @field mode "tcp"|"pipe"|nil
--- @field address string?
--- @field callback_registries table<RpcRegistryId, RpcRegistry>
local RpcServer = {
    mode = nil,
    address = nil,
    callback_registries = {},
}

--- @param mode "tcp"|"pipe"|nil
--- @param expect_address string?
--- @return RpcServer
function RpcServer:new(mode, expect_address)
    mode = mode or "tcp"
    expect_address = expect_address or "127.0.0.1:0"

    --- @type string
    local address = vim.fn.serverstart(expect_address) --[[@as string ]]
    log.debug(
        "|fzfx.server - RpcServer:new| start server on socket address:%s",
        vim.inspect(address)
    )
    log.ensure(
        type(address) == "string" and string.len(address) > 0,
        "error! failed to start socket server on address: %s!",
        expect_address
    )

    -- export socket address as environment variable
    vim.env._FZFX_NVIM_SOCKET_ADDRESS = address

    return vim.tbl_deep_extend("force", vim.deepcopy(RpcServer), {
        mode = mode,
        address = address,
        callback_registries = {},
    })
end

--- @return string?
function RpcServer:close()
    log.debug("|fzfx.server - RpcServer:close| self: %s!", vim.inspect(self))
    local address = self.address
    if type(self.address) == "string" and string.len(self.address) > 0 then
        local result = vim.fn.serverstop(self.address)
        log.debug(
            "|fzfx.server - RpcServer:close| stop result(valid): %s!",
            vim.inspect(result)
        )
    end
    self.address = nil
    return address
end

--- @param callback RpcCallback
--- @param user_context any?
--- @return RpcRegistryId
function RpcServer:register(callback, user_context)
    log.ensure(
        type(callback) == "function",
        "|fzfx.server - RpcServer:register| error! callback f(%s) must be function! %s",
        type(callback),
        vim.inspect(callback)
    )
    local registry_id = next_registry_id()
    local registry = RpcRegistry:new(user_context, callback)
    self.callback_registries[registry_id] = registry
    return registry_id
end

--- @param registry_id RpcRegistryId
--- @return RpcRegistry
function RpcServer:unregister(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.server - RpcServer:unregister| error! registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local r = self.callback_registries[registry_id]
    log.ensure(
        type(r) == "table",
        "|fzfx.server - RpcServer:unregister| error! saved registry(%s) must be table! %s",
        type(r),
        vim.inspect(r)
    )
    self.callback_registries[registry_id] = nil
    return r
end

--- @param registry_id RpcRegistryId
--- @return RpcRegistry
function RpcServer:get(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.server - RpcServer:get| error! registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local r = self.callback_registries[registry_id]
    log.ensure(
        type(r) == "table",
        "|fzfx.server - RpcServer:unregister| error! saved registry(%s) must be table! %s",
        type(r),
        vim.inspect(r)
    )
    return r
end

--- @type RpcServer?
local GlobalRpcServer = nil

--- @param mode "tcp"|"pipe"|nil
--- @param address string?
local function setup(mode, address)
    GlobalRpcServer = RpcServer:new(mode, address)
    log.debug(
        "|fzfx.server - setup| GlobalRpcServer:%s",
        vim.inspect(GlobalRpcServer)
    )
    return GlobalRpcServer
end

--- @return RpcServer
local function get_global_rpc_server()
    return GlobalRpcServer --[[@as RpcServer]]
end

local M = {
    setup = setup,
    get_global_rpc_server = get_global_rpc_server,
}

return M
