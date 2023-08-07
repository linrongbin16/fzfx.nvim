local args = _G.arg
local provider = args[1]
local icon_enable = tostring(vim.env._FZFX_NVIM_ICON_ENABLE):lower() == "1"
local devicon_path = vim.env._FZFX_NVIM_DEVICON_PATH
local devicon_ok = nil
local devicon = nil
if
    icon_enable
    and type(devicon_path) == "string"
    and string.len(devicon_path) > 0
then
    vim.opt.runtimepath:append(devicon_path)
    devicon_ok, devicon = pcall(require, "nvim-web-devicons")
end

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

--- shell helper

-- job.stdout buffer {

-- FIFO buffer, push at tail, cut from head
--- @class StdoutBuffer
--- @field lines string[]
local StdoutBuffer = {
    lines = {},
}

function StdoutBuffer:new()
    return vim.tbl_deep_extend(
        "force",
        vim.deepcopy(StdoutBuffer),
        { lines = { "" } }
    )
end

-- push at tail
--- @param data string[]
--- @return nil
function StdoutBuffer:push(data)
    self.lines[#self.lines] = self.lines[#self.lines] .. data[1]
    vim.list_extend(self.lines, data, 2)
end

-- cut from head
--- @return nil
function StdoutBuffer:cut()
    if #self.lines > 1 then
        self.lines = vim.list_slice(self.lines, #self.lines - 1, #self.lines)
    end
end

function StdoutBuffer:size()
    return #self.lines
end

--- @param pos integer
--- @return string|nil
function StdoutBuffer:get(pos)
    return #self.lines > 0 and self.lines[pos] or nil
end

-- job.stdout buffer }

-- color render {

--- @param rgb string
--- @param fg boolean
--- @return string|nil
local function rgbfmt(rgb, fg)
    local code = fg and 38 or 48
    local r, g, b = rgb:match("#(..)(..)(..)")
    if r and g and b then
        r = tonumber(r, 16)
        g = tonumber(g, 16)
        b = tonumber(b, 16)
        return string.format("%d;2;%d;%d;%d", code, r, g, b)
    else
        return nil
    end
end

local function render_line_with_icon(line, nvim_devicons)
    local ext = vim.fn.fnamemodify(line, ":e")
    local icon, color = nvim_devicons.get_icon_color(line, ext)
    -- if debug_enable then
    --     io.write(
    --         string.format(
    --             "DEBUG line:%s, ext:%s, icon:%s, color:%s\n",
    --             vim.inspect(line),
    --             vim.inspect(ext),
    --             vim.inspect(icon),
    --             vim.inspect(color)
    --         )
    --     )
    -- end
    if type(icon) == "string" and string.len(icon) > 0 then
        local colorfmt = rgbfmt(color, true)
        if colorfmt then
            return string.format("[%sm%s[0m %s", colorfmt, icon, line)
        else
            return string.format("%s %s", icon, line)
        end
    else
        return string.format(" %s", line)
    end
end

-- color render }

--- shell helper

--- @type StdoutBuffer
local cmd_buffer = StdoutBuffer:new()
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
        local line_with_icon = render_line_with_icon(line, devicon)
        -- local icon, icon_color = devicon.get_icon_color(line)
        io.write(string.format("%s\n", line_with_icon))
        -- io.write(string.format("%s\n", line_with_icon))
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
            -- local icon = devicon.get_icon_color(line)
            local line_with_icon = render_line_with_icon(line, devicon)
            io.write(string.format("%s\n", line_with_icon))
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
