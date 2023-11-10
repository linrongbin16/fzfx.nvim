local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(string.format("|fzfport| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")
shell_helpers.setup("fzfport")

local fzf_port_file = _G.arg[1]
shell_helpers.log_debug("fzf_port_file:%s", vim.inspect(fzf_port_file))
shell_helpers.log_debug("FZF_PORT:%s", vim.inspect(vim.env.FZF_PORT))

shell_helpers.writefile(fzf_port_file, tostring(vim.env.FZF_PORT))
