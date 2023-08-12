local log = require("fzfx.log")
local constants = require("fzfx.constants")

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

--- @return string|nil
local function get_pipe_name()
    if constants.is_windows then
        local result = vim.fn.trim(
            string.format(
                [[ \\.\pipe\nvim-pipe-%d-%d ]],
                vim.fn.getpid(),
                os.time()
            )
        )
        log.debug(
            "|fzfx.server - make_windows_pipe_name| result:%s",
            vim.inspect(result)
        )
        return result
    else
        return nil
    end
end

--- @class RpcServer
--- @field address string?
--- @field callback_registries table<RpcRegistryId, RpcRegistry>
local RpcServer = {
    address = nil,
    callback_registries = {},
}

--- @return RpcServer
function RpcServer:new()
    --- @type string
    local address = vim.fn.serverstart(get_pipe_name()) --[[@as string]]
    log.debug(
        "|fzfx.server - RpcServer:new| start server on socket address:%s",
        vim.inspect(address)
    )
    log.ensure(
        type(address) == "string" and string.len(address) > 0,
        "error! failed to start socket server!"
    )

    -- export socket address as environment variable
    vim.env._FZFX_NVIM_SOCKET_ADDRESS = address

    return vim.tbl_deep_extend("force", vim.deepcopy(RpcServer), {
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
    local registry = RpcRegistry:new(callback, user_context)
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

local function setup()
    GlobalRpcServer = RpcServer:new()
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
