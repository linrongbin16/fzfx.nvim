local ICON_ENABLE = tostring(vim.env._FZFX_NVIM_ICON_ENABLE):lower() == "1"
local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format("|fzfx.bin.files.provider| error! SELF_PATH is empty!")
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local filename = _G.arg[1]
local lineno = nil
if #_G.arg >= 2 then
    lineno = _G.arg[2]
end

shell_helpers.log_debug("filename:[%s]", vim.inspect(filename))
shell_helpers.log_debug("lineno:[%s]", vim.inspect(lineno))

if ICON_ENABLE then
    local splits = vim.fn.split(filename)
    filename = splits[2]
end

if vim.fn.executable("batcat") > 0 or vim.fn.executable("bat") > 0 then
    local style = "numbers,changes"
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

    shell_helpers.log_debug("cmd:[%s]", cmd)
    os.execute(cmd)
else
    local cmd = string.format("cat %s", filename)
    shell_helpers.log_debug("cmd:[%s]", cmd)
    os.execute(cmd)
end
