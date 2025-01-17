local M = {}

-- Escape the Windows/DOS command line (cmd.exe) strings for Windows OS.
--
-- References:
-- * https://www.robvanderwoude.com/escapechars.php
-- * https://ss64.com/nt/syntax-esc.html
-- * https://stackoverflow.com/questions/562038/escaping-double-quotes-in-batch-script
--
--- @param s string
--- @return string
M._escape_windows = function(s)
  local shellslash = vim.o.shellslash
  vim.o.shellslash = false
  local result = vim.fn.escape(s)
  vim.o.shellslash = shellslash
  return result
end

-- Escape shell strings for POSIX compatible OS.
--- @param s string
--- @return string
M._escape_posix = function(s)
  return vim.fn.escape(s)
end

--- @param s string
--- @return string
M.escape = function(s)
  if require("fzfx.commons.platform").IS_WINDOWS then
    return M._escape_windows(s)
  else
    return M._escape_posix(s)
  end
end

--- @class commons.ShellContext
--- @field shell string?
--- @field shellslash string?
--- @field shellcmdflag string?
local ShellContext = {}

--- @return commons.ShellContext
function ShellContext:save()
  local is_win = require("fzfx.commons.platform").IS_WINDOWS

  local o
  if is_win then
    o = {
      shell = vim.o.shell,
      shellslash = vim.o.shellslash,
      shellcmdflag = vim.o.shellcmdflag,
    }
  else
    o = {
      shell = vim.o.shell,
    }
  end

  setmetatable(o, self)
  self.__index = self

  if is_win then
    vim.o.shell = "cmd.exe"
    vim.o.shellslash = false
    vim.o.shellcmdflag = "/s /c"
  else
    vim.o.shell = "sh"
  end

  return o
end

function ShellContext:restore()
  local is_win = require("fzfx.commons.platform").IS_WINDOWS

  if is_win then
    vim.o.shell = self.shell
    vim.o.shellslash = self.shellslash
    vim.o.shellcmdflag = self.shellcmdflag
  else
    vim.o.shell = self.shell
  end
end

--- @alias commons.ShellJobOnExit fun(exitcode:integer?):nil
--- @alias commons.ShellJobOnLine fun(line:string?):any
--- @alias commons.ShellJobOpts {on_stdout:commons.ShellJobOnLine,on_stderr:commons.ShellJobOnLine?,[string]:any}
--- @alias commons.ShellJob {jobid:integer,opts:commons.ShellJobOpts,on_exit:commons.ShellJobOnExit?}

