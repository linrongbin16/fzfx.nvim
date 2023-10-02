local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(string.format("|provider| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_SOCKET_ADDRESS
shell_helpers.log_ensure(
    type(SOCKET_ADDRESS) == "string" and string.len(SOCKET_ADDRESS) > 0,
    "|provider| error! SOCKET_ADDRESS must not be empty!"
)
local registry_id = _G.arg[1]
local metafile = _G.arg[2]
local resultfile = _G.arg[3]
local query = _G.arg[4]
shell_helpers.log_debug("|provider| registry_id:[%s]", registry_id)
shell_helpers.log_debug("|provider| metafile:[%s]", metafile)
shell_helpers.log_debug("|provider| resultfile:[%s]", resultfile)
shell_helpers.log_debug("|provider| query:[%s]", query)

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

local metajsonstring = shell_helpers.readfile(metafile) --[[@as string]]
shell_helpers.log_ensure(
    type(metajsonstring) == "string" and string.len(metajsonstring) > 0,
    "|provider| error! metajson is not string! %s",
    vim.inspect(metajsonstring)
)
--- @type ProviderMetaOpts
local metaopts = vim.fn.json_decode(metajsonstring) --[[@as ProviderMetaOpts]]
shell_helpers.log_debug("|provider| metajson:[%s]", vim.inspect(metaopts))

--- @param line string?
local function println(line)
    if type(line) == "string" and string.len(vim.trim(line)) > 0 then
        line = shell_helpers.string_rtrim(line)
        if metaopts.prepend_icon_by_ft then
            local rendered_line = shell_helpers.prepend_path_with_icon(
                line,
                metaopts.prepend_icon_path_delimiter,
                metaopts.prepend_icon_path_position
            )
            io.write(string.format("%s\n", rendered_line))
        else
            io.write(string.format("%s\n", line))
        end
    end
end

if metaopts.provider_type == "plain" or metaopts.provider_type == "command" then
    --- @type string
    local cmd = shell_helpers.readfile(resultfile) --[[@as string]]
    shell_helpers.log_debug(
        "|provider| plain or command cmd:[%s]",
        vim.inspect(cmd)
    )
    if cmd == nil or string.len(cmd) == 0 then
        os.exit(0)
        return
    end

    local p = io.popen(cmd)
    shell_helpers.log_ensure(
        p ~= nil,
        "|provider| error! failed to open pipe on provider cmd! %s",
        vim.inspect(cmd)
    )
    ---@diagnostic disable-next-line: need-check-nil
    for line in p:lines("*line") do
        println(line)
    end
    ---@diagnostic disable-next-line: need-check-nil
    p:close()
elseif
    metaopts.provider_type == "plain_list"
    or metaopts.provider_type == "command_list"
then
    local cmd = shell_helpers.readfile(resultfile) --[[@as string]]
    shell_helpers.log_debug(
        "|provider| plain_list or command_list cmd:[%s]",
        vim.inspect(cmd)
    )
    if cmd == nil or string.len(cmd) == 0 then
        os.exit(0)
        return
    end

    local cmd_splits = vim.fn.json_decode(cmd)
    if type(cmd_splits) ~= "table" or vim.tbl_isempty(cmd_splits) then
        os.exit(0)
        return
    end

    -- local async_spawn = shell_helpers.AsyncSpawn:open(cmd_splits, println) --[[@as AsyncSpawn]]
    -- shell_helpers.log_ensure(
    --     async_spawn ~= nil,
    --     "|provider| error! failed to open async command: %s",
    --     vim.inspect(cmd_splits)
    -- )
    -- async_spawn:run()

    local async_cmd = shell_helpers.AsyncCmd:run(cmd_splits, println) --[[@as AsyncCmd]]
    async_cmd:wait()
elseif metaopts.provider_type == "list" then
    local reader = shell_helpers.FileLineReader:open(resultfile) --[[@as FileLineReader ]]
    shell_helpers.log_ensure(
        reader ~= nil,
        "|provider| error! failed to open resultfile: %s",
        vim.inspect(resultfile)
    )

    while reader:has_next() do
        local line = reader:next()
        println(line)
    end
    reader:close()
else
    shell_helpers.log_throw(
        "|provider| error! unknown provider type:%s",
        vim.inspect(metajsonstring)
    )
end
