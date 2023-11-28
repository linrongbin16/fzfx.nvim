local strs = require("fzfx.lib.strings")
local numbers = require("fzfx.lib.numbers")
local uv = (vim.fn.has("nvim-0.10") > 0 and vim.uv ~= nil) and vim.ui
  or vim.loop

local M = {}

--- @alias fzfx.SpawnLineConsumer fun(line:string):any
--- @class fzfx._Spawn
--- @field cmds string[]
--- @field fn_out_line_consumer fzfx.SpawnLineConsumer
--- @field fn_err_line_consumer fzfx.SpawnLineConsumer
--- @field out_pipe uv_pipe_t
--- @field err_pipe uv_pipe_t
--- @field out_buffer string?
--- @field err_buffer string?
--- @field process_handle uv_process_t?
--- @field process_id integer|string|nil
--- @field _close_count integer
--- @field result {code:integer?,signal:integer?}?
--- @field _blocking boolean
local _Spawn = {}

--- @param cmds string[]
--- @param fn_out_line_consumer fzfx.SpawnLineConsumer
--- @param fn_err_line_consumer fzfx.SpawnLineConsumer
--- @param blocking boolean?
--- @return fzfx._Spawn?
function _Spawn:make(cmds, fn_out_line_consumer, fn_err_line_consumer, blocking)
  local out_pipe = uv.new_pipe(false) --[[@as uv_pipe_t]]
  local err_pipe = uv.new_pipe(false) --[[@as uv_pipe_t]]
  if not out_pipe or not err_pipe then
    return nil
  end

  local o = {
    cmds = cmds,
    fn_out_line_consumer = fn_out_line_consumer,
    fn_err_line_consumer = fn_err_line_consumer,
    out_pipe = out_pipe,
    err_pipe = err_pipe,
    out_buffer = nil,
    err_buffer = nil,
    process_handle = nil,
    process_id = nil,
    _close_count = 0,
    result = nil,
    _blocking = type(blocking) == "boolean" and blocking or true,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param buffer string
--- @param fn_line_processor fzfx.SpawnLineConsumer
--- @return integer
function _Spawn:_consume_line(buffer, fn_line_processor)
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
function _Spawn:_close_handle(handle)
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
function _Spawn:_on_stdout(err, data)
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
    local i = self:_consume_line(self.out_buffer, self.fn_out_line_consumer)
    -- truncate the printed lines if found any
    self.out_buffer = i <= #self.out_buffer
        and self.out_buffer:sub(i, #self.out_buffer)
      or nil
  else
    if self.out_buffer then
      -- foreach the data_buffer and find every line
      local i = self:_consume_line(self.out_buffer, self.fn_out_line_consumer)
      if i <= #self.out_buffer then
        local line = self.out_buffer:sub(i, #self.out_buffer)
        self.fn_out_line_consumer(line)
        self.out_buffer = nil
      end
    end
    self.out_pipe:read_stop()
    self:_close_handle(self.out_pipe)
  end
end

--- @param err string?
--- @param data string?
function _Spawn:_on_stderr(err, data)
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
    local i = self:_consume_line(self.err_buffer, self.fn_err_line_consumer)
    -- truncate the printed lines if found any
    self.err_buffer = i <= #self.err_buffer
        and self.err_buffer:sub(i, #self.err_buffer)
      or nil
  else
    if self.err_buffer then
      -- foreach the data_buffer and find every line
      local i = self:_consume_line(self.err_buffer, self.fn_err_line_consumer)
      if i <= #self.err_buffer then
        local line = self.err_buffer:sub(i, #self.err_buffer)
        self.fn_err_line_consumer(line)
        self.err_buffer = nil
      end
    end
    self.err_pipe:read_stop()
    self:_close_handle(self.err_pipe)
  end
end

function _Spawn:run()
  self.process_handle, self.process_id = uv.spawn(self.cmds[1], {
    args = vim.list_slice(self.cmds, 2),
    stdio = { nil, self.out_pipe, self.err_pipe },
    hide = true,
  }, function(code, signal)
    self.result = { code = code, signal = signal }
    self:_close_handle(self.process_handle)
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

M._Spawn = _Spawn

--- @param cmds string[]
--- @param opts {on_stdout:fzfx.SpawnLineConsumer, on_stderr:fzfx.SpawnLineConsumer?, blocking:boolean}
M.spawn = function(cmds, opts)
  assert(type(opts) == "table")
  assert(type(opts.blocking) == "boolean")
  assert(type(opts.on_stdout) == "function")
  assert(type(opts.on_stderr) == "function" or opts.on_stderr == nil)
  return M._Spawn
    :make(cmds, opts.on_stdout, opts.on_stderr or function() end, opts.blocking)
    :run()
end

--- @param cmds string[]
--- @param opts {on_stdout:fzfx.SpawnLineConsumer, on_stderr:fzfx.SpawnLineConsumer?}
M.blocking_spawn = function(cmds, opts)
  ---@diagnostic disable-next-line: inject-field
  opts.blocking = true
  ---@diagnostic disable-next-line: param-type-mismatch
  return M.spawn(cmds, opts)
end

--- @param cmds string[]
--- @param opts {on_stdout:fzfx.SpawnLineConsumer, on_stderr:fzfx.SpawnLineConsumer?}
M.nonblocking_spawn = function(cmds, opts)
  ---@diagnostic disable-next-line: inject-field
  opts.blocking = false
  ---@diagnostic disable-next-line: param-type-mismatch
  return M.spawn(cmds, opts)
end

return M
