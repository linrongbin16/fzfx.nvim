local args = _G.arg
local provider = args[1]
local content = args[2]

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
    io.write(string.format("DEBUG content:[%s]\n", content))
    io.write(string.format("DEBUG icon_enable:%s\n", vim.inspect(icon_enable)))
    io.write(
        string.format("DEBUG devicon_path:%s\n", vim.inspect(devicon_path))
    )
end

--- shell helper

-- job.stdout buffer {

local function new_buffer()
    local buf = { lines = { "" } }
    if debug_enable then
        io.write(string.format("DEBUG new_buffer, buf:%s\n", vim.inspect(buf)))
    end
    return buf
end

local function buffer_push(buf, data)
    buf.lines[#buf.lines] = buf.lines[#buf.lines] .. data[1]
    vim.list_extend(buf.lines, data, 2)
    if debug_enable then
        io.write(string.format("DEBUG buffer_push, buf:%s\n", vim.inspect(buf)))
    end
end

local function buffer_cut(buf)
    if #buf.lines > 1 then
        buf.lines = vim.list_slice(buf.lines, #buf.lines - 1, #buf.lines)
    end
    if debug_enable then
        io.write(string.format("DEBUG buffer_cut, buf:%s\n", vim.inspect(buf)))
    end
end

local function buffer_size(buf)
    return #buf.lines
end

local function buffer_get(buf, pos)
    return #buf.lines > 0 and buf.lines[pos] or nil
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
        local result = string.format("%d;2;%d;%d;%d", code, r, g, b)
        if debug_enable then
            io.write(
                string.format("DEBUG rgbfmt, result:%s\n", vim.inspect(result))
            )
        end
        return result
    else
        if debug_enable then
            io.write(string.format("DEBUG rgbfmt, result:nil\n"))
        end
        return nil
    end
end

local function render_line_with_icon(line, nvim_devicons)
    local splits = vim.fn.split(line, ":")
    local filename = splits[1]
    local ext = vim.fn.fnamemodify(filename, ":e")
    local icon, color = nvim_devicons.get_icon_color(filename, ext)
    if debug_enable then
        io.write(
            string.format(
                "DEBUG render_line_with_icon, line:%s\n",
                vim.inspect(line)
            )
        )
        io.write(
            string.format(
                "DEBUG render_line_with_icon, filename:%s, ext:%s\n",
                vim.inspect(filename),
                vim.inspect(ext)
            )
        )
        io.write(
            string.format(
                "DEBUG render_line_with_icon, icon:%s, color:%s\n",
                vim.inspect(icon),
                vim.inspect(color)
            )
        )
    end
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

local f = io.open(provider --[[@as string]], "r")
assert(f ~= nil, string.format("error! failed to open provider:%s", provider))
local provider_cmd = vim.fn.trim(f:read("*a"))
f:close()

if content == nil then
    content = ""
end

local flag = "--"
local flag_pos = nil
local query = ""
local option = nil

for i = 1, #content do
    if i + 1 <= #content and string.sub(content, i, i + 1) == flag then
        flag_pos = i
        break
    end
end

local cmd = nil
if flag_pos ~= nil and flag_pos > 0 then
    query = string.sub(content, 1, flag_pos - 1)
    option = string.sub(content, flag_pos + 2)
    cmd = string.format(
        "%s %s -- %s",
        provider_cmd,
        vim.fn.trim(option),
        vim.fn.shellescape(vim.fn.trim(query))
    )
else
    cmd = string.format(
        "%s -- %s",
        provider_cmd,
        vim.fn.shellescape(vim.fn.trim(content))
    )
end

if debug_enable then
    io.write(string.format("DEBUG cmd:[%s]\n", cmd))
end

local cmd_buffer = new_buffer()
local cmd_exitcode = 0

local function on_stdout(chanid, data, name)
    if debug_enable then
        io.write(
            string.format(
                "DEBUG on_stdout, data:%s, name:%s\n",
                vim.inspect(data),
                vim.inspect(name)
            )
        )
        io.write(
            string.format(
                "DEBUG on_stdout, cmd_buffer:%s\n",
                vim.inspect(cmd_buffer)
            )
        )
    end
    buffer_push(cmd_buffer, data)
    local i = 1
    while i < buffer_size(cmd_buffer) - 1 do
        local line = buffer_get(cmd_buffer, i)
        -- if icon_enable and devicon_ok then
        --     local line_with_icon = render_line_with_icon(line, devicon)
        --     io.write(string.format("%s\n", line_with_icon))
        -- else
        io.write(string.format("%s\n", line))
        -- end
        i = i + 1
    end
    buffer_cut(cmd_buffer)
end

local function on_stderr(chanid, data, name)
    if debug_enable then
        io.write(
            string.format(
                "DEBUG on_stderr, data:%s, name:%s, cmd_buffer:%s\n",
                vim.inspect(data),
                vim.inspect(name),
                vim.inspect(cmd_buffer)
            )
        )
    end
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
    while i <= buffer_size(cmd_buffer) do
        local line = buffer_get(cmd_buffer, i)
        if type(line) == "string" and string.len(line) > 0 then
            -- if icon_enable and devicon_ok then
            --     local line_with_icon = render_line_with_icon(line, devicon)
            --     io.write(string.format("%s\n", line_with_icon))
            -- else
            io.write(string.format("%s\n", line))
            -- end
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
if debug_enable then
    io.write(
        string.format(
            "DEBUG jobwait, jobid:%s, cmd_buffer:%s, cmd_exitcode:%s:\n",
            vim.inspect(jobid),
            vim.inspect(cmd_buffer),
            vim.inspect(cmd_exitcode)
        )
    )
end

vim.fn.jobwait({ jobid })
-- os.execute(cmd)
os.exit(cmd_exitcode)
