local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format("|fzfx.bin.files.provider| error! SELF_PATH is empty!")
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local provider = _G.arg[1]

shell_helpers.log_debug("provider:[%s]", provider)

local cmd = shell_helpers.read_provider_command(provider) --[[@as string]]
shell_helpers.log_debug("cmd:[%s]", cmd)

local git_root_cmd =
    shell_helpers.Command:run({ "git", "rev-parse", "--show-toplevel" })
shell_helpers.log_debug(
    "git_root_cmd.result.stdout:[%s]",
    vim.inspect(git_root_cmd.result.stdout)
)
shell_helpers.log_debug(
    "git_root_cmd.result.stderr:[%s]",
    vim.inspect(git_root_cmd.result.stderr)
)
shell_helpers.log_debug(
    "git_root_cmd.result.exitcode:[%s]",
    vim.inspect(git_root_cmd.result.exitcode)
)
if
    type(git_root_cmd.result.stderr) == "table"
    and #git_root_cmd.result.stderr > 0
then
    return
end

local p = io.popen(cmd)
shell_helpers.log_ensure(
    p ~= nil,
    "error! failed to open pipe on cmd! %s",
    vim.inspect(cmd)
)
--- @diagnostic disable-next-line: need-check-nil
for line in p:lines("*line") do
    -- shell_helpers.log_debug("line:%s", vim.inspect(line))
    local line_with_icon = shell_helpers.render_line_with_icon(line)
    io.write(string.format("%s\n", line_with_icon))
end
--- @diagnostic disable-next-line: need-check-nil
p:close()
