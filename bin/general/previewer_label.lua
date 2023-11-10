local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
    io.write(string.format("|previewer_label| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")
shell_helpers.setup("previewer_label")

local PIPE_ADDRESS = vim.env._FZFX_NVIM_PIPE_ADDRESS
shell_helpers.log_ensure(
    type(PIPE_ADDRESS) == "string" and string.len(PIPE_ADDRESS) > 0,
    "error! PIPE_ADDRESS must not be empty!"
)
local registry_id = _G.arg[1]
local params = nil
if #_G.arg >= 2 then
    params = _G.arg[2]
end
shell_helpers.log_debug("PIPE_ADDRESS:%s", vim.inspect(PIPE_ADDRESS))
shell_helpers.log_debug("registry_id:%s", vim.inspect(registry_id))
shell_helpers.log_debug("params:%s", vim.inspect(params))

shell_helpers.make_pipe_rpc_notify(registry_id, params)
