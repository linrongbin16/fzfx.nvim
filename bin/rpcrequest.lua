local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
  io.write(string.format("|bin.rpcrequest| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)

local str = require("fzfx.commons.str")
local shell_helpers = require("fzfx.detail.shell_helpers")
shell_helpers.setup("rpcrequest")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_RPC_SERVER_ADDRESS
shell_helpers.log_ensure(str.not_empty(SOCKET_ADDRESS), "error! SOCKET_ADDRESS must not be empty!")
-- shell_helpers.log_debug("_G.arg:%s", vim.inspect(_G.arg))
local registry_id = _G.arg[1]
local params = nil
if #_G.arg >= 2 then
  params = _G.arg[2]
end
-- shell_helpers.log_debug("SOCKET_ADDRESS:%s", vim.inspect(SOCKET_ADDRESS))
-- shell_helpers.log_debug("registry_id:%s", vim.inspect(registry_id))
-- shell_helpers.log_debug("params:%s", vim.inspect(params))

local channel_id = vim.fn.sockconnect("pipe", SOCKET_ADDRESS, { rpc = true })
-- shell_helpers.log_debug("channel_id:%s", vim.inspect(channel_id))
-- shell_helpers.log_ensure(
--   channel_id > 0,
--   "error! failed to connect socket on SOCKET_ADDRESS:%s",
--   vim.inspect(SOCKET_ADDRESS)
-- )
vim.rpcrequest(
  channel_id,
  "nvim_exec_lua",
  ---@diagnostic disable-next-line: param-type-mismatch
  [[
    local luaargs = {...}
    local registry_id = luaargs[1]
    local params = nil
    if #luaargs >= 2 then
        params = luaargs[2]
    end
    local cb = require("fzfx.detail.rpcserver").get_instance():get(registry_id)
    cb(params)
    ]],
  params == nil and { registry_id } or { registry_id, params }
)
vim.fn.chanclose(channel_id)
