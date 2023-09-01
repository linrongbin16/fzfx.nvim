local string_sub = string.sub
local string_byte = string.byte
local string_len = string.len
local string_format = string.format

local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string_len(SELF_PATH) == 0 then
    io.write(string_format("|provider| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_SOCKET_ADDRESS
shell_helpers.log_ensure(
    type(SOCKET_ADDRESS) == "string" and string_len(SOCKET_ADDRESS) > 0,
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

--- @type string
local metajsonstring = shell_helpers.readfile(metafile)
shell_helpers.log_ensure(
    type(metajsonstring) == "string" and string_len(metajsonstring) > 0,
    "|provider| error! metajson is not string! %s",
    vim.inspect(metajsonstring)
)
--- @type ProviderMetaJson
local metajson = vim.fn.json_decode(metajsonstring) --[[@as ProviderMetaJson]]
shell_helpers.log_debug("metajson:[%s]", vim.inspect(metajson))

if metajson.provider_type == "plain" or metajson.provider_type == "command" then
    --- @type string
    local cmd = shell_helpers.readfile(resultfile)
    shell_helpers.log_debug("cmd:[%s]", vim.inspect(cmd))
    if cmd == nil or string_len(cmd) == 0 then
        os.exit(0)
    else
        local out_pipe = vim.loop.new_pipe() --[[@as uv_pipe_t]]
        local err_pipe = vim.loop.new_pipe() --[[@as uv_pipe_t]]
        shell_helpers.log_debug("out_pipe:%s", vim.inspect(out_pipe))
        shell_helpers.log_debug("err_pipe:%s", vim.inspect(err_pipe))
        --- @type string?
        local prev_line_content = nil

        local function exit_cb(code, signal)
            out_pipe:shutdown()
            err_pipe:shutdown()
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
            exit_cb(code, signal)
        end)
        shell_helpers.log_debug(
            "process_handler:%s",
            vim.inspect(process_handler)
        )
        shell_helpers.log_debug("process_id:%s", vim.inspect(process_id))

        --- @param data string
        local function process_lines(data)
            local start_idx = 1
            repeat
                local nl_idx = shell_helpers.find_next_newline(data, start_idx)
                local line = string_sub(data, start_idx, nl_idx - 1)
                -- We used to limit lines fed into fzf to 1K for perf reasons
                -- but it turned out to have some negative consequnces (#580)
                -- if #line > 1024 then
                -- line = line:sub(1, 1024)
                -- io.stderr:write(string.format("[Fzf-lua] long line detected (%db), "
                --   .. "consider adding '--max-columns=512' to ripgrep options: %s\n",
                --   #line, line:sub(1,256)))
                -- end
                if line and string_len(line) > 0 then
                    if metajson.provider_line_type == "file" then
                        if string_len(vim.fn.trim(line)) > 0 then
                            local rendered_line =
                                shell_helpers.render_filepath_line(
                                    line,
                                    metajson.provider_line_delimiter,
                                    metajson.provider_line_pos
                                )
                            io.write(string_format("%s\n", rendered_line))
                        end
                    else
                        io.write(string_format("%s\n", line))
                    end
                end
                start_idx = nl_idx + 1
            until start_idx >= #data
        end

        local read_cb = function(err, data)
            shell_helpers.log_debug(
                "read_cb err:%s, data:%s",
                vim.inspect(err),
                vim.inspect(data)
            )
            if err then
                exit_cb(130, 0)
            end
            if not data then
                return
            end
            if prev_line_content then
                -- truncate super long line
                if #prev_line_content > 4096 then
                    prev_line_content = string_sub(prev_line_content, 1, 4096)
                end
                data = prev_line_content .. data
                prev_line_content = nil
            end

            -- data is end with '\n' (10)
            if string_byte(data, #data) == 10 then
                process_lines(data)
            else
                -- data is not end with '\n' (10)
                -- find any newlines inside data
                local nl_index = shell_helpers.find_last_newline(data)
                if not nl_index then
                    prev_line_content = data
                else
                    prev_line_content = string_sub(data, nl_index + 1)
                    local stripped_with_newline = string_sub(data, 1, nl_index)
                    process_lines(stripped_with_newline)
                end
            end
        end

        local err_cb = function(err, data)
            shell_helpers.log_debug(
                "err_cb err:%s, data:%s",
                vim.inspect(err),
                vim.inspect(data)
            )
            if err then
                exit_cb(130, 0)
            end
            if not data then
                return
            end
        end

        out_pipe:read_start(read_cb)
        err_pipe:read_start(err_cb)
        vim.loop.run()
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
