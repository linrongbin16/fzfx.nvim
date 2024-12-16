local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
  io.write(string.format("|bin.provider| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)

local str = require("fzfx.commons.str")
local tbl = require("fzfx.commons.tbl")
local fileio = require("fzfx.commons.fileio")
local spawn = require("fzfx.commons.spawn")
local schema = require("fzfx.schema")
local shell_helpers = require("fzfx.detail.shell_helpers")
shell_helpers.setup("provider")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_RPC_SERVER_ADDRESS
shell_helpers.log_ensure(str.not_empty(SOCKET_ADDRESS), "SOCKET_ADDRESS must not be empty!")
local registry_id = _G.arg[1]
local metafile = _G.arg[2]
local resultfile = _G.arg[3]
local query = _G.arg[4]
-- shell_helpers.log_debug("registry_id:[%s]", registry_id)
-- shell_helpers.log_debug("metafile:[%s]", metafile)
-- shell_helpers.log_debug("resultfile:[%s]", resultfile)
-- shell_helpers.log_debug("query:[%s]", query)

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
    local query = luaargs[2]
    local cb = require("fzfx.detail.rpcserver").get_instance():get(registry_id)
    return cb(query)
    ]],
  {
    registry_id,
    query,
  }
)
vim.fn.chanclose(channel_id)

local metajsonstring = fileio.readfile(metafile, { trim = true }) --[[@as string]]
shell_helpers.log_ensure(
  str.not_empty(metajsonstring),
  "metajsonstring is not string:" .. vim.inspect(metajsonstring)
)
--- @type fzfx.ProviderMetaOpts
local metaopts = vim.json.decode(metajsonstring) --[[@as fzfx.ProviderMetaOpts]]
-- shell_helpers.log_debug("metaopt:[%s]", vim.inspect(metaopts))

-- decorator

vim.opt.runtimepath:append(vim.fn.stdpath("config"))

--- @type {decorate:fun(line:string):string}
local decorator_module = nil
if metaopts.provider_decorator ~= nil then
  if str.not_empty(tbl.tbl_get(metaopts.provider_decorator, "rtp")) then
    vim.opt.runtimepath:append(tbl.tbl_get(metaopts.provider_decorator, "rtp"))
  end
  shell_helpers.log_ensure(
    str.not_empty(tbl.tbl_get(metaopts.provider_decorator, "module")),
    "decorator module cannot be empty:" .. vim.inspect(metaopts.provider_decorator)
  )
  local module_name = metaopts.provider_decorator.module
  local ok, module_or_err = pcall(require, module_name)
  shell_helpers.log_ensure(
    ok and tbl.tbl_not_empty(module_or_err),
    string.format(
      "failed to load decorator:%s, error:%s",
      vim.inspect(metaopts.provider_decorator),
      vim.inspect(module_or_err)
    )
  )
  decorator_module = module_or_err
end

--- @param line string?
local function println(line)
  if str.empty(line) then
    return
  end
  line = str.rtrim(line --[[@as string]])
  if tbl.tbl_not_empty(decorator_module) then
    -- shell_helpers.log_debug("decorate line:%s", vim.inspect(line))
    vim.schedule(function()
      local rendered_ok, rendered_line_or_err = pcall(decorator_module.decorate, line)
      if rendered_ok then
        io.write(string.format("%s\n", rendered_line_or_err))
      else
        shell_helpers.log_err(
          string.format(
            "failed to render line with decorator:%s, error:%s",
            vim.inspect(decorator_module),
            vim.inspect(rendered_line_or_err)
          )
        )
      end
    end)
  else
    io.write(string.format("%s\n", line))
  end
end

local ProviderTypeEnum = schema.ProviderTypeEnum
if
  metaopts.provider_type == ProviderTypeEnum.PLAIN_COMMAND_STRING
  or metaopts.provider_type == ProviderTypeEnum.FUNCTIONAL_COMMAND_STRING
then
  --- @type string
  local cmd = fileio.readfile(resultfile, { trim = true }) --[[@as string]]
  -- shell_helpers.log_debug("plain/command cmd:%s", vim.inspect(cmd))
  if str.empty(cmd) then
    os.exit(0)
    return
  end

  local p = io.popen(cmd)
  shell_helpers.log_ensure(p ~= nil, "failed to open pipe on command:" .. vim.inspect(cmd))
  ---@diagnostic disable-next-line: need-check-nil
  for line in p:lines("*line") do
    println(line)
  end
  ---@diagnostic disable-next-line: need-check-nil
  p:close()
elseif
  metaopts.provider_type == ProviderTypeEnum.PLAIN_COMMAND_ARRAY
  or metaopts.provider_type == ProviderTypeEnum.FUNCTIONAL_COMMAND_ARRAY
then
  local cmd = fileio.readfile(resultfile, { trim = true }) --[[@as string]]
  -- shell_helpers.log_debug("plain_list/command_list cmd:%s", vim.inspect(cmd))
  if str.empty(cmd) then
    os.exit(0)
    return
  end

  local cmd_splits = vim.json.decode(cmd) --[[@as table]]
  if tbl.tbl_empty(cmd_splits) then
    os.exit(0)
    return
  end

  local sp = spawn.run(cmd_splits, { on_stdout = println, on_stderr = function() end }) --[[@as vim.SystemObj]]
  shell_helpers.log_ensure(sp ~= nil, "failed to run command:" .. vim.inspect(cmd_splits))
  sp:wait()
elseif metaopts.provider_type == ProviderTypeEnum.DIRECT then
  local reader = fileio.FileLineReader:open(resultfile) --[[@as commons.FileLineReader ]]
  shell_helpers.log_ensure(reader ~= nil, "failed to open resultfile:" .. vim.inspect(resultfile))

  while reader:has_next() do
    local line = reader:next()
    println(line)
  end
  reader:close()
else
  shell_helpers.log_throw("unknown provider meta:" .. vim.inspect(metajsonstring))
end
