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

--- @class IpcServer
--- @field mode "tcp"|"pipe"|nil
--- @field address string|nil
--- @field registry IpcRegistry|nil
--- @field listen_channel IpcChannel|nil
local IpcServer = {
    mode = nil,
    address = nil,
    registry = nil,
    listen_channel = nil,
}

--- @param mode "tcp"|"pipe"|nil
--- @param addr string|nil
--- @return IpcServer
function IpcServer:new(mode, addr)
    mode = mode or "tcp"
    addr = addr or "127.0.0.1:0"
    local address = vim.fn.serverstart(addr)
    log.debug("|fzfx.server - IpcServer:new| address:%s", vim.inspect(address))
    log.ensure(
        type(address) == "string" and string.len(address) > 0,
        "error! failed to start tcp server on %s!",
        addr
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

local M = {
    IpcServer = IpcServer,
    IpcChannel = IpcChannel,
}

return M
