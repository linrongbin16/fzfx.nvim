local args = _G.arg
local provider = args[1]
local debug_enable = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower()
debug_enable = debug_enable:match("true$") or debug_enable == "1"
if debug_enable then
    -- print(string.format("DEBUG provider:[%s]\n", provider))
    io.write(string.format("DEBUG provider:[%s]", provider))
end

local f = io.open(provider --[[@as string]], "r")
assert(f ~= nil, string.format("error! failed to open provider:%s", provider))
local cmd = vim.fn.trim(f:read("*a"))
f:close()

if debug_enable then
    -- print(string.format("DEBUG cmd:[%s]\n", cmd))
    io.write(string.format("DEBUG cmd:[%s]", cmd))
end
os.execute(cmd)
