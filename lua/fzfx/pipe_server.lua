local constants = require("fzfx.constants")
local json = require("fzfx.json")
local log = require("fzfx.log")

--- @return string
local function _make_uuid()
    local secs, ms = vim.loop.gettimeofday()
    return string.format(
        "%d-%d-%d-%d",
        vim.loop.os_getpid(),
        secs,
        ms,
        math.random(1, constants.int32_max)
    )
end

--- @type integer
local NextPipeRegistryId = 0

--- @alias PipeRpcRegistryId string
--- @return PipeRpcRegistryId
local function _next_registry_id()
    if NextPipeRegistryId >= constants.int32_max then
        NextPipeRegistryId = 1
    else
        NextPipeRegistryId = NextPipeRegistryId + 1
    end
    return string.format("pipe%d", NextPipeRegistryId)
end

--- @return string
local function make_pipe_name()
    if constants.is_windows then
        return string.format([[\\.\pipe\nvim-pipe-%s]], _make_uuid())
    else
        return vim.fn.tempname()
    end
end

--- @alias PipeRpcCallback fun(params:any):string?
--- @type table<PipeRpcRegistryId, PipeRpcCallback>
local PipeRpcRegistries = {}

--- @param cb PipeRpcCallback
--- @return PipeRpcRegistryId
local function register(cb)
    log.ensure(
        type(cb) == "function",
        "|fzfx.pipe_server - register| callback f(%s) must be function! %s",
        type(cb),
        vim.inspect(cb)
    )
    local registry_id = _next_registry_id()
    PipeRpcRegistries[registry_id] = cb
    return registry_id
end

--- @param registry_id PipeRpcRegistryId
--- @return PipeRpcCallback
local function unregister(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.pipe_server - unregister| registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local cb = PipeRpcRegistries[registry_id]
    log.ensure(
        type(cb) == "function",
        "|fzfx.pipe_server - unregister| registered callback(%s) must be function! %s",
        type(cb),
        vim.inspect(cb)
    )
    PipeRpcRegistries[registry_id] = nil
    return cb
end

--- @param registry_id PipeRpcRegistryId
--- @return PipeRpcCallback
local function get(registry_id)
    log.ensure(
        type(registry_id) == "string",
        "|fzfx.pipe_server - get| registry_id(%s) must be string! %s",
        type(registry_id),
        vim.inspect(registry_id)
    )
    local cb = PipeRpcRegistries[registry_id]
    log.ensure(
        type(cb) == "function",
        "|fzfx.server - get| registered callback(%s) must be function! %s",
        type(cb),
        vim.inspect(cb)
    )
    return cb
end

--- @param handle uv_pipe_t?
local function _close_client_handle(handle)
    if handle and not handle:is_closing() then
        handle:shutdown()
        handle:close()
    end
end

local function setup()
    local address = make_pipe_name()
    log.debug(
        "|fzfx.pipe_server - setup| make address:%s",
        vim.inspect(address)
    )

    local server_handle, new_server_err = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    log.ensure(
        server_handle ~= nil,
        "|fzfx.pipe_server - setup| failed to create new server pipe: %s",
        vim.inspect(new_server_err)
    )
    local bind_result, bind_err = server_handle:bind(address)
    log.ensure(
        bind_result ~= nil,
        "|fzfx.pipe_server - setup| failed to bind pipe server on address: %s! error: %s",
        vim.inspect(address),
        vim.inspect(bind_err)
    )
    local listen_result, listen_err = server_handle:listen(
        128,
        function(listen_complete_err)
            if listen_complete_err then
                log.throw(
                    "|fzfx.pipe_server - setup| failed to complete listen on pipe server: %s! error: %s",
                    vim.inspect(address),
                    vim.inspect(listen_complete_err)
                )
                return
            end

            local client_handle, new_client_err = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
            if client_handle == nil then
                log.err(
                    "|fzfx.pipe_server - setup| failed to create new client pipe: %s",
                    vim.inspect(new_client_err)
                )
                return
            end

            local accept_result, accept_err =
                server_handle:accept(client_handle)
            if accept_result == nil then
                log.err(
                    "|fzfx.pipe_server - setup| failed to accept new client pipe: %s",
                    vim.inspect(accept_err)
                )
                _close_client_handle(client_handle)
                return
            end

            local buffer = nil

            local read_start_result, read_start_err = client_handle:read_start(
                function(read_err, read_data)
                    log.debug(
                        "|fzfx.pipe_server - setup| client pipe read: %s, err: %s",
                        vim.inspect(read_data),
                        vim.inspect(read_err)
                    )
                    if read_err then
                        log.err(
                            "|fzfx.pipe_server - setup| failed to read on client pipe:%s, data:%s",
                            vim.inspect(read_err),
                            vim.inspect(read_data)
                        )
                        client_handle:read_stop()
                        _close_client_handle(client_handle)
                        return
                    end

                    if read_data then
                        buffer = buffer and (buffer .. read_data) or read_data
                        buffer = buffer:gsub("\r\n", "\n")
                    else
                        --- @alias RpcParams {["id"]:string,params:string?}
                        --- @type RpcParams
                        local obj = json.decode(buffer) --[[@as table]]
                        local registry_id = obj["id"]
                        local params = obj["params"]
                        local cb = get(registry_id)
                        log.ensure(
                            type(cb) == "function",
                            "|fzfx.pipe_server - setup| registered callbacks(%s) must be a function: %s",
                            vim.inspect(registry_id),
                            vim.inspect(cb)
                        )
                        cb(params) --[[@as string?]]
                        client_handle:read_stop()
                        _close_client_handle(client_handle)
                    end
                end
            )
            if read_start_result == nil then
                log.err(
                    "|fzfx.pipe_server - setup| failed to start read new client pipe: %s",
                    vim.inspect(read_start_err)
                )
                _close_client_handle(client_handle)
            end
        end
    )
    log.ensure(
        listen_result ~= nil,
        "|fzfx.pipe_server - setup| failed to listen pipe server on address: %s! error: %s",
        vim.inspect(address),
        vim.inspect(listen_err)
    )

    -- export socket address as environment variable
    vim.env._FZFX_NVIM_PIPE_ADDRESS = address
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
