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

    local out_pipe = vim.loop.new_pipe() --[[@as uv_pipe_t]]
    local err_pipe = vim.loop.new_pipe() --[[@as uv_pipe_t]]
    shell_helpers.log_ensure(
        out_pipe ~= nil,
        "|previewer| error! failed to create out pipe with vim.loop.new_pipe"
    )
    shell_helpers.log_ensure(
        err_pipe ~= nil,
        "|previewer| error! failed to create err pipe with vim.loop.new_pipe"
    )
    shell_helpers.log_debug("|previewer| out_pipe:%s", vim.inspect(out_pipe))
    shell_helpers.log_debug("|previewer| err_pipe:%s", vim.inspect(err_pipe))

    --- @type string?
    local data_buffer = nil

    local function on_exit(code)
        out_pipe:close()
        err_pipe:close()
        vim.loop.stop()
        os.exit(code)
    end

    local process_handler, process_id = vim.loop.spawn(cmd_splits[1], {
        args = { unpack(cmd_splits, 2) },
        stdio = { nil, out_pipe, err_pipe },
        -- verbatim = true,
    }, function(code, signal)
        out_pipe:read_stop()
        err_pipe:read_stop()
        out_pipe:shutdown()
        err_pipe:shutdown()
        on_exit(code)
    end)
    shell_helpers.log_debug(
        "|previewer| process_handler:%s, process_id:%s",
        vim.inspect(process_handler),
        vim.inspect(process_id)
    )

    --- @param err string?
    --- @param data string?
    local function on_output(err, data)
        -- shell_helpers.log_debug(
        --     "|previewer| plain_list|command_list on_output err:%s, data:%s",
        --     vim.inspect(err),
        --     vim.inspect(data)
        -- )
        if err then
            on_exit(1)
            return
        end

        if not data then
            if data_buffer then
                -- foreach the data_buffer and find every line
                local i = consume(data_buffer, println)
                if i <= #data_buffer then
                    local line = data_buffer:sub(i, #data_buffer)
                    println(line)
                    data_buffer = nil
                end
            end
            on_exit(0)
            return
        end

        -- append data to data_buffer
        data_buffer = data_buffer and (data_buffer .. data) or data
        -- foreach the data_buffer and find every line
        local i = consume(data_buffer, println)
        -- truncate the printed lines if found any
        data_buffer = i <= #data_buffer and data_buffer:sub(i, #data_buffer)
            or nil
    end

    local function on_error(err, data)
        shell_helpers.log_debug(
            "|previewer| plain_list|command_list on_error err:%s, data:%s",
            vim.inspect(err),
            vim.inspect(data)
        )
        -- if err then
        --     on_exit(1)
        --     return
        -- end
        -- if not data then
        --     on_exit(0)
        --     return
        -- end
    end

    out_pipe:read_start(on_output)
    err_pipe:read_start(on_error)
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
