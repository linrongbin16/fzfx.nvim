local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format("|fzfx.bin.buffers.provider| error! SELF_PATH is empty!")
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_SOCKET_ADDRESS
shell_helpers.log_ensure(
    type(SOCKET_ADDRESS) == "string" and string.len(SOCKET_ADDRESS) > 0,
    "|fzfx.bin.rpc.client| error! SOCKET_ADDRESS must not be empty!"
)
local registry_id = _G.arg[1]

shell_helpers.log_debug("registry_id:[%s]", registry_id)

local channel_id = vim.fn.sockconnect("pipe", SOCKET_ADDRESS, { rpc = true })
shell_helpers.log_debug("channel_id:%s", vim.inspect(channel_id))
shell_helpers.log_ensure(
    channel_id > 0,
    "|fzfx.bin.buffers.provider| error! failed to connect socket on SOCKET_ADDRESS:%s",
    vim.inspect(SOCKET_ADDRESS)
)
local buffers = vim.rpcrequest(
    channel_id,
    "nvim_exec_lua",
    ---@diagnostic disable-next-line: param-type-mismatch
    [[
    local luaargs = {...}
    local registry_id = luaargs[1]
    return require("fzfx.rpc_helpers").call(registry_id)
    ]],
    {
        registry_id,
    }
)
vim.fn.chanclose(channel_id)
shell_helpers.log_debug(
    "|fzfx.bin.buffers.provider| buffers(%s):%s",
    type(buffers),
    vim.inspect(buffers)
)

if type(buffers) == "table" and #buffers > 0 then
    for _, line in ipairs(buffers) do
        -- shell_helpers.log_debug("line:%s", vim.inspect(line))
        local line_with_icon = shell_helpers.render_line_with_icon(line)
        io.write(string.format("%s\n", line_with_icon))
    end
end
