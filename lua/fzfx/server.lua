local log = require("fzfx.log")

local NextRegistryId = 0

--- @type table<integer, function>
local Registry = {}

--- @param f fun(data:string):nil
local function register(f)
    NextRegistryId = NextRegistryId + 1
    Registry[NextRegistryId] = f
end

local function accept(chanid, data, name)
    log.debug(
        "|fzfx.server - accept| chanid:%s, data:%s, name:%s",
        vim.inspect(chanid),
        vim.inspect(data),
        vim.inspect(name)
    )
    local registry_id = data[1]
    local input_data = data[2]
    local callback = Registry[registry_id]
    log.debug("|fzfx.server - accept| callback:%s", vim.inspect(callback))
    assert(
        type(callback) == "function",
        "|fzfx.server - accept| error! cannot find registered callback function with id:%s",
        vim.inspect(registry_id)
    )
    callback(input_data)
end

local function startserver()
    local sockaddr = vim.fn.serverstart("127.0.0.1:0")
    vim.env._FZFX_NVIM_SOCKET_ADDRESS = sockaddr
    log.debug("|fzfx.server - startserver| sockaddr:%s", vim.inspect(sockaddr))
    local result = vim.fn.sockconnect("tcp", sockaddr, { on_data = accept })
    log.debug(
        "|fzfx.server - startserver| listen result:%s",
        vim.inspect(result)
    )
end

local function setup()
    startserver()
end

local M = {
    setup = setup,
    register = register,
}

return M
