local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format("|fzfx.bin.general.previewer| error! SELF_PATH is empty!")
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_SOCKET_ADDRESS
shell_helpers.log_ensure(
    type(SOCKET_ADDRESS) == "string" and string.len(SOCKET_ADDRESS) > 0,
    "|fzfx.bin.general.previewer| error! SOCKET_ADDRESS must not be empty!"
)
local metafile = _G.arg[1]
local resultfile = _G.arg[2]
local line = _G.arg[3]
shell_helpers.log_debug("metafile:[%s]", metafile)
shell_helpers.log_debug("resultfile:[%s]", resultfile)
shell_helpers.log_debug("line:[%s]", line)

--- @type string
local metajsonstring = shell_helpers.readfile(metafile)
shell_helpers.log_ensure(
    type(metajsonstring) == "string" and string.len(metajsonstring) > 0,
    "|fzfx.bin.general.previewer| error! metajson is not string! %s",
    vim.inspect(metajsonstring)
)
--- @type {previewer_type:PreviewerType}
local metajson = vim.fn.json_decode(metajsonstring) --[[@as {previewer_type:PreviewerType}]]
shell_helpers.log_debug("metajson:[%s]", vim.inspect(metajson))

if metajson.previewer_type == "command" then
    local cmd = shell_helpers.readfile(resultfile)
    os.execute(cmd)
elseif metajson.previewer_type == "list" then
    local f = io.open(resultfile, "r")
    shell_helpers.log_ensure(
        f ~= nil,
        "error! failed to open file on resultfile! %s",
        vim.inspect(resultfile)
    )
    --- @diagnostic disable-next-line: need-check-nil
    for l in f:lines("*line") do
        -- shell_helpers.log_debug("l:%s", vim.inspect(l))
        io.write(string.format("%s\n", l))
    end
    --- @diagnostic disable-next-line: need-check-nil
    f:close()
else
    shell_helpers.log_throw(
        "|fzfx.bin.general.previewer| error! unknown previewer type:%s",
        vim.inspect(metajsonstring)
    )
end
