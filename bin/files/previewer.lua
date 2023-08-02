local args = _G.arg
local filename = args[1]
local lineno = args[1]
local _FZFX_NVIM_DEBUG_ENABLE = os.getenv("_FZFX_NVIM_DEBUG_ENABLE")
if _FZFX_NVIM_DEBUG_ENABLE then
    io.write(
        string.format("DEBUG filename:[%s], lineno:[%s]", filename, lineno)
    )
end

local bat_style = vim.env["BAT_STYLE"]
if type(bat_style) ~= "string" or string.len(bat_style) <= 0 then
    bat_style = "number"
end

local bat = nil
if vim.fn.executable("batcat") > 0 then
elseif vim.fn.executable("bat") > 0 then
    bat = "bat"
end

if type(bat) == "string" and string.len(bat) > 0 then
    local cmd = string.format(
        "batcat --style=%s --color=always --pager=never --highlight-line=%s -- %s",
        bat_style,
        lineno,
        filename
    )
    if _FZFX_NVIM_DEBUG_ENABLE then
        io.write(string.format("DEBUG cmd:[%s]", cmd))
    end
    os.execute(cmd)
else
    local cmd = string.format("cat %s", filename)
    if _FZFX_NVIM_DEBUG_ENABLE then
        io.write(string.format("DEBUG cmd:[%s]", cmd))
    end
    os.execute(cmd)
end
