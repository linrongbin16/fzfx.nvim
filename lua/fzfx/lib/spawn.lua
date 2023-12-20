local strs = require("fzfx.lib.strings")
local numbers = require("fzfx.commons.numbers")
local uv = (vim.fn.has("nvim-0.10") > 0 and vim.uv ~= nil) and vim.uv
  or vim.loop

local M = {}

--- @alias fzfx.SpawnLineProcessor fun(line:string):any
--- @alias fzfx.SpawnOnStdout fzfx.SpawnLineProcessor
--- @alias fzfx.SpawnOnStderr fzfx.SpawnLineProcessor
--- @alias fzfx.SpawnOnExit fun(code:integer?,signal:integer?):any
--- @class fzfx.Spawn
--- @field cmds string[]
--- @field fn_on_exit fzfx.SpawnOnExit
--- @field result {code:integer?,signal:integer?}?
--- @field fn_on_stdout fzfx.SpawnOnStdout
--- @field fn_on_stderr fzfx.SpawnOnStderr
--- @field out_pipe uv_pipe_t
--- @field err_pipe uv_pipe_t
--- @field out_buffer string?
--- @field err_buffer string?
--- @field process_handle uv_process_t?
--- @field process_id integer|string|nil
--- @field _close_count integer
--- @field _blocking boolean
local Spawn = {}

--- @param cmds string[]
--- @param opts {on_stdout:fzfx.SpawnOnStdout,on_stderr:fzfx.SpawnOnStderr?,on_exit:fzfx.SpawnOnExit?,blocking:boolean}
--- @return fzfx.Spawn
function Spawn:make(cmds, opts)
  assert(type(opts) == "table")
  assert(type(opts.on_stdout) == "function")
  assert(type(opts.on_stderr) == "function" or opts.on_stderr == nil)
  assert(type(opts.on_exit) == "function" or opts.on_exit == nil)
  assert(type(opts.blocking) == "boolean")

  local out_pipe = uv.new_pipe(false) --[[@as uv_pipe_t]]
  local err_pipe = uv.new_pipe(false) --[[@as uv_pipe_t]]
  assert(out_pipe ~= nil)
  assert(err_pipe ~= nil)

  local o = {
    cmds = cmds,
    fn_on_exit = opts.on_exit,
    result = nil,
    fn_on_stdout = opts.on_stdout,
    fn_on_stderr = opts.on_stderr or function() end,
    out_pipe = out_pipe,
    err_pipe = err_pipe,
    out_buffer = nil,
    err_buffer = nil,
    process_handle = nil,
    process_id = nil,
    _close_count = 0,
    _blocking = opts.blocking,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param buffer string
--- @param fn_line_processor fzfx.SpawnLineProcessor
--- @return integer
function Spawn:_consume_line(buffer, fn_line_processor)
  local i = 1
  while i <= #buffer do
    local newline_pos = strs.find(buffer, "\n", i)
    if not newline_pos then
      break
    end
    local line = buffer:sub(i, newline_pos - 1)
    fn_line_processor(line)
    i = newline_pos + 1
  end
  return i
end

--- @param handle uv_handle_t
--- @param code integer?
--- @param signal integer?
function Spawn:_close_handle(handle, code, signal)
  if handle and not handle:is_closing() then
    handle:close(function()
      self._close_count = self._close_count + 1
      if self._blocking and self._close_count >= 3 then
        uv.stop()
      end
    end)
  end
end

--- @param err string?
--- @param data string?
function Spawn:_on_stdout(err, data)
  if err then
    self.out_pipe:read_stop()
    self:_close_handle(self.out_pipe)
    return
  end

  if data then
    -- append data to data_buffer
    self.out_buffer = self.out_buffer and (self.out_buffer .. data) or data
    self.out_buffer = self.out_buffer:gsub("\r\n", "\n")
    -- foreach the data_buffer and find every line
    local i = self:_consume_line(self.out_buffer, self.fn_on_stdout)
    -- truncate the printed lines if found any
    self.out_buffer = i <= #self.out_buffer
        and self.out_buffer:sub(i, #self.out_buffer)
      or nil
  else
    if self.out_buffer then
      -- foreach the data_buffer and find every line
      local i = self:_consume_line(self.out_buffer, self.fn_on_stdout)
      if i <= #self.out_buffer then
        local line = self.out_buffer:sub(i, #self.out_buffer)
        self.fn_on_stdout(line)
        self.out_buffer = nil
      end
    end
    self.out_pipe:read_stop()
    self:_close_handle(self.out_pipe)
  end
end

--- @param err string?
--- @param data string?
function Spawn:_on_stderr(err, data)
  if err then
    io.write(
      string.format(
        "Spawn:_on_stderr, err:%s, data:%s",
        vim.inspect(err),
        vim.inspect(data)
      )
    )
    error(
      string.format(
        "Spawn:_on_stderr, err:%s, data:%s",
        vim.inspect(err),
        vim.inspect(data)
      )
    )
    self.err_pipe:read_stop()
    self:_close_handle(self.err_pipe)
    return
  end

  if data then
    -- append data to data_buffer
    self.err_buffer = self.err_buffer and (self.err_buffer .. data) or data
    self.err_buffer = self.err_buffer:gsub("\r\n", "\n")
    -- foreach the data_buffer and find every line
    local i = self:_consume_line(self.err_buffer, self.fn_on_stderr)
    -- truncate the printed lines if found any
    self.err_buffer = i <= #self.err_buffer
        and self.err_buffer:sub(i, #self.err_buffer)
      or nil
  else
    if self.err_buffer then
      -- foreach the data_buffer and find every line
      local i = self:_consume_line(self.err_buffer, self.fn_on_stderr)
      if i <= #self.err_buffer then
        local line = self.err_buffer:sub(i, #self.err_buffer)
        self.fn_on_stderr(line)
        self.err_buffer = nil
      end
    end
    self.err_pipe:read_stop()
    self:_close_handle(self.err_pipe)
  end
end

function Spawn:run()
  self.process_handle, self.process_id = uv.spawn(self.cmds[1], {
    args = vim.list_slice(self.cmds, 2),
    stdio = { nil, self.out_pipe, self.err_pipe },
    hide = true,
  }, function(code, signal)
    self.result = { code = code, signal = signal }
    if type(self.fn_on_exit) == "function" then
      self.fn_on_exit(code, signal)
    end
    self:_close_handle(self.process_handle, code, signal)
  end)

  self.out_pipe:read_start(function(err, data)
    self:_on_stdout(err, data)
  end)
  self.err_pipe:read_start(function(err, data)
    self:_on_stderr(err, data)
  end)
  if self._blocking then
    uv.run()
    vim.wait(numbers.INT32_MAX, function()
      return self._close_count == 3
    end)
  end
end

M.Spawn = Spawn

return M
