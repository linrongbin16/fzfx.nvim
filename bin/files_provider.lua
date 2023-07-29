local args = _G.arg
local provider = args[1]
local _FZFX_DEBUG_ENABLE = os.getenv("_FZFX_DEBUG_ENABLE")
if _FZFX_DEBUG_ENABLE then
    os.execute(string.format('echo "DEBUG provider:[%s]"', provider))
end

local f = io.open(provider --[[@as string]], "r")
assert(f ~= nil, string.format("error! failed to open provider:%s", provider))
local cmd = vim.fn.trim(f:read("*a"))
if _FZFX_DEBUG_ENABLE then
    os.execute(string.format('echo "DEBUG cmd:[%s]"', cmd))
end
os.execute(cmd)
