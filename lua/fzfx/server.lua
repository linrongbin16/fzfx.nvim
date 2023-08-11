local log = require("fzfx.log")

--- @type integer
local NextRegistryIntegerId = 0

--- @alias RpcRegistryId string

--- @return RpcRegistryId
local function next_registry_id()
    NextRegistryIntegerId = NextRegistryIntegerId + 1
    return tostring(NextRegistryIntegerId)
end

--- @alias RpcCallback fun(user_context:any,data:string):string?

--- @class RpcRegistry
--- @field user_context any?
--- @field callback RpcCallback?
local RpcRegistry = {
    user_context = nil,
    callback = nil,
}

--- @param user_context any?
--- @param callback RpcCallback?
--- @return RpcRegistry
function RpcRegistry:new(user_context, callback)
    return vim.tbl_deep_extend(
        "force",
        vim.deepcopy(RpcRegistry),
        { user_context = user_context, callback = callback }
    )
end

--- @class RpcRegistryManager
--- @field registries table<RpcRegistryId, RpcRegistry>
local RpcRegistryManager = {
    registries = {},
}

function RpcRegistryManager:new()
    return vim.tbl_deep_extend(
        "force",
        vim.deepcopy(RpcRegistryManager),
        { callbacks = {} }
    )
end

--- @param ctx any
--- @param f RpcCallback
--- @return RpcRegistryId
function RpcRegistryManager:register(ctx, f)
    log.ensure(
        type(f) == "function",
        "|fzfx.server - RpcRegistryManager:register| error! callback f(%s) must be function! %s",
        type(f),
        vim.inspect(f)
    )
    local registry_id = next_registry_id()
    local registry = RpcRegistry:new(ctx, f)
    self.registries[registry_id] = registry
    return registry_id
end

--- @param registry_id RpcRegistryId
--- @return RpcRegistry
function RpcRegistryManager:unregister(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.server - RpcRegistryManager:unregister| error! registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local r = self.registries[registry_id]
    log.ensure(
        type(r) == "table",
        "|fzfx.server - RpcRegistryManager:unregister| error! saved registry(%s) must be table! %s",
        type(r),
        vim.inspect(r)
    )
    self.registries[registry_id] = nil
    return r
end

--- @param registry_id RpcRegistryId
--- @return RpcRegistry
function RpcRegistryManager:get(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.server - RpcRegistryManager:get| error! registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local r = self.registries[registry_id]
    log.ensure(
        type(r) == "table",
        "|fzfx.server - RpcRegistryManager:unregister| error! saved registry(%s) must be table! %s",
        type(r),
        vim.inspect(r)
    )
    return r
end

--- @class RpcServer
--- @field mode "tcp"|"pipe"|nil
--- @field address string?
--- @field registry_manager RpcRegistryManager?
local RpcServer = {
    mode = nil,
    address = nil,
    registry_manager = nil,
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

    --- @type RpcRegistryManager
    local registry_manager = RpcRegistryManager:new()

    return vim.tbl_deep_extend("force", vim.deepcopy(RpcServer), {
        mode = mode,
        address = address,
        registry_manager = registry_manager,
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

--- @param user_context any
--- @param callback RpcCallback
--- @return RpcRegistryId
function RpcServer:register(user_context, callback)
    return self.registry_manager:register(user_context, callback)
end

--- @param registry_id RpcRegistryId
--- @return RpcRegistry
function RpcServer:unregister(registry_id)
    return self.registry_manager:unregister(registry_id)
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
