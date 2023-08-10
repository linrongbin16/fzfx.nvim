local log = require("fzfx.log")

-- IPC: inter-process communication

local NextRegistryId = 0

--- @alias IpcCallback fun(chanid:integer,data:string):nil

--- @class IpcRegistry
--- @field callbacks table<integer, IpcCallback>
local IpcRegistry = {
    callbacks = {},
}

function IpcRegistry:new()
    return vim.tbl_deep_extend(
        "force",
        vim.deepcopy(IpcRegistry),
        { callbacks = {} }
    )
end

--- @param f IpcCallback
--- @return integer
function IpcRegistry:register(f)
    log.ensure(
        type(f) == "function",
        "|fzfx.server - Registry:register| error! callback f(%s) must be function! %s",
        type(f),
        vim.inspect(f)
    )
    NextRegistryId = NextRegistryId + 1
    self.callbacks[NextRegistryId] = f
    return NextRegistryId
end

--- @param registry_id integer
--- @return IpcCallback|nil
function IpcRegistry:get(registry_id)
    return self.callbacks[registry_id]
end

--- @class IpcChannel
--- @field address string|nil
--- @field channel_id integer|nil
local IpcChannel = {
    address = nil,
    channel_id = nil,
}

--- @param address string
--- @param channel_id integer
function IpcChannel:new(address, channel_id)
    return vim.tbl_deep_extend("force", vim.deepcopy(IpcChannel), {
        address = address,
        channel_id = channel_id,
    })
end

--- @alias IpcHandler userdata

--- @class IpcServer
--- @field mode "tcp"|"pipe"|nil
--- @field address string|nil
--- @field port integer|nil
--- @field registry IpcRegistry|nil
--- @field server_handler IpcHandler|nil
local IpcServer = {
    mode = nil,
    address = nil,
    port = nil,
    registry = nil,
    server_handler = nil,
}

--- @param mode "tcp"|"pipe"|nil
--- @param address string|nil
--- @return IpcServer
function IpcServer:new(mode, address)
    mode = mode or "tcp"
    address = address or "127.0.0.1"

    local server_handler = vim.loop.new_tcp()
    log.ensure(
        server_handler ~= nil,
        "|fzfx.server - IpcServer:new| error! failed to create new tcp server handler on address:%s!",
        vim.inspect(address)
    )
    local bind_result = server_handler:bind(address, 0)
    log.ensure(
        bind_result == 0,
        "|fzfx.server - IpcServer:new| error! failed to bind server handler on address:%s, %s",
        vim.inspect(address),
        vim.inspect(bind_result)
    )
    local sockname = server_handler:getsockname()
    log.debug(
        "|fzfx.server - IpcServer:new| sockname:%s",
        vim.inspect(sockname)
    )

    local function on_listen(err)
        log.debug(
            "|fzfx.server - IpcServer:new.on_listen| err:%s",
            vim.inspect(err)
        )
        log.ensure(
            not err,
            "|fzfx.server - IpcServer:new.on_listen| error! failed to listen on sockname:%s, %s",
            vim.inspect(sockname),
            vim.inspect(err)
        )
        local client_handler = vim.loop.new_tcp() --[[@as uv_tcp_t]]
        if client_handler == nil then
            log.err(
                "|fzfx.server - IpcServer:new| error! failed to create new tcp client handler on sockname:%s!",
                vim.inspect(sockname)
            )
            return
        end
        local accept_result =
            server_handler:accept(client_handler --[[@as uv_stream_t]])
        if accept_result ~= 0 then
            log.err(
                "|fzfx.server - IpcServer:new.on_listen| error! failed to accept client handler on sockname:%s, %s",
                vim.inspect(sockname),
                vim.inspect(err)
            )
            client_handler:close()
            return
        end
        local function on_read_start(read_err, read_data)
            log.debug(
                "|fzfx.server - IpcServer:new.on_listen.on_read_start| read_err:%s, read_data:%s",
                vim.inspect(read_err),
                vim.inspect(read_data)
            )
            if read_err then
                log.err(
                    "|fzfx.server - IpcServer:new.on_listen.on_read_start| error! read error:%s, data:%s",
                    vim.inspect(read_err),
                    vim.inspect(read_data)
                )
                client_handler:shutdown()
                client_handler:close()
                return
            end
        end
        local read_start_result = client_handler:read_start(on_read_start)
        if read_start_result ~= 0 then
            log.err(
                "|fzfx.server - IpcServer:new.on_listen| error! failed to read start on client handler on sockname:%s, %s",
                vim.inspect(sockname),
                vim.inspect(read_start_result)
            )
            client_handler:close()
            return
        end
    end
    local listen_result = server_handler:listen(128, on_listen)
    log.ensure(
        listen_result == 0,
        "|fzfx.server - IpcServer:new| error! failed to listen on sockname:%s, %s",
        vim.inspect(sockname),
        vim.inspect(listen_result)
    )

    --- @type integer
    local channel_id = vim.fn.sockconnect(mode, address, {
        on_data = function(chanid, data, name)
            self:accept(chanid, data, name)
        end,
        data_buffered = true,
    })
    log.debug(
        "|fzfx.server - IpcServer:new| listen on channel id:%s",
        vim.inspect(channel_id)
    )
    log.ensure(
        type(channel_id) == "number" and channel_id > 0,
        "error! failed to connect to tcp server on %s!",
        address
    )
    --- @type IpcChannel
    local listen_channel = IpcChannel:new(address --[[@as string]], channel_id)
    --- @type IpcRegistry
    local registry = IpcRegistry:new()

    return vim.tbl_deep_extend("force", vim.deepcopy(IpcServer), {
        mode = mode,
        address = address,
        registry = registry,
        listen_channel = listen_channel,
    })
end

--- @param chanid integer
--- @param data string
--- @param name string
function IpcServer:accept(chanid, data, name)
    log.debug(
        "|fzfx.server - accept| chanid:%s, data:%s, name:%s",
        vim.inspect(chanid),
        vim.inspect(data),
        vim.inspect(name)
    )
    local registry_id = data[1]
    local input_data = data[2]
    local callback = self.registry:get(registry_id) --[[@as IpcCallback]]
    log.debug("|fzfx.server - accept| callback:%s", vim.inspect(callback))
    log.ensure(
        type(callback) == "function",
        "|fzfx.server - accept| error! cannot find registered rpc callback function with id:%s",
        vim.inspect(registry_id)
    )
    callback(chanid, input_data)
end

--- @param f IpcCallback
--- @return integer
function IpcServer:register(f)
    self.registry:register(f)
end

local M = {
    IpcServer = IpcServer,
    IpcChannel = IpcChannel,
}

return M
