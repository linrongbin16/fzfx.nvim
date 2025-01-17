local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
  io.write(string.format("|bin.rpcnotify| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)

local str = require("fzfx.commons.str")
local child_process_helpers = require("fzfx.detail.child_process_helpers")
child_process_helpers.setup("rpcnotify")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_RPC_SERVER_ADDRESS
child_process_helpers.log_ensure(
  str.not_empty(SOCKET_ADDRESS),
  "error! SOCKET_ADDRESS must not be empty!"
)
local registry_id = _G.arg[1]
local params = nil
if #_G.arg >= 2 then
  params = _G.arg[2]
end
-- child_process_helpers.log_debug("SOCKET_ADDRESS:%s", vim.inspect(SOCKET_ADDRESS))
-- child_process_helpers.log_debug("registry_id:%s", vim.inspect(registry_id))
-- child_process_helpers.log_debug("params:%s", vim.inspect(params))

local channel_id = vim.fn.sockconnect("pipe", SOCKET_ADDRESS, { rpc = true })
-- child_process_helpers.log_debug("channel_id:%s", vim.inspect(channel_id))
-- child_process_helpers.log_ensure(
--   channel_id > 0,
--   "error! failed to connect socket on SOCKET_ADDRESS:%s",
--   vim.inspect(SOCKET_ADDRESS)
-- )
vim.rpcnotify(
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
