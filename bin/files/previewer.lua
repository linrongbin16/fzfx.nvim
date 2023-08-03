local args = _G.arg
local filename = args[1]
local lineno = nil
if #args >= 2 then
    lineno = args[2]
end
local debug_enable = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"
if debug_enable then
    io.write(string.format("DEBUG filename:[%s]\n", vim.inspect(filename)))
    io.write(string.format("DEBUG lineno:[%s]\n", vim.inspect(lineno)))
end

if vim.fn.executable("batcat") > 0 or vim.fn.executable("bat") > 0 then
    local style = "number"
    if
        type(vim.env["BAT_STYLE"]) == "string"
        and string.len(vim.env["BAT_STYLE"]) > 0
    then
        style = vim.env["BAT_STYLE"]
    end
    local cmd = string.format(
        "%s --style=%s --color=always --pager=never %s -- %s",
        vim.fn.executable("batcat") > 0 and "batcat" or "bat",
        style,
        (lineno ~= nil and string.len(lineno) > 0)
                and string.format("--highlight-line=%s", lineno)
            or "",
        filename
    )
    if debug_enable then
        io.write(string.format("DEBUG cmd:[%s]", cmd))
    end
    os.execute(cmd)
else
    local cmd = string.format("cat %s", filename)
    if debug_enable then
        io.write(string.format("DEBUG cmd:[%s]", cmd))
    end
    os.execute(cmd)
end
