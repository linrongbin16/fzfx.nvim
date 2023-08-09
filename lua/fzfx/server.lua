local log = require("fzfx.log")

local NextRegistryId = 0

--- @type table<integer, function>
local Registry = {}

-- IPC: inter-process communication
--- @alias IpcCallback fun(chanid:integer,data:string):nil

--- @param f IpcCallback
--- @return integer
local function register(f)
    NextRegistryId = NextRegistryId + 1
    Registry[NextRegistryId] = f
    return NextRegistryId
end

--- @param chanid integer
--- @param data string
--- @param name string
local function accept(chanid, data, name)
    log.debug(
        "|fzfx.server - accept| chanid:%s, data:%s, name:%s",
        vim.inspect(chanid),
        vim.inspect(data),
        vim.inspect(name)
    )
    local registry_id = data[1]
    local input_data = data[2]
    --- @type IpcCallback
    local rpc_callback = Registry[registry_id]
    log.debug(
        "|fzfx.server - accept| rpc_callback:%s",
        vim.inspect(rpc_callback)
    )
    log.ensure(
        type(rpc_callback) == "function",
        "|fzfx.server - accept| error! cannot find registered rpc callback function with id:%s",
        vim.inspect(registry_id)
    )
    rpc_callback(chanid, input_data)
end

--- @class IpcChannel
--- @field sockaddr string|nil
--- @field chanid integer|nil
local IpcChannel = {
    sockaddr = nil,
    chanid = nil,
}

--- @param sockaddr string
--- @param chanid integer
function IpcChannel:new(sockaddr, chanid)
    return vim.tbl_deep_extend("force", vim.deepcopy(IpcChannel), {
        sockaddr = sockaddr,
        chanid = chanid,
    })
end

--- @return IpcChannel
local function startserver()
    local sockaddr = vim.fn.serverstart("127.0.0.1:0")
    log.debug("|fzfx.server - startserver| sockaddr:%s", vim.inspect(sockaddr))
    log.ensure(
        type(sockaddr) == "string" and string.len(sockaddr) > 0,
        "error! failed to start tcp server on 127.0.0.1:0!"
    )
    local chanid = vim.fn.sockconnect(
        "tcp",
        sockaddr,
        { on_data = accept, data_buffered = true }
    )
    log.debug(
        "|fzfx.server - startserver| listen on chanid:%s",
        vim.inspect(chanid)
    )
    log.ensure(
        type(chanid) == "number" and chanid > 0,
        "error! failed to connect to tcp server on 127.0.0.1:0!"
    )
    return IpcChannel:new(sockaddr --[[@as string]], chanid)
end

local function setup() end

local M = {
    setup = setup,
    startserver = startserver,
    register = register,
}

return M
