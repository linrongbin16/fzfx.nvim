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

shell_helpers.log_debug("provider:[%s]\n", provider)
shell_helpers.log_debug("DEBUG content:[%s]\n", content)

if content == nil then
    content = ""
end

local flag = "--"
local flag_pos = nil
local query = ""

for i = 1, #content do
    if i + 1 <= #content and string.sub(content, i, i + 1) == flag then
        flag_pos = i
        break
    end
end

local provider_cmd = shell_helpers.get_provider_command(provider)
local cmd = nil
if flag_pos ~= nil and flag_pos > 0 then
    query = vim.fn.trim(string.sub(content, 1, flag_pos - 1))
    local option = vim.fn.trim(string.sub(content, flag_pos + 2))
    cmd = string.format(
        "%s %s -- %s",
        provider_cmd,
        option,
        vim.fn.shellescape(query)
    )
else
    query = vim.fn.trim(content)
    cmd = string.format("%s -- %s", provider_cmd, vim.fn.shellescape(query))
end

shell_helpers.log_debug("cmd:%s\n", vim.inspect(cmd))

local p = io.popen(cmd)
shell_helpers.log_ensure(
    p ~= nil,
    "error! failed to open pipe on cmd: %s",
    vim.inspect(cmd)
)
--- @diagnostic disable-next-line: need-check-nil
for line in p:lines("*line") do
    local line_with_icon =
        shell_helpers.render_delimiter_line_with_icon(line, ":", 1)
    io.write(string.format("%s\n", line_with_icon))
end
--- @diagnostic disable-next-line: need-check-nil
p:close()
