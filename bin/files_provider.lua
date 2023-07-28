local _FZFX_DEBUG = os.getenv("_FZFX_DEBUG")
local _FZFX_FILES_PROVIDER = os.getenv("_FZFX_FILES_PROVIDER")
if _FZFX_DEBUG then
    print(
        string.format("DEBUG _FZFX_FILES_PROVIDER:[%s]\n", _FZFX_FILES_PROVIDER)
    )
end
local f = io.open(_FZFX_FILES_PROVIDER --[[@as string]], "r")
assert(
    f ~= nil,
    string.format(
        "Error! failed to open _FZFX_FILES_PROVIDER:%s",
        _FZFX_FILES_PROVIDER
    )
)
local cmd = vim.fn.trim(f:read("*a"))
if _FZFX_DEBUG then
    print(string.format("DEBUG cmd:[%s]\n", cmd))
end
os.execute(cmd)
