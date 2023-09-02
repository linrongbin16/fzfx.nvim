local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(string.format("|provider| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")
shell_helpers.setup("general-provider")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_SOCKET_ADDRESS
shell_helpers.log_ensure(
    type(SOCKET_ADDRESS) == "string" and string.len(SOCKET_ADDRESS) > 0,
    "error! SOCKET_ADDRESS must not be empty!"
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
    "error! metajson is not string! %s",
    vim.inspect(metajsonstring)
)
--- @type ProviderMetaJson
local metajson = vim.fn.json_decode(metajsonstring) --[[@as ProviderMetaJson]]
shell_helpers.log_debug("metajson:[%s]", vim.inspect(metajson))

if metajson.provider_type == "plain" or metajson.provider_type == "command" then
    --- @type string
    local cmd = shell_helpers.readfile(resultfile)
    shell_helpers.log_debug("cmd:[%s]", vim.inspect(cmd))
    if cmd == nil or string.len(cmd) == 0 then
        os.exit(0)
    else
        local out_pipe = vim.loop.new_pipe() --[[@as uv_pipe_t]]
        local err_pipe = vim.loop.new_pipe() --[[@as uv_pipe_t]]
        shell_helpers.log_ensure(
            out_pipe ~= nil,
            "error! failed to create out pipe with vim.loop.new_pipe"
        )
        shell_helpers.log_ensure(
            err_pipe ~= nil,
            "error! failed to create err pipe with vim.loop.new_pipe"
        )
        shell_helpers.log_debug("out_pipe:%s", vim.inspect(out_pipe))
        shell_helpers.log_debug("err_pipe:%s", vim.inspect(err_pipe))

        --- @type string?
        local data_buffer = nil

        --- @param code integer
        local function on_exit(code)
            out_pipe:shutdown()
            err_pipe:shutdown()
            os.exit(code)
        end

        local cmd_splits = vim.fn.split(cmd)
        local process_handler, process_id = vim.loop.spawn(cmd_splits[1], {
            args = { unpack(cmd_splits, 2) },
            stdio = { nil, out_pipe, err_pipe },
            verbatim = true,
        }, function(code, signal)
            out_pipe:read_stop()
            err_pipe:read_stop()
            out_pipe:close()
            err_pipe:close()
            on_exit(code)
        end)
        shell_helpers.log_debug(
            "process_handler:%s, process_id:%s",
            vim.inspect(process_handler),
            vim.inspect(process_id)
        )

        --- @param line string?
        local function writeline(line)
            if type(line) == "string" and string.len(vim.trim(line)) > 0 then
                if metajson.provider_line_type == "file" then
                    local rendered_line = shell_helpers.render_filepath_line(
                        line,
                        metajson.provider_line_delimiter,
                        metajson.provider_line_pos
                    )
                    io.write(string.format("%s\n", rendered_line))
                else
                    io.write(string.format("%s\n", line))
                end
            end
        end

        --- @param err string?
        --- @param data string?
        local function on_output(err, data)
            shell_helpers.log_debug(
                "on_output err:%s, data:%s",
                vim.inspect(err),
                vim.inspect(data)
            )
            if err then
                on_exit(130)
                return
            end
            if not data then
                on_exit(0)
                return
            end

            -- append data to data_buffer
            data_buffer = data and data_buffer .. data or data

            -- foreach the data_buffer and find every line
            local i = 1
            local truncated = false
            while i <= #data_buffer do
                local newline_pos =
                    shell_helpers.string_find(data_buffer, "\n", i)
                if not newline_pos then
                    break
                end
                local line = data_buffer:sub(i, newline_pos - 1)
                writeline(line)
                i = newline_pos + 1
                truncated = true
            end

            -- truncate the printed lines if any
            if truncated then
                data_buffer = i <= #data_buffer
                        and data_buffer:sub(i, #data_buffer)
                    or nil
            end
        end

        local function on_error(err, data)
            shell_helpers.log_debug(
                "on_error err:%s, data:%s",
                vim.inspect(err),
                vim.inspect(data)
            )
            if err then
                on_exit(130)
                return
            end
            if not data then
                on_exit(0)
                return
            end
        end

        out_pipe:read_start(on_output)
        err_pipe:read_start(on_error)
    end
elseif metajson.provider_type == "list" then
    local f = io.open(resultfile, "r")
    if f then
        if metajson.provider_line_type == "file" then
            --- @diagnostic disable-next-line: need-check-nil
            for line in f:lines("*line") do
                if string.len(vim.fn.trim(line)) > 0 then
                    local line_with_icon = shell_helpers.render_filepath_line(
                        line,
                        metajson.provider_line_delimiter,
                        metajson.provider_line_pos
                    )
                    io.write(string.format("%s\n", line_with_icon))
                end
            end
        else
            for line in f:lines("*line") do
                -- shell_helpers.log_debug("line:%s", vim.inspect(line))
                if string.len(vim.fn.trim(line)) > 0 then
                    io.write(string.format("%s\n", line))
                end
            end
        end
        f:close()
    else
        shell_helpers.debug(
            "|provider| error! failed to open file on list provider resultfile! %s",
            vim.inspect(resultfile)
        )
    end
else
    shell_helpers.log_throw(
        "|provider| error! unknown provider type:%s",
        vim.inspect(metajsonstring)
    )
end
