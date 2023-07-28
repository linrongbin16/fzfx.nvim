local _FZFX_DEBUG = os.getenv("_FZFX_DEBUG")
local _FZFX_LIVE_GREP_PROVIDER = os.getenv("_FZFX_LIVE_GREP_PROVIDER")
local args = _G.arg
local content = args[1]

if _FZFX_DEBUG then
    os.execute(
        string.format(
            'echo "DEBUG _FZFX_LIVE_GREP_PROVIDER:[%s]"',
            _FZFX_LIVE_GREP_PROVIDER
        )
    )
    os.execute(string.format('echo "DEBUG content:[%s]"', content))
end

local f = io.open(_FZFX_LIVE_GREP_PROVIDER --[[@as string]], "r")
assert(
    f ~= nil,
    string.format(
        "error! failed to open _FZFX_LIVE_GREP_PROVIDER:%s",
        _FZFX_LIVE_GREP_PROVIDER
    )
)
local cmd = vim.fn.trim(f:read("*a"))
if _FZFX_DEBUG then
    print(string.format("DEBUG cmd:[%s]\n", cmd))
end
os.execute(cmd)
