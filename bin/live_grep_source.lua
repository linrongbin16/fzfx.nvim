local args = _G.arg

local _FZFX_RG_COMMAND = os.getenv("_FZFX_RG_COMMAND")
local content = args[1]
local cmd = string.format('%s -- "%s"', _FZFX_RG_COMMAND, content)
print("cmd:[" .. cmd .. "]\n")
os.execute(cmd)
