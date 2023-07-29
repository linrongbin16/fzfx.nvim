local args = _G.arg
local provider = args[1]
local content = args[2]

local _FZFX_DEBUG_ENABLE = os.getenv("_FZFX_DEBUG_ENABLE")
if _FZFX_DEBUG_ENABLE then
    os.execute(string.format("echo DEBUG provider:[%s]", provider))
    os.execute(string.format("echo DEBUG content:[%s]", content))
end

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
    cmd = string.format("%s %s -- %s", provider_cmd, option, query)
else
    cmd = string.format("%s -- %s", provider_cmd, content)
end

if _FZFX_DEBUG_ENABLE then
    os.execute(string.format("echo DEBUG cmd:[%s]", cmd))
end
os.execute(cmd)
