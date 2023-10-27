local log = require("fzfx.log")
local constants = require("fzfx.constants")

--- @type integer
local NextRegistryIntegerId = 0

--- @alias RpcRegistryId string

--- @return RpcRegistryId
local function next_registry_id()
    -- int32 max: 2147483647
    if NextRegistryIntegerId >= 2147483647 then
        NextRegistryIntegerId = 1
    else
        NextRegistryIntegerId = NextRegistryIntegerId + 1
    end
    return tostring(NextRegistryIntegerId)
end

--- @alias RpcCallback fun(params:any):string?

--- @return string?
local function get_windows_pipe_name()
    log.ensure(
        constants.is_windows,
        "|fzfx.server - get_windows_pipe_name| error! must use this function in Windows!"
    )
    local result = vim.trim(
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
end

--- @class RpcServer
--- @field address string
--- @field registry table<RpcRegistryId, RpcCallback>
local RpcServer = {}

--- @return RpcServer
function RpcServer:new()
    --- @type string
    local address = constants.is_windows
            and vim.fn.serverstart(get_windows_pipe_name())
        or vim.fn.serverstart() --[[@as string]]
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
--- @return RpcRegistryId
function RpcServer:register(callback)
    log.ensure(
        type(callback) == "function",
        "|fzfx.server - RpcServer:register| error! callback f(%s) must be function! %s",
        type(callback),
        vim.inspect(callback)
    )
    local registry_id = next_registry_id()
    self.registry[registry_id] = callback
    return registry_id
end

--- @param registry_id RpcRegistryId
--- @return RpcCallback
function RpcServer:unregister(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.server - RpcServer:unregister| error! registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local callback = self.registry[registry_id]
    log.ensure(
        type(callback) == "function",
        "|fzfx.server - RpcServer:unregister| error! saved callback(%s) must be function! %s",
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
        "|fzfx.server - RpcServer:get| error! registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local callback = self.registry[registry_id]
    log.ensure(
        type(callback) == "function",
        "|fzfx.server - RpcServer:get| error! saved callback(%s) must be function! %s",
        type(callback),
        vim.inspect(callback)
    )
    return callback
end

--- @type RpcServer?
local GlobalRpcServer = nil

--- @return RpcServer
local function get_global_rpc_server()
    return GlobalRpcServer --[[@as RpcServer]]
end

local function setup()
    GlobalRpcServer = RpcServer:new()
    log.debug(
        "|fzfx.server - setup| GlobalRpcServer:%s",
        vim.inspect(GlobalRpcServer)
    )
    return GlobalRpcServer
end

local M = {
    setup = setup,
    get_global_rpc_server = get_global_rpc_server,
    next_registry_id = next_registry_id,
    get_windows_pipe_name = get_windows_pipe_name,
}

return M
