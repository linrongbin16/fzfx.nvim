local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format("|fzfx.bin.files.provider| error! SELF_PATH is empty!")
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local provider = _G.arg[1]
local content = _G.arg[2]

shell_helpers.log_debug("provider:[%s]", provider)
shell_helpers.log_debug("DEBUG content:[%s]", content)

if content == nil then
    content = ""
end

local provider_cmd = shell_helpers.read_provider_command(provider)
local cmd = nil
local parsed_query = shell_helpers.parse_query(content)
if parsed_query[2] ~= nil and string.len(parsed_query[2]) > 0 then
    local query = parsed_query[1]
    local option = parsed_query[2]
    cmd = string.format(
        "%s %s -- %s",
        provider_cmd,
        option,
        vim.fn.shellescape(query)
    )
else
    local query = parsed_query[1]
    cmd = string.format("%s -- %s", provider_cmd, vim.fn.shellescape(query))
end

shell_helpers.log_debug("cmd:%s", vim.inspect(cmd))

local p = io.popen(cmd)
shell_helpers.log_ensure(
    p ~= nil,
    "error! failed to open pipe on cmd: %s",
    vim.inspect(cmd)
)
--- @diagnostic disable-next-line: need-check-nil
for line in p:lines("*line") do
    local line_with_icon = shell_helpers.render_filepath_line(line, ":", 1)
    io.write(string.format("%s\n", line_with_icon))
end
--- @diagnostic disable-next-line: need-check-nil
p:close()
