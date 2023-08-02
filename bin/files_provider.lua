local args = _G.arg
local provider = args[1]
local _FZFX_NVIM_DEBUG_ENABLE = os.getenv("_FZFX_NVIM_DEBUG_ENABLE")
if _FZFX_NVIM_DEBUG_ENABLE then
    -- print(string.format("DEBUG provider:[%s]\n", provider))
    io.write(string.format("DEBUG provider:[%s]", provider))
end

local f = io.open(provider --[[@as string]], "r")
assert(f ~= nil, string.format("error! failed to open provider:%s", provider))
local cmd = vim.fn.trim(f:read("*a"))
f:close()

if _FZFX_NVIM_DEBUG_ENABLE then
    -- print(string.format("DEBUG cmd:[%s]\n", cmd))
    io.write(string.format("DEBUG cmd:[%s]", cmd))
end
os.execute(cmd)
