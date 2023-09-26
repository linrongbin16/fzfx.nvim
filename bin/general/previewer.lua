local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format("|fzfx.bin.general.previewer| error! SELF_PATH is empty!")
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_SOCKET_ADDRESS
shell_helpers.log_ensure(
    type(SOCKET_ADDRESS) == "string" and string.len(SOCKET_ADDRESS) > 0,
    "|fzfx.bin.general.previewer| error! SOCKET_ADDRESS must not be empty!"
)
local registry_id = _G.arg[1]
local metafile = _G.arg[2]
local resultfile = _G.arg[3]
local line = nil
if #_G.arg >= 4 then
    line = _G.arg[4]
end
shell_helpers.log_debug("registry_id:[%s]", registry_id)
shell_helpers.log_debug("metafile:[%s]", metafile)
shell_helpers.log_debug("resultfile:[%s]", resultfile)
shell_helpers.log_debug("line:[%s]", vim.inspect(line))

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
    local line = luaargs[2]
    return require("fzfx.rpc_helpers").call(registry_id, line)
    ]],
    {
        registry_id,
        line,
    }
)
vim.fn.chanclose(channel_id)

--- @type string
local metajsonstring = shell_helpers.readfile(metafile)
shell_helpers.log_ensure(
    type(metajsonstring) == "string" and string.len(metajsonstring) > 0,
    "|fzfx.bin.general.previewer| error! metajson is not string! %s",
    vim.inspect(metajsonstring)
)
--- @type {previewer_type:PreviewerType}
local metajson = vim.fn.json_decode(metajsonstring) --[[@as {previewer_type:PreviewerType}]]
shell_helpers.log_debug("metajson:[%s]", vim.inspect(metajson))

--- @param l string?
local function println(l)
    if type(l) == "string" and string.len(vim.trim(l)) > 0 then
        l = shell_helpers.string_rtrim(l)
        io.write(string.format("%s\n", l))
    end
end

--- @param data_buffer string
--- @param fn_line_processor fun(l:string?):nil
local function consume(data_buffer, fn_line_processor)
    local i = 1
    while i <= #data_buffer do
        local newline_pos = shell_helpers.string_find(data_buffer, "\n", i)
        if not newline_pos then
            break
        end
        local line = data_buffer:sub(i, newline_pos)
        fn_line_processor(line)
        i = newline_pos + 1
    end
    return i
end

if metajson.previewer_type == "command" then
    local cmd = shell_helpers.readfile(resultfile)
    shell_helpers.log_debug("cmd:[%s]", vim.inspect(cmd))
    if cmd == nil or string.len(cmd) == 0 then
        os.exit(0)
    else
        os.execute(cmd)
    end
elseif metajson.previewer_type == "command_list" then
    local cmd = shell_helpers.readfile(resultfile)
    shell_helpers.log_debug("cmd:[%s]", vim.inspect(cmd))
    if cmd == nil or string.len(cmd) == 0 then
        os.exit(0)
        return
    end
    local cmd_splits = vim.fn.json_decode(cmd)
    if type(cmd_splits) ~= "table" or vim.tbl_isempty(cmd_splits) then
        os.exit(0)
        return
    end

    local process_context = {
        process_handler = nil,
        process_id = nil,
    }
    local async_spawn = shell_helpers.AsyncSpawn:open(cmd_splits, println, {
        on_exit = function(code, signal)
            vim.loop.stop()
            if shell_helpers.is_windows then
                if process_context.process_handler then
                    process_context.process_handler:kill()
                end
            else
                if process_context.process_id then
                    vim.loop.kill(process_context.process_id --[[@as integer]])
                end
            end
            os.exit(code)
        end,
    }) --[[@as AsyncSpawn]]
    shell_helpers.log_ensure(
        async_spawn ~= nil,
        "|provider| error! failed to open async command: %s",
        vim.inspect(cmd_splits)
    )
    local process_handler, process_id = async_spawn:start()
    process_context.process_handler = process_handler
    process_context.process_id = process_id
    vim.loop.run()
elseif metajson.previewer_type == "list" then
    local f = io.open(resultfile, "r")
    shell_helpers.log_ensure(
        f ~= nil,
        "error! failed to open file on resultfile! %s",
        vim.inspect(resultfile)
    )
    --- @diagnostic disable-next-line: need-check-nil
    for l in f:lines("*line") do
        shell_helpers.log_debug("list:[%s]", l)
        io.write(string.format("%s\n", l))
    end
    --- @diagnostic disable-next-line: need-check-nil
    f:close()
else
    shell_helpers.log_throw(
        "|fzfx.bin.general.previewer| error! unknown previewer type:%s",
        vim.inspect(metajsonstring)
    )
end
