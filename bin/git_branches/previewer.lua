local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(
        string.format(
            "|fzfx.bin.git_branches.previewer| error! SELF_PATH is empty!"
        )
    )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")

local previewer = _G.arg[1]
local branch = _G.arg[2]

shell_helpers.log_debug("previewer:[%s]", vim.inspect(previewer))
shell_helpers.log_debug("branch:[%s]", vim.inspect(branch))

branch = vim.fn.split(branch)[1]
local cmd = shell_helpers.read_provider_command(previewer) --[[@as string]]
cmd = string.format("%s %s", cmd, branch)

shell_helpers.log_debug("cmd:[%s]", cmd)
os.execute(cmd)
