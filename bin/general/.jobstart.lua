local data_buffer = { "" }

--- @param job_id integer?
--- @param code integer?
--- @param event string?
local function on_exit(job_id, code, event)
    os.exit(code)
end

--- @param chanid integer?
--- @param data string[]
--- @param name string?
local function on_output(chanid, data, name)
    -- shell_helpers.log_debug(
    --     "|provider| plain|command on_output name:%s, data:%s",
    --     vim.inspect(name),
    --     vim.inspect(data)
    -- )
    if #data == 1 and string.len(data[1]) == 0 then
        if #data_buffer > 0 then
            for _, line in ipairs(data_buffer) do
                println(line)
            end
        end
        on_exit(nil, 0, name)
        return
    end

    data_buffer[#data_buffer] = data_buffer[#data_buffer] .. data[1]
    vim.list_extend(data_buffer, data, 2)
    local i = 1
    -- skip the last item in data_buffer, it could be a partial line
    while i < #data_buffer do
        local line = data_buffer[i]
        println(line)
        i = i + 1
    end
    data_buffer = vim.list_slice(data_buffer, #data_buffer, #data_buffer)
end

--- @param chanid integer?
--- @param data string[]?
--- @param name string?
local function on_error(chanid, data, name)
    shell_helpers.log_debug(
        "|provider| plain|command on_error name:%s, data:%s",
        vim.inspect(name),
        vim.inspect(data)
    )
end

local jobid = vim.fn.jobstart(cmd, {
    on_stdout = on_output,
    on_stderr = on_error,
    on_exit = on_exit,
})
vim.fn.jobwait({ jobid })
