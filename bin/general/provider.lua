local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format("|fzfx.bin.general.provider| error! SELF_PATH is empty!")
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_SOCKET_ADDRESS
shell_helpers.log_ensure(
    type(SOCKET_ADDRESS) == "string" and string.len(SOCKET_ADDRESS) > 0,
    "|fzfx.bin.general.provider| error! SOCKET_ADDRESS must not be empty!"
)
local registry_id = _G.arg[1]
local metafile = _G.arg[2]
local resultfile = _G.arg[3]
local query = _G.arg[4]
shell_helpers.log_debug("registry_id:[%s]", registry_id)
shell_helpers.log_debug("metafile:[%s]", metafile)
shell_helpers.log_debug("resultfile:[%s]", resultfile)
shell_helpers.log_debug("query:[%s]", query)

local channel_id = vim.fn.sockconnect("pipe", SOCKET_ADDRESS, { rpc = true })
-- shell_helpers.log_debug("channel_id:%s", vim.inspect(channel_id))
-- shell_helpers.log_ensure(
--     channel_id > 0,
--     "|fzfx.bin.buffers.provider| error! failed to connect socket on SOCKET_ADDRESS:%s",
--     vim.inspect(SOCKET_ADDRESS)
-- )
vim.rpcrequest(
    channel_id,
    "nvim_exec_lua",
    ---@diagnostic disable-next-line: param-type-mismatch
    [[
    local luaargs = {...}
    local registry_id = luaargs[1]
    local query = luaargs[2]
    return require("fzfx.rpc_helpers").call(registry_id, query)
    ]],
    {
        registry_id,
        query,
    }
)
vim.fn.chanclose(channel_id)

--- @type string
local metajsonstring = shell_helpers.readfile(metafile)
shell_helpers.log_ensure(
    type(metajsonstring) == "string" and string.len(metajsonstring) > 0,
    "|fzfx.bin.general.provider| error! metajson is not string! %s",
    vim.inspect(metajsonstring)
)
--- @type {provider_type:ProviderType}
local metajson = vim.fn.json_decode(metajsonstring) --[[@as {provider_type:ProviderType}]]
shell_helpers.log_debug("metajson:[%s]", vim.inspect(metajson))

if metajson.provider_type == "plain" or metajson.provider_type == "command" then
    --- @type string
    local cmd = shell_helpers.readfile(resultfile)
    shell_helpers.log_debug("cmd:[%s]", vim.inspect(cmd))
    if cmd == nil or string.len(cmd) == 0 then
        os.exit(0)
    else
        os.execute(cmd)
    end
elseif metajson.provider_type == "list" then
    local f = io.open(resultfile, "r")
    shell_helpers.log_ensure(
        f ~= nil,
        "error! failed to open file on resultfile! %s",
        vim.inspect(resultfile)
    )
    --- @diagnostic disable-next-line: need-check-nil
    for line in f:lines("*line") do
        -- shell_helpers.log_debug("line:%s", vim.inspect(line))
        io.write(string.format("%s\n", line))
    end
    --- @diagnostic disable-next-line: need-check-nil
    f:close()
else
    shell_helpers.log_throw(
        "|fzfx.bin.general.provider| error! unknown provider type:%s",
        vim.inspect(metajsonstring)
    )
end
