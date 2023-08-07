local args = _G.arg
local provider = args[1]
local devicon_path = vim.env._FZFX_NVIM_DEVICON_PATH
local devicon_ok = nil
local devicon = nil
if type(devicon_path) == "string" and string.len(devicon_path) > 0 then
    vim.opt.runtimepath:append(devicon_path)
    devicon_ok, devicon = pcall(require, "nvim-web-devicons")
end
local self_path = vim.env._FZFX_NVIM_SELF_PATH
local self_helpers_ok = nil
local self_helpers = nil
assert(
    type(self_path) == "string" and string.len(self_path) > 0,
    string.format(
        "error! cannot find 'fzfx.nvim' plugin on runtimepath! %s",
        vim.inspect(vim.o.runtimepath)
    )
)
vim.opt.runtimepath:append(self_path)
self_helpers_ok, self_helpers = pcall(require, "fzfx.helpers")
assert(
    self_helpers_ok,
    string.format(
        "error! cannot load 'fzfx.helpers' module on runtimepath! %s",
        vim.inspect(vim.o.runtimepath)
    )
)

local debug_enable = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"
if debug_enable then
    io.write(string.format("DEBUG provider:[%s]\n", provider))
    -- io.write(
    --     string.format("DEBUG devicon_path:[%s]\n", vim.inspect(devicon_path))
    -- )
    -- io.write(
    --     string.format(
    --         "DEBUG devicon_ok:[%s], devicon:[%s]\n",
    --         vim.inspect(devicon_ok),
    --         vim.inspect(devicon)
    --     )
    -- )
    -- io.write(string.format("DEBUG self_path:[%s]\n", vim.inspect(self_path)))
    -- io.write(
    --     string.format(
    --         "DEBUG self_helpers_ok:[%s], self_helpers:[%s]\n",
    --         vim.inspect(self_helpers_ok),
    --         vim.inspect(self_helpers)
    --     )
    -- )
end

local f = io.open(provider --[[@as string]], "r")
assert(f ~= nil, string.format("error! failed to open provider:%s", provider))
local cmd = vim.fn.trim(f:read("*a"))
f:close()

if debug_enable then
    io.write(string.format("DEBUG cmd:[%s]\n", cmd))
end

--- @type StdoutBuffer
local cmd_buffer = self_helpers.StdoutBuffer:new()
local cmd_exitcode = 0

-- here we use lua coroutine to while processing stdout data, and print to terminal at the same time,
-- to achieve the purpose of running CPU and IO devices at the same time, thus improve our performance.

-- --- @type fun|nil
-- local co = coroutine.create(function()
--     if debug_enable then
--         io.write(
--             string.format(
--                 "DEBUG coroutine.create, cmd_buffer:%s\n",
--                 vim.inspect(cmd_buffer)
--             )
--         )
--     end
--     local last_line = cmd_buffer:pop()
--     if last_line ~= nil then
--         local formatted_line = last_line:print()
--         if devicon_ok and devicon then
--             local icon = devicon.get_icon(formatted_line)
--             io.write(string.format("%s %s\n", icon, formatted_line))
--         else
--             io.write(string.format("%s\n", formatted_line))
--         end
--     end
--     -- go back to the co_producer, e.g. on_stdout
--     coroutine.yield()
-- end)

--- @param chanid integer
--- @param data string[]
--- @param name string
--- @return nil
local function on_stdout(chanid, data, name)
    -- if debug_enable then
    --     io.write(string.format("DEBUG on_stdout, data:%s\n", vim.inspect(data)))
    --     io.write(
    --         string.format(
    --             "DEBUG on_stdout, cmd_buffer:%s\n",
    --             vim.inspect(cmd_buffer)
    --         )
    --     )
    -- end
    cmd_buffer:push(data)
    if debug_enable then
        io.write(
            string.format(
                "DEBUG on_stdout, push, cmd_buffer:%s\n",
                vim.inspect(cmd_buffer)
            )
        )
    end
    local i = 1
    while i < cmd_buffer:size() do
        local line = cmd_buffer:get(i)
        io.write(string.format("%s\n", line))
        i = i + 1
    end
    cmd_buffer:cut()
end

local function on_stderr(chanid, data, name)
    -- if debug_enable then
    --     io.write(
    --         string.format(
    --             "DEBUG on_stderr, chanid:%s, data:%s, name:%s, buffer:%s\n",
    --             vim.inspect(chanid),
    --             vim.inspect(data),
    --             vim.inspect(name),
    --             vim.inspect(cmd_buffer)
    --         )
    --     )
    -- end
end

local function on_exit(chanid, exitcode, event)
    if debug_enable then
        io.write(
            string.format(
                "DEBUG on_exit, exitcode:%s, event:%s, buffer:%s\n",
                vim.inspect(exitcode),
                vim.inspect(event),
                vim.inspect(cmd_buffer)
            )
        )
    end
    local i = 1
    while i <= cmd_buffer:size() do
        local line = cmd_buffer:get(i)
        if type(line) == "string" and string.len(line) > 0 then
            io.write(string.format("%s\n", line))
        end
        i = i + 1
    end
    cmd_exitcode = exitcode
end

local jobid = vim.fn.jobstart(cmd, {
    on_exit = on_exit,
    on_stdout = on_stdout,
    on_stderr = on_stderr,
})
-- if debug_enable then
--     io.write(
--         string.format(
--             "DEBUG jobwait, jobid:%s, cmd_buffer:%s, cmd_exitcode:%s:\n",
--             vim.inspect(jobid),
--             vim.inspect(cmd_buffer),
--             vim.inspect(cmd_exitcode)
--         )
--     )
-- end

vim.fn.jobwait({ jobid })
os.exit(cmd_exitcode)
