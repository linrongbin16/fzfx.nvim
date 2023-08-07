local args = _G.arg
local provider = args[1]
local devicon_path = vim.env._FZFX_NVIM_DEVICON_PATH
local devicon_ok = nil
local devicon = nil
if type(devicon_path) == "string" and string.len(devicon_path) > 0 then
    vim.opt.runtimepath:append(devicon_path)
    devicon_ok, devicon = pcall(require, "nvim-web-devicons")
end
local debug_enable = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"
if debug_enable then
    io.write(string.format("DEBUG provider:[%s]\n", provider))
    io.write(
        string.format("DEBUG devicon_path:[%s]\n", vim.inspect(devicon_path))
    )
    io.write(
        string.format(
            "DEBUG devicon_ok:[%s], devicon:[%s]\n",
            vim.inspect(devicon_ok),
            vim.inspect(devicon)
        )
    )
end

local f = io.open(provider --[[@as string]], "r")
assert(f ~= nil, string.format("error! failed to open provider:%s", provider))
local cmd = vim.fn.trim(f:read("*a"))
f:close()

if debug_enable then
    -- print(string.format("DEBUG cmd:[%s]\n", cmd))
    io.write(string.format("DEBUG cmd:[%s]\n", cmd))
end

local cmd_buffer = vim.ringbuf(debug_enable and 10 or 8192)
local cmd_exitcode = 0

local function on_stdout(chanid, data, name)
    if debug_enable then
        io.write(
            string.format(
                "DEBUG on_stdout, data:%s, buffer:%s",
                vim.inspect(data),
                vim.inspect(cmd_buffer)
            )
        )
    end

    local peek = cmd_buffer:peek()
    if peek ~= nil then
    end

    if #cmd_buffer > 0 then
    end
end

local function on_stderr(chanid, data, name)
    if debug_enable then
        io.write(
            string.format(
                "DEBUG on_stderr, data:%s, buffer:%s",
                vim.inspect(data),
                vim.inspect(cmd_buffer)
            )
        )
    end
end

local function on_exit(chanid, exitcode, event)
    if debug_enable then
        io.write(
            string.format(
                "DEBUG on_exit, exitcode:%s, event:%s, buffer:%s",
                vim.inspect(exitcode),
                vim.inspect(event),
                vim.inspect(cmd_buffer)
            )
        )
    end
    cmd_exitcode = exitcode
end

local jobid = vim.fn.jobstart(cmd, {
    detach = true,
    on_exit = on_exit,
    on_stdout = on_stdout,
    on_stderr = on_stderr,
})

vim.fn.jobwait({ jobid })
os.exit(cmd_exitcode)
