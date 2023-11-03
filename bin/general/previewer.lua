local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
  io.write(
    string.format("|fzfx.bin.general.previewer| error! SELF_PATH is empty!")
  )
end
vim.opt.runtimepath:append(SELF_PATH)
local shell_helpers = require("fzfx.shell_helpers")
shell_helpers.setup("previewer")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_SOCKET_ADDRESS
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
    return require("fzfx.rpc_helpers").call(registry_id, line)
    ]],
  {
    registry_id,
    line,
  }
)
vim.fn.chanclose(channel_id)

local metajsonstring = shell_helpers.readfile(metafile) --[[@as string]]
shell_helpers.log_ensure(
  type(metajsonstring) == "string" and string.len(metajsonstring) > 0,
  "metajsonstring is not string! %s",
  vim.inspect(metajsonstring)
)
local metaopts = vim.fn.json_decode(metajsonstring) --[[@as PreviewerMetaOpts]]
shell_helpers.log_debug("metaopts:[%s]", vim.inspect(metaopts))

--- @param l string?
local function println(l)
  if type(l) == "string" and string.len(vim.trim(l)) > 0 then
    l = shell_helpers.string_rtrim(l)
    io.write(string.format("%s\n", l))
  end
end

if metaopts.previewer_type == "command" then
  local cmd = shell_helpers.readfile(resultfile)
  shell_helpers.log_debug("cmd:%s", vim.inspect(cmd))
  if cmd == nil or string.len(cmd) == 0 then
    os.exit(0)
  else
    os.execute(cmd)
  end
elseif metaopts.previewer_type == "command_list" then
  local cmd = shell_helpers.readfile(resultfile)
  shell_helpers.log_debug("cmd:%s", vim.inspect(cmd))
  if cmd == nil or string.len(cmd) == 0 then
    os.exit(0)
    return
  end
  local cmd_splits = vim.fn.json_decode(cmd)
  if type(cmd_splits) ~= "table" or vim.tbl_isempty(cmd_splits) then
    os.exit(0)
    return
  end

  local sp = shell_helpers.Spawn:make(cmd_splits, println) --[[@as Spawn]]
  shell_helpers.log_ensure(
    sp ~= nil,
    "failed to open async command: %s",
    vim.inspect(cmd_splits)
  )
  sp:run()
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
  shell_helpers.log_throw(
    "unknown previewer type:%s",
    vim.inspect(metajsonstring)
  )
end
