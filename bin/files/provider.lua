local DEBUG_ENABLE = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"
local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format("|fzfx.bin.files.provider| error! SELF_PATH is empty!")
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local provider = _G.arg[1]

if DEBUG_ENABLE then
    io.write(string.format("DEBUG provider:[%s]\n", provider))
end

local cmd = shell_helpers.get_provider_command(provider) --[[@as string]]
shell_helpers.log_debug("cmd:[%s]", cmd)

local p = io.popen(cmd)
shell_helpers.ensure(
    p ~= nil,
    "error! failed to open pipe on cmd! %s",
    vim.inspect(cmd)
)
--- @diagnostic disable-next-line: need-check-nil
for line in p:lines("*line") do
    local line_with_icon = shell_helpers.render_line_with_icon(line)
    io.write(string.format("%s\n", line_with_icon))
end
--- @diagnostic disable-next-line: need-check-nil
p:close()