--- @param cmd string
--- @param opts commons.ShellJobOpts?
--- @param on_exit commons.ShellJobOnExit?
--- @return commons.ShellJob
local function _impl(cmd, opts, on_exit)
  opts = opts or {}

  if type(opts.on_stderr) ~= "function" then
    opts.on_stderr = function() end
  end

  assert(type(opts.on_stdout) == "function", "Shell job must have 'on_stdout' function in 'opts'")
  assert(type(opts.on_stderr) == "function", "Shell job must have 'on_stderr' function in 'opts'")
  assert(type(on_exit) == "function" or on_exit == nil)

  local saved_ctx = ShellContext:save()

  local stdout_buffer = { "" }

  local function _handle_stdout(chanid, data, name)
    local eof = type(data) == "table" and #data == 1 and string.len(data[1]) == 0
    local n = #stdout_buffer
    -- Concat the first line in `data` to the last line in `stdout_buffer`, since they could be partial.
    stdout_buffer[n] = stdout_buffer[n] .. data[1]
    local i = 1
    while i < n do
      local line = stdout_buffer[i]
      opts.on_stdout(line)
    end
    -- Removes all the lines before `n` in `stdout_buffer`, only keep the last line since it could be partial.
    stdout_buffer = { stdout_buffer[n] }
    i = 2
    n = #data
    -- Append all the lines after `1` in `data`, since the 1st line is already concat to `stdout_buffer`.
    while i <= n do
      table.insert(stdout_buffer, data[i])
    end
  end

  local stderr_buffer = { "" }

  local function _handle_stderr(chanid, data, name)
    local eof = type(data) == "table" and #data == 1 and string.len(data[1]) == 0
    local n = #stderr_buffer
    -- Concat the first line in `data` to the last line in `stderr_buffer`, since they could be partial.
    stderr_buffer[n] = stderr_buffer[n] .. data[1]
    local i = 1
    while i < n do
      local line = stderr_buffer[i]
      opts.on_stderr(line)
    end
    -- Removes all the lines before `n` in `stderr_buffer`, only keep the last line since it could be partial.
    stderr_buffer = { stderr_buffer[n] }
    i = 2
    n = #data
    -- Append all the lines after `1` in `data`, since the 1st line is already concat to `stderr_buffer`.
    while i <= n do
      table.insert(stderr_buffer, data[i])
    end
  end

  local function _handle_exit(jobid1, exitcode, event)
    opts.on_exit(exitcode)
  end

  local jobid
  if type(on_exit) == "function" then
    jobid = vim.fn.jobstart(cmd, {
      clear_env = opts.clear_env,
      cwd = opts.cwd,
      detach = opts.detach,
      env = opts.env,
      overlapped = opts.overlapped,
      rpc = opts.rpc,
      stdin = opts.stdin,
      term = opts.term,
      height = opts.height,
      width = opts.width,
      pty = opts.pty,
      on_stdout = _handle_stdout,
      on_stderr = _handle_stderr,
      on_exit = _handle_exit,
    })
  else
    jobid = vim.fn.jobstart(cmd, {
      clear_env = opts.clear_env,
      cwd = opts.cwd,
      detach = opts.detach,
      env = opts.env,
      overlapped = opts.overlapped,
      rpc = opts.rpc,
      stdin = opts.stdin,
      term = opts.term,
      height = opts.height,
      width = opts.width,
      pty = opts.pty,
      on_stdout = _handle_stdout,
      on_stderr = _handle_stderr,
    })
  end

  saved_ctx:restore()

  return { jobid = jobid, opts = opts, on_exit = on_exit }
end

--- @param cmd string
--- @param opts commons.ShellJobOpts?
--- @param on_exit commons.ShellJobOnExit
--- @return commons.ShellJob
M.detached = function(cmd, opts, on_exit)
  opts = opts or {}

  assert(
    type(opts.on_stdout) == "function",
    "Detached shell job must have 'on_stdout' function in 'opts'"
  )
  assert(opts.on_exit == nil, "Detached shell job cannot have 'on_exit' function in 'opts'")
  assert(
    type(on_exit) == "function",
    "Detached shell job must have 'on_exit' function in 3rd parameter"
  )

  return _impl(cmd, opts, on_exit)
end

--- @param cmd string
--- @param opts commons.ShellJobOpts?
--- @return commons.ShellJob
M.waitable = function(cmd, opts)
  opts = opts or {}

  assert(
    type(opts.on_stdout) == "function",
    "Waitable shell job must have 'on_stdout' function in 'opts'"
  )
  assert(opts.on_exit == nil, "Waitable shell job cannot have 'on_exit' function in 'opts'")

  return _impl(cmd, opts)
end

--- @param job commons.ShellJob
--- @param timeout integer?
M.wait = function(job, timeout)
  assert(type(job) == "table", "Shell job must be a 'commons.ShellJob' object")
  assert(type(job.jobid) == "number", "Shell job must has a job ID")
  assert(type(job.opts) == "table", "Shell job must has a job opts")
  assert(
    job.on_exit == nil,
    "Detached shell job cannot 'wait' for its exit, it already has 'on_exit' in 3rd parameter for its exit"
  )

  if type(timeout) == "number" and timeout >= 0 then
    vim.fn.jobwait({ job.jobid }, timeout)
  else
    vim.fn.jobwait({ job.jobid })
  end
end

return M
