local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
  io.write(string.format("|fzfx.bin.general.previewer| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)

local tables = require("fzfx.commons.tables")
local fileios = require("fzfx.commons.fileios")
local jsons = require("fzfx.commons.jsons")
local strings = require("fzfx.commons.strings")
local spawn = require("fzfx.commons.spawn")
local shell_helpers = require("fzfx.detail.shell_helpers")
shell_helpers.setup("previewer")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_RPC_SERVER_ADDRESS
shell_helpers.log_ensure(
  type(SOCKET_ADDRESS) == "string" and string.len(SOCKET_ADDRESS) > 0,
  "SOCKET_ADDRESS must not be empty!"
)
local registry_id = _G.arg[1]
local metafile = _G.arg[2]
local resultfile = _G.arg[3]
local line = nil
if #_G.arg >= 4 then
  line = _G.arg[4]
end
shell_helpers.log_debug("registry_id:[%s]", registry_id)
shell_helpers.log_debug("metafile:[%s]", metafile)
shell_helpers.log_debug("resultfile:[%s]", resultfile)
shell_helpers.log_debug("line:[%s]", vim.inspect(line))

local channel_id = vim.fn.sockconnect("pipe", SOCKET_ADDRESS, { rpc = true })
-- shell_helpers.log_debug("channel_id:%s", vim.inspect(channel_id))
-- shell_helpers.log_ensure(
--     channel_id > 0,
--     "failed to connect socket on SOCKET_ADDRESS:%s",
--     vim.inspect(SOCKET_ADDRESS)
-- )
vim.rpcrequest(
  channel_id,
  "nvim_exec_lua",
  ---@diagnostic disable-next-line: param-type-mismatch
  [[
    local luaargs = {...}
    local registry_id = luaargs[1]
    local line = luaargs[2]
    local cb = require("fzfx.detail.rpcserver").get_instance():get(registry_id)
    return cb(line)
    ]],
  {
    registry_id,
    line,
  }
)
vim.fn.chanclose(channel_id)

local metajsonstring = fileios.readfile(metafile, { trim = true }) --[[@as string]]
shell_helpers.log_ensure(
  type(metajsonstring) == "string" and string.len(metajsonstring) > 0,
  "metajsonstring is not string! %s",
  vim.inspect(metajsonstring)
)
local metaopts = jsons.decode(metajsonstring) --[[@as fzfx.PreviewerMetaOpts]]
shell_helpers.log_debug("metaopts:[%s]", vim.inspect(metaopts))

--- @param l string?
local function println(l)
  if type(l) == "string" and string.len(vim.trim(l)) > 0 then
    l = strings.rtrim(l)
    io.write(string.format("%s\n", l))
  end
end

if metaopts.previewer_type == "command" then
  local cmd = fileios.readfile(resultfile, { trim = true })
  shell_helpers.log_debug("cmd:%s", vim.inspect(cmd))
  if strings.empty(cmd) then
    os.exit(0)
  else
    os.execute(cmd)
  end
elseif metaopts.previewer_type == "command_list" then
  local cmd = fileios.readfile(resultfile, { trim = true })
  shell_helpers.log_debug("cmd:%s", vim.inspect(cmd))
  if strings.empty(cmd) then
    os.exit(0)
    return
  end
  local cmd_splits = jsons.decode(cmd) --[[ @as string[] ]]
  if tables.tbl_empty(cmd_splits) then
    os.exit(0)
    return
  end

  local sp = spawn.run(cmd_splits, { on_stdout = println, on_stderr = function() end })
  shell_helpers.log_ensure(sp ~= nil, "failed to open async command: %s", vim.inspect(cmd_splits))
  sp:wait()
elseif metaopts.previewer_type == "list" then
  local f = io.open(resultfile, "r")
  shell_helpers.log_ensure(
    f ~= nil,
    "failed to open file on resultfile! %s",
    vim.inspect(resultfile)
  )
  --- @diagnostic disable-next-line: need-check-nil
  for l in f:lines("*line") do
    shell_helpers.log_debug("list:[%s]", l)
    io.write(string.format("%s\n", l))
  end
  --- @diagnostic disable-next-line: need-check-nil
  f:close()
else
  shell_helpers.log_throw("unknown previewer type:%s", vim.inspect(metajsonstring))
end
