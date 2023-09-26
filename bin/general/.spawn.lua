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
