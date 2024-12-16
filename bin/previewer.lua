local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
  io.write(string.format("|bin.previewer| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)

local str = require("fzfx.commons.str")
local tbl = require("fzfx.commons.tbl")
local fileio = require("fzfx.commons.fileio")
local spawn = require("fzfx.commons.spawn")
local schema = require("fzfx.schema")
local shell_helpers = require("fzfx.detail.shell_helpers")
shell_helpers.setup("previewer")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_RPC_SERVER_ADDRESS
shell_helpers.log_ensure(str.not_empty(SOCKET_ADDRESS), "SOCKET_ADDRESS must not be empty!")
local registry_id = _G.arg[1]
local metafile = _G.arg[2]
local resultfile = _G.arg[3]
local line = nil
if #_G.arg >= 4 then
  line = _G.arg[4]
end
-- shell_helpers.log_debug("registry_id:" .. vim.inspect(registry_id))
-- shell_helpers.log_debug("metafile:" .. vim.inspect(metafile))
-- shell_helpers.log_debug("resultfile:" .. vim.inspect(resultfile))
-- shell_helpers.log_debug("line:" .. vim.inspect(line))

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

local metajsonstring = fileio.readfile(metafile, { trim = true }) --[[@as string]]
shell_helpers.log_ensure(
  str.not_empty(metajsonstring),
  "metajsonstring is not string! " .. vim.inspect(metajsonstring)
)
local metaopts = vim.json.decode(metajsonstring) --[[@as fzfx.PreviewerMetaOpts]]
shell_helpers.log_debug("metaopts:" .. vim.inspect(metaopts))

--- @param l string?
local function println(l)
  if type(l) == "string" and string.len(vim.trim(l)) > 0 then
    l = str.rtrim(l)
    io.write(string.format("%s\n", l))
  end
end

local PreviewerTypeEnum = schema.PreviewerTypeEnum
if metaopts.previewer_type == PreviewerTypeEnum.FUNCTIONAL_COMMAND_STRING then
  local cmd = fileio.readfile(resultfile, { trim = true })
  shell_helpers.log_debug("cmd:" .. vim.inspect(cmd))
  if str.empty(cmd) then
    os.exit(0)
  else
    os.execute(cmd)
  end
elseif metaopts.previewer_type == PreviewerTypeEnum.FUNCTIONAL_COMMAND_ARRAY then
  local cmd = fileio.readfile(resultfile, { trim = true })
  shell_helpers.log_debug("cmd:" .. vim.inspect(cmd))
  if str.empty(cmd) then
    os.exit(0)
    return
  end
  local cmd_splits = vim.json.decode(cmd) --[[ @as string[] ]]
  if tbl.tbl_empty(cmd_splits) then
    os.exit(0)
    return
  end

  local sp = spawn.run(cmd_splits, { on_stdout = println, on_stderr = function() end })
  shell_helpers.log_ensure(sp ~= nil, "failed to run command:" .. vim.inspect(cmd_splits))
  sp:wait()
else
  shell_helpers.log_throw("unknown previewer meta:" .. vim.inspect(metajsonstring))
end
