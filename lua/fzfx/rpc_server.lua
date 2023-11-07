local log = require("fzfx.log")
local constants = require("fzfx.constants")

--- @type integer
local NextRegistryIntegerId = 0

--- @alias RpcRegistryId string
--- @return RpcRegistryId
local function _next_registry_id()
    if NextRegistryIntegerId >= constants.int32_max then
        NextRegistryIntegerId = 1
    else
        NextRegistryIntegerId = NextRegistryIntegerId + 1
    end
    local secs, ms = vim.loop.gettimeofday()
    return string.format("%d-%d-%d", NextRegistryIntegerId, secs, ms)
end

--- @return string
local function make_pipe_name()
    if constants.is_windows then
        local secs, ms = vim.loop.gettimeofday()
        local result = string.format(
            [[\\.\pipe\nvim-pipe-%d-%d-%d]],
            vim.fn.getpid(),
            secs,
            ms
        )
        log.debug(
            "|fzfx.rpc_server - make_pipe_name| result:%s",
            vim.inspect(result)
        )
        return result
    else
        return vim.fn.tempname()
    end
end

--- @alias RpcCallback fun(params:any):string?
--- @type table<RpcRegistryId, RpcCallback>
local RpcRegistries = {}

--- @param cb RpcCallback
--- @return RpcRegistryId
local function register(cb)
    log.ensure(
        type(cb) == "function",
        "|fzfx.rpc_server - register| callback f(%s) must be function! %s",
        type(cb),
        vim.inspect(cb)
    )
    local registry_id = _next_registry_id()
    RpcRegistries[registry_id] = cb
    return registry_id
end

--- @param registry_id RpcRegistryId
--- @return RpcCallback
local function unregister(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.rpc_server - unregister| registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local cb = RpcRegistries[registry_id]
    log.ensure(
        type(cb) == "function",
        "|fzfx.rpc_server - unregister| registered callback(%s) must be function! %s",
        type(cb),
        vim.inspect(cb)
    )
    RpcRegistries[registry_id] = nil
    return cb
end

--- @param registry_id RpcRegistryId
--- @return RpcCallback
local function get(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.rpc_server - get| registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local cb = RpcRegistries[registry_id]
    log.ensure(
        type(cb) == "function",
        "|fzfx.server - get| registered callback(%s) must be function! %s",
        type(cb),
        vim.inspect(cb)
    )
    return cb
end

local function setup()
    local address = make_pipe_name()
    log.debug("|fzfx.rpc_server - setup| make address:%s", vim.inspect(address))

    local server_handle, new_server_err = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    log.ensure(
        server_handle ~= nil,
        "|fzfx.rpc_server - setup| failed to create new server pipe: %s",
        vim.inspect(new_server_err)
    )
    local bind_result, bind_err = server_handle:bind(address)
    log.ensure(
        bind_result ~= nil,
        "|fzfx.rpc_server - setup| failed to bind pipe server on address: %s! error: %s",
        vim.inspect(address),
        vim.inspect(bind_err)
    )
    local listen_result, listen_err = server_handle:listen(
        128,
        function(listen_complete_err)
            if listen_complete_err then
                log.throw(
                    "|fzfx.rpc_server - setup| failed to complete listen on pipe server: %s! error: %s",
                    vim.inspect(address),
                    vim.inspect(listen_complete_err)
                )
                return
            end
        end
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

local M = {
    _next_registry_id = _next_registry_id,
    make_pipe_name = make_pipe_name,
    setup = setup,
    register = register,
    unregister = unregister,
    get = get,
}

return M
