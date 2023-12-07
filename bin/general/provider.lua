local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
  io.write(string.format("|provider| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)

local tbls = require("fzfx.lib.tables")
local fs = require("fzfx.lib.filesystems")
local jsons = require("fzfx.lib.jsons")
local strs = require("fzfx.lib.strings")
local spawn = require("fzfx.lib.spawn")
local shell_helpers = require("fzfx.detail.shell_helpers")
shell_helpers.setup("provider")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_RPC_SERVER_ADDRESS
shell_helpers.log_ensure(
  type(SOCKET_ADDRESS) == "string" and string.len(SOCKET_ADDRESS) > 0,
  "SOCKET_ADDRESS must not be empty!"
)
local registry_id = _G.arg[1]
local metafile = _G.arg[2]
local resultfile = _G.arg[3]
local query = _G.arg[4]
shell_helpers.log_debug("registry_id:[%s]", registry_id)
shell_helpers.log_debug("metafile:[%s]", metafile)
shell_helpers.log_debug("resultfile:[%s]", resultfile)
shell_helpers.log_debug("query:[%s]", query)

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

local metajsonstring = fs.readfile(metafile) --[[@as string]]
shell_helpers.log_ensure(
  type(metajsonstring) == "string" and string.len(metajsonstring) > 0,
  "metajsonstring is not string! %s",
  vim.inspect(metajsonstring)
)
--- @type fzfx.ProviderMetaOpts
local metaopts = jsons.decode(metajsonstring) --[[@as fzfx.ProviderMetaOpts]]
shell_helpers.log_debug("metaopt:[%s]", vim.inspect(metaopts))

-- decorator

vim.opt.runtimepath:append(vim.fn.stdpath("config"))

--- @type {decorate:fun(line:string):string}
local decorator_module = nil
if metaopts.provider_decorator ~= nil then
  if strs.not_empty(tbls.tbl_get(metaopts.provider_decorator, "rtp")) then
    vim.opt.runtimepath:append(tbls.tbl_get(metaopts.provider_decorator, "rtp"))
  end
  shell_helpers.log_ensure(
    strs.not_empty(tbls.tbl_get(metaopts.provider_decorator, "module")),
    "decorator module cannot be empty: %s",
    vim.inspect(metaopts.provider_decorator)
  )
  local module_name = metaopts.provider_decorator.module
  if metaopts.provider_decorator.builtin then
    module_name = "fzfx.helper.provider_decorators." .. module_name
  end
  local ok, module_or_err = pcall(require, module_name)
  shell_helpers.log_ensure(
    ok and tbls.tbl_not_empty(module_or_err),
    "failed to load decorator:%s, error:%s",
    vim.inspect(metaopts.provider_decorator),
    vim.inspect(module_or_err)
  )
  decorator_module = module_or_err
end

--- @param line string?
local function println(line)
  if strs.empty(line) then
    return
  end
  line = strs.rtrim(line --[[@as string]])
  if metaopts.prepend_icon_by_ft then
    local rendered_line = shell_helpers.prepend_path_with_icon(
      line,
      metaopts.prepend_icon_path_delimiter,
      metaopts.prepend_icon_path_position
    )
    io.write(string.format("%s\n", rendered_line))
  elseif tbls.tbl_not_empty(decorator_module) then
    vim.schedule(function()
      local rendered_ok, rendered_line_or_err =
        pcall(decorator_module.decorate, line)
      if rendered_ok then
        io.write(string.format("%s\n", rendered_line_or_err))
      else
        shell_helpers.log_err(
          "failed to render line with decorator:%s, error:%s",
          vim.inspect(decorator_module),
          vim.inspect(rendered_line_or_err)
        )
      end
    end)
  else
    io.write(string.format("%s\n", line))
  end
end

if metaopts.provider_type == "plain" or metaopts.provider_type == "command" then
  --- @type string
  local cmd = fs.readfile(resultfile) --[[@as string]]
  shell_helpers.log_debug("plain/command cmd:%s", vim.inspect(cmd))
  if cmd == nil or string.len(cmd) == 0 then
    os.exit(0)
    return
  end

  local p = io.popen(cmd)
  shell_helpers.log_ensure(
    p ~= nil,
    "failed to open pipe on provider cmd! %s",
    vim.inspect(cmd)
  )
  ---@diagnostic disable-next-line: need-check-nil
  for line in p:lines("*line") do
    println(line)
  end
  ---@diagnostic disable-next-line: need-check-nil
  p:close()
elseif
  metaopts.provider_type == "plain_list"
  or metaopts.provider_type == "command_list"
then
  local cmd = fs.readfile(resultfile) --[[@as string]]
  shell_helpers.log_debug("plain_list/command_list cmd:%s", vim.inspect(cmd))
  if cmd == nil or string.len(cmd) == 0 then
    os.exit(0)
    return
  end

  local cmd_splits = jsons.decode(cmd) --[[@as table]]
  if tbls.tbl_empty(cmd_splits) then
    os.exit(0)
    return
  end

  local sp =
    spawn.Spawn:make(cmd_splits, { on_stdout = println, blocking = true })
  shell_helpers.log_ensure(
    sp ~= nil,
    "failed to open async command: %s",
    vim.inspect(cmd_splits)
  )
  sp:run()
elseif metaopts.provider_type == "list" then
  local reader = fs.FileLineReader:open(resultfile) --[[@as fzfx.FileLineReader ]]
  shell_helpers.log_ensure(
    reader ~= nil,
    "failed to open resultfile: %s",
    vim.inspect(resultfile)
  )

  while reader:has_next() do
    local line = reader:next()
    println(line)
  end
  reader:close()
else
  shell_helpers.log_throw(
    "unknown provider type:%s",
    vim.inspect(metajsonstring)
  )
end
