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
    if string.len(filename) > 0 then
        filename = filename:gsub("\x1b%[%d+m", "")
    end
    if debug_enable then
        io.write(
            string.format(
                "DEBUG render_line_with_icon, splits:%s, filename:%s\n",
                vim.inspect(splits[1]),
                vim.inspect(filename)
            )
        )
    end
    local ext = vim.fn.fnamemodify(filename, ":e")
    local icon, color = nvim_devicons.get_icon_color(filename, ext)
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

for i = 1, #content do
    if i + 1 <= #content and string.sub(content, i, i + 1) == flag then
        flag_pos = i
        break
    end
end

local cmd = nil
if flag_pos ~= nil and flag_pos > 0 then
    query = vim.fn.trim(string.sub(content, 1, flag_pos - 1))
    local option = vim.fn.trim(string.sub(content, flag_pos + 2))
    cmd = string.format(
        "%s %s -- %s",
        provider_cmd,
        option,
        vim.fn.shellescape(query)
    )
else
    query = vim.fn.trim(content)
    cmd = string.format("%s -- %s", provider_cmd, vim.fn.shellescape(query))
end

if debug_enable then
    io.write(string.format("DEBUG cmd:%s\n", vim.inspect(cmd)))
end

local p = io.popen(cmd)
assert(
    p ~= nil,
    string.format("error! failed to open pipe on cmd! %s", vim.inspect(cmd))
)
for line in p:lines("*line") do
    if icon_enable and devicon_ok then
        local line_with_icon = render_line_with_icon(line, devicon)
        io.write(string.format("%s\n", line_with_icon))
    else
        io.write(string.format("%s\n", line))
    end
end
p:close()
