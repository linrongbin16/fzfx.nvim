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

    -- local data_buffer = { "" }
    --
    -- --- @param job_id integer?
    -- --- @param code integer?
    -- --- @param event string?
    -- local function on_exit(job_id, code, event)
    --     os.exit(code)
    -- end
    --
    -- --- @param chanid integer?
    -- --- @param data string[]
    -- --- @param name string?
    -- local function on_output(chanid, data, name)
    --     -- shell_helpers.log_debug(
    --     --     "|provider| plain|command on_output name:%s, data:%s",
    --     --     vim.inspect(name),
    --     --     vim.inspect(data)
    --     -- )
    --     if #data == 1 and string.len(data[1]) == 0 then
    --         if #data_buffer > 0 then
    --             for _, line in ipairs(data_buffer) do
    --                 println(line)
    --             end
    --         end
    --         on_exit(nil, 0, name)
    --         return
    --     end
    --
    --     data_buffer[#data_buffer] = data_buffer[#data_buffer] .. data[1]
    --     vim.list_extend(data_buffer, data, 2)
    --     local i = 1
    --     -- skip the last item in data_buffer, it could be a partial line
    --     while i < #data_buffer do
    --         local line = data_buffer[i]
    --         println(line)
    --         i = i + 1
    --     end
    --     data_buffer = vim.list_slice(data_buffer, #data_buffer, #data_buffer)
    -- end
    --
    -- --- @param chanid integer?
    -- --- @param data string[]?
    -- --- @param name string?
    -- local function on_error(chanid, data, name)
    --     shell_helpers.log_debug(
    --         "|provider| plain|command on_error name:%s, data:%s",
    --         vim.inspect(name),
    --         vim.inspect(data)
    --     )
    -- end
    --
    -- local jobid = vim.fn.jobstart(cmd, {
    --     on_stdout = on_output,
    --     on_stderr = on_error,
    --     on_exit = on_exit,
    -- })
    -- vim.fn.jobwait({ jobid })
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

    local out_pipe = vim.loop.new_pipe() --[[@as uv_pipe_t]]
    local err_pipe = vim.loop.new_pipe() --[[@as uv_pipe_t]]
    shell_helpers.log_ensure(
        out_pipe ~= nil,
        "|provider| error! failed to create out pipe with vim.loop.new_pipe"
    )
    shell_helpers.log_ensure(
        err_pipe ~= nil,
        "|provider| error! failed to create err pipe with vim.loop.new_pipe"
    )
    shell_helpers.log_debug("|provider| out_pipe:%s", vim.inspect(out_pipe))
    shell_helpers.log_debug("|provider| err_pipe:%s", vim.inspect(err_pipe))

    local function on_exit(code)
        out_pipe:close()
        err_pipe:close()
        vim.loop.stop()
        os.exit(code)
    end

    local process_handler, process_id = vim.loop.spawn(cmd_splits[1], {
        args = vim.list_slice(cmd_splits, 2),
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
        "|provider| process_handler:%s, process_id:%s",
        vim.inspect(process_handler),
        vim.inspect(process_id)
    )

    --- @type string?
    local out_buffer = nil

    --- @param err string?
    --- @param data string?
    local function on_output(err, data)
        -- shell_helpers.log_debug(
        --     "|provider| plain_list|command_list on_output err:%s, data:%s",
        --     vim.inspect(err),
        --     vim.inspect(data)
        -- )
        if err then
            on_exit(1)
            return
        end

        if not data then
            if out_buffer then
                -- foreach the data_buffer and find every line
                local i = shell_helpers.consume_line(out_buffer, println)
                if i <= #out_buffer then
                    local line = out_buffer:sub(i, #out_buffer)
                    println(line)
                    out_buffer = nil
                end
            end
            on_exit(0)
            return
        end

        -- append data to data_buffer
        out_buffer = out_buffer and (out_buffer .. data) or data
        -- foreach the data_buffer and find every line
        local i = shell_helpers.consume_line(out_buffer, println)
        -- truncate the printed lines if found any
        out_buffer = i <= #out_buffer and out_buffer:sub(i, #out_buffer) or nil
    end

    local function on_error(err, data)
        shell_helpers.log_debug(
            "|provider| plain_list|command_list on_error err:%s, data:%s",
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
