local args = _G.arg

local _FZFX_GREP_COMMAND = os.getenv("_FZFX_GREP_COMMAND")
local content = args[1]
local cmd = string.format('%s -- "%s"', _FZFX_GREP_COMMAND, content)
print("cmd:[" .. cmd .. "]\n")
os.execute(cmd)
