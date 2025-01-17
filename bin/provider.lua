local SELF_PATH = vim.env._FZFX_NVIM_SELF_PATH
if type(SELF_PATH) ~= "string" or string.len(SELF_PATH) == 0 then
  io.write(string.format("|bin.provider| error! SELF_PATH is empty!"))
end
vim.opt.runtimepath:append(SELF_PATH)

local str = require("fzfx.commons.str")
local tbl = require("fzfx.commons.tbl")
local fio = require("fzfx.commons.fio")
local spawn = require("fzfx.commons.spawn")
local schema = require("fzfx.schema")
local uv = require("fzfx.commons.uv")
local child_process_helpers = require("fzfx.detail.child_process_helpers")
child_process_helpers.setup("provider")

local SOCKET_ADDRESS = vim.env._FZFX_NVIM_RPC_SERVER_ADDRESS
child_process_helpers.log_ensure(str.not_empty(SOCKET_ADDRESS), "SOCKET_ADDRESS must not be empty!")
local registry_id = _G.arg[1]
local metafile = _G.arg[2]
local resultfile = _G.arg[3]
local donefile = _G.arg[4]
local query = _G.arg[5]
-- child_process_helpers.log_debug("registry_id:[%s]", registry_id)
-- child_process_helpers.log_debug("metafile:[%s]", metafile)
-- child_process_helpers.log_debug("resultfile:[%s]", resultfile)
-- child_process_helpers.log_debug("query:[%s]", query)

local channel_id = vim.fn.sockconnect("pipe", SOCKET_ADDRESS, { rpc = true })
-- child_process_helpers.log_debug("channel_id:%s", vim.inspect(channel_id))
-- child_process_helpers.log_ensure(
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

local metajsonstring = fio.readfile(metafile, { trim = true }) --[[@as string]]
child_process_helpers.log_ensure(
  str.not_empty(metajsonstring),
  "metajsonstring is not string:" .. vim.inspect(metajsonstring)
)
--- @type fzfx.ProviderMetaOpts
local metaopts = vim.json.decode(metajsonstring) --[[@as fzfx.ProviderMetaOpts]]
-- child_process_helpers.log_debug("metaopt:[%s]", vim.inspect(metaopts))

-- decorator

vim.opt.runtimepath:append(vim.fn.stdpath("config"))

--- @type {decorate:fun(line:string):string}
local decorator_module = nil
if metaopts.provider_decorator ~= nil then
  if str.not_empty(tbl.tbl_get(metaopts.provider_decorator, "rtp")) then
    vim.opt.runtimepath:append(tbl.tbl_get(metaopts.provider_decorator, "rtp"))
  end
  child_process_helpers.log_ensure(
    str.not_empty(tbl.tbl_get(metaopts.provider_decorator, "module")),
    "decorator module cannot be empty:" .. vim.inspect(metaopts.provider_decorator)
  )
  local module_name = metaopts.provider_decorator.module
  local ok, module_or_err = pcall(require, module_name)
  child_process_helpers.log_ensure(
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
    -- child_process_helpers.log_debug("decorate line:%s", vim.inspect(line))
    vim.schedule(function()
      local rendered_ok, rendered_line_or_err = pcall(decorator_module.decorate, line)
      if rendered_ok then
        io.write(string.format("%s\n", rendered_line_or_err))
      else
        child_process_helpers.log_err(
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

local function direct_print()
  local reader = fio.FileLineReader:open(resultfile) --[[@as commons.FileLineReader ]]
  child_process_helpers.log_ensure(
    reader ~= nil,
    "failed to open resultfile:" .. vim.inspect(resultfile)
  )

  while reader:has_next() do
    local line = reader:next()
    println(line)
  end
  reader:close()
end

local ProviderTypeEnum = schema.ProviderTypeEnum
if metaopts.provider_type == ProviderTypeEnum.COMMAND_STRING then
  --- @type string
  local cmd = fio.readfile(resultfile, { trim = true }) --[[@as string]]
  -- child_process_helpers.log_debug("plain/command cmd:%s", vim.inspect(cmd))
  if str.empty(cmd) then
    os.exit(0)
    return
  end

  local p = io.popen(cmd)
  child_process_helpers.log_ensure(p ~= nil, "failed to open pipe on command:" .. vim.inspect(cmd))
  ---@diagnostic disable-next-line: need-check-nil
  for line in p:lines("*line") do
    println(line)
  end
  ---@diagnostic disable-next-line: need-check-nil
  p:close()
elseif metaopts.provider_type == ProviderTypeEnum.COMMAND_ARRAY then
  local cmd = fio.readfile(resultfile, { trim = true }) --[[@as string]]
  -- child_process_helpers.log_debug("plain_list/command_list cmd:%s", vim.inspect(cmd))
  if str.empty(cmd) then
    os.exit(0)
    return
  end

  local cmd_splits = vim.json.decode(cmd) --[[@as table]]
  if tbl.tbl_empty(cmd_splits) then
    os.exit(0)
    return
  end

  local job = spawn.waitable(cmd_splits, { on_stdout = println, on_stderr = function() end })
  child_process_helpers.log_ensure(job ~= nil, "failed to run command:" .. vim.inspect(cmd_splits))
  local _ = spawn.wait(job)
elseif metaopts.provider_type == ProviderTypeEnum.DIRECT then
  local reader = fio.FileLineReader:open(resultfile) --[[@as commons.FileLineReader ]]
  child_process_helpers.log_ensure(
    reader ~= nil,
    "failed to open resultfile:" .. vim.inspect(resultfile)
  )

  while reader:has_next() do
    local line = reader:next()
    println(line)
  end
  reader:close()
elseif metaopts.provider_type == ProviderTypeEnum.ASYNC_DIRECT then
  ---@diagnostic disable-next-line: undefined-field
  local done_fsevent, done_fsevent_err = uv.new_fs_event()
  child_process_helpers.log_ensure(
    done_fsevent ~= nil,
    "failed to create fs_event on donefile:"
      .. vim.inspect(donefile)
      .. ", err:"
      .. vim.inspect(done_fsevent_err)
  )

  local is_done = false
  local done_fsevent_start, done_fsevent_start_err = done_fsevent:start(
    donefile,
    {},
    function(err1, donefile1, events1)
      if err1 then
        child_process_helpers.log_err(
          string.format(
            "failed to start fsevent on donefile:%s, error:%s",
            vim.inspect(donefile),
            vim.inspect(err1)
          )
        )
        return
      end

      if not str.find(donefile, donefile1) then
        return
      end

      local done = fio.readfile(donefile1)
      if done == "done" then
        -- Now the resultfile is ready, start println.
        direct_print()

        done_fsevent:stop()
        is_done = true
      end
    end
  )
  child_process_helpers.log_ensure(
    done_fsevent_start ~= nil,
    "failed to start fs_event on donefile:"
      .. vim.inspect(donefile)
      .. ", err:"
      .. vim.inspect(done_fsevent_start_err)
  )

  local function runloop()
    vim.defer_fn(function()
      if not is_done then
        runloop()
      end
    end, 1)
  end

  -- Wait until done.
  runloop()

  -- direct_print()
else
  child_process_helpers.log_throw("unknown provider meta:" .. vim.inspect(metajsonstring))
end
