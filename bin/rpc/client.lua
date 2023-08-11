local debug_enable = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"

local args = _G.arg
local sockaddr = args[1]
local function_id = args[2]

if debug_enable then
    io.write(string.format("DEBUG sockaddr:%s\n", vim.inspect(sockaddr)))
    io.write(string.format("DEBUG function_id:%s\n", vim.inspect(function_id)))
end

--- @param chanid integer
--- @param data string
--- @param name string
--- @return nil
local function accept(chanid, data, name)
    if debug_enable then
        io.write(string.format("DEBUG accept.chanid:%s\n", vim.inspect(chanid)))
        io.write(string.format("DEBUG accept.data:%s\n", vim.inspect(data)))
        io.write(string.format("DEBUG accept.name:%s\n", vim.inspect(name)))
    end
end

local socket_channel_id = vim.fn.sockconnect(
    "tcp",
    sockaddr,
    { on_data = accept, data_buffered = true }
)

if socket_channel_id > 0 then
    local bytes = vim.fn.chansend(socket_channel_id, { function_id, "request" })
    if bytes == 0 then
        io.stderr:write(
            string.format(
                "|fzfx.ipc_client| error! failed to send any bytes server on socket address: %s, channel id: %s",
                vim.inspect(sockaddr),
                vim.inspect(socket_channel_id)
            )
        )
    end
else
    io.stderr:write(
        string.format(
            "|fzfx.ipc_client| error! failed to connect to server on socket address: %s",
            vim.inspect(sockaddr)
        )
    )
end
