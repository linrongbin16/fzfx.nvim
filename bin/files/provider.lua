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

local f = io.open(provider --[[@as string]], "r")
assert(f ~= nil, string.format("error! failed to open provider:%s", provider))
local cmd = vim.fn.trim(f:read("*a"))
f:close()

if debug_enable then
    io.write(string.format("DEBUG cmd:[%s]\n", cmd))
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
