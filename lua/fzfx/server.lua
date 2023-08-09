local log = require("fzfx.log")
local constants = require("fzfx.constants")

local Context = {
    --- @type string|nil
    socket_address = nil,
}

local function startserver()
    local addr = vim.fn.serverstart("127.0.0.1:0")
    vim.env._FZFX_NVIM_SOCKET_ADDRESS = addr
    log.debug("|fzfx.server - startserver| addr:%s", vim.inspect(addr))
end

local function setup() end

local M = {
    setup = setup,
}

return M
