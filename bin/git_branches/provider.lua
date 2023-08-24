local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format(
            "|fzfx.bin.git_branches.provider| error! SELF_PATH is empty!"
        )
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local provider = _G.arg[1]
shell_helpers.log_debug("provider:[%s]", provider)

local cmd = shell_helpers.read_provider_command(provider) --[[@as string]]
shell_helpers.log_debug("cmd:[%s]", cmd)

local git_root_cmd = shell_helpers.GitRootCommand:run()
-- shell_helpers.log_debug(
--     "git_root_cmd.result:%s",
--     vim.inspect(git_root_cmd.result)
-- )
if git_root_cmd:wrong() then
    return
end

local git_current_branch_cmd = shell_helpers.GitCurrentBranchCommand:run()
shell_helpers.log_debug(
    "git_current_branch_cmd.result.stdout:%s",
    vim.inspect(git_current_branch_cmd.result.stdout)
)
shell_helpers.log_debug(
    "git_current_branch_cmd.result.stderr:%s",
    vim.inspect(git_current_branch_cmd.result.stderr)
)
shell_helpers.log_debug(
    "git_current_branch_cmd.result.exitcode:%s",
    vim.inspect(git_current_branch_cmd.result.exitcode)
)
if git_current_branch_cmd:wrong() then
    shell_helpers.log_err(
        "|fzfx.bin.git_branches.provider| git_current_branch_cmd.wrong:%s",
        vim.inspect(git_current_branch_cmd)
    )
end

local current_branch = string.format("* %s", git_current_branch_cmd:value())
local other_branches = {}
local p = io.popen(cmd)
shell_helpers.log_ensure(
    p ~= nil,
    "error! failed to open pipe on cmd! %s",
    vim.inspect(cmd)
)
--- @diagnostic disable-next-line: need-check-nil
for line in p:lines("*line") do
    -- shell_helpers.log_debug("line:%s", vim.inspect(line))
    if string.len(line) > 0 then
        if vim.fn.trim(line):sub(1, 1) ~= "*" then
            table.insert(other_branches, line)
        end
    end
end
--- @diagnostic disable-next-line: need-check-nil
p:close()

io.write(string.format("%s\n", current_branch))
for _, b in ipairs(other_branches) do
    io.write(string.format("%s\n", b))
end
