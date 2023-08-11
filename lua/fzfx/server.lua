local log = require("fzfx.log")

--- @type integer
local NextRegistryIntegerId = 0

--- @return string
local function next_registry_id()
    NextRegistryIntegerId = NextRegistryIntegerId + 1
    return tostring(NextRegistryIntegerId)
end

--- @alias RpcCallback fun(channel_id:integer,user_context:any,data:string):string|nil

--- @class RpcRegistry
--- @field callbacks table<integer, RpcCallback>
local RpcRegistry = {
    callbacks = {},
}

function RpcRegistry:new()
    return vim.tbl_deep_extend(
        "force",
        vim.deepcopy(RpcRegistry),
        { callbacks = {} }
    )
end

--- @param f RpcCallback
--- @return string
function RpcRegistry:register(f)
    log.ensure(
        type(f) == "function",
        "|fzfx.server - RpcRegistry:register| error! callback f(%s) must be function! %s",
        type(f),
        vim.inspect(f)
    )
    local registry_id = next_registry_id()
    self.callbacks[registry_id] = f
    return registry_id
end

--- @param registry_id string
--- @return RpcCallback
function RpcRegistry:unregister(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.server - RpcRegistry:unregister| error! registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local f = self.callbacks[registry_id]
    log.ensure(
        type(f) == "function",
        "|fzfx.server - RpcRegistry:unregister| error! registered callback(%s) must be function! %s",
        type(f),
        vim.inspect(f)
    )
    self.callbacks[registry_id] = nil
    return f
end

--- @param registry_id string
--- @return RpcCallback
function RpcRegistry:get(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.server - RpcRegistry:get| error! registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local f = self.callbacks[registry_id]
    log.ensure(
        type(f) == "function",
        "|fzfx.server - RpcRegistry:get| error! registered callback(%s) must be function! %s",
        type(f),
        vim.inspect(f)
    )
    return f
end

--- @class RpcServer
--- @field mode "tcp"|"pipe"|nil
--- @field address string|nil
--- @field registry RpcRegistry|nil
local RpcServer = {
    mode = nil,
    address = nil,
    registry = nil,
}

--- @param mode "tcp"|"pipe"|nil
--- @param expect_address string|nil
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

    --- @type RpcRegistry
    local registry = RpcRegistry:new()

    return vim.tbl_deep_extend("force", vim.deepcopy(RpcServer), {
        mode = mode,
        address = address,
        registry = registry,
    })
end

--- @return string|nil
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

--- @param f RpcCallback
--- @return string
function RpcServer:register(f)
    return self.registry:register(f)
end

--- @param registry_id string
--- @return RpcCallback
function RpcServer:unregister(registry_id)
    return self.registry:unregister(registry_id)
end

--- @type RpcServer|nil
local GlobalRpcServer = nil

--- @param mode "tcp"|"pipe"|nil
--- @param address string|nil
local function setup(mode, address)
    GlobalRpcServer = RpcServer:new(mode, address)
    return GlobalRpcServer
end

local M = {
    setup = setup,
    GlobalRpcServer = GlobalRpcServer,
}

return M
