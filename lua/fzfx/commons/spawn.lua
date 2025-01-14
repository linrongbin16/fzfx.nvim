local M = {}

--- @alias commons.SpawnOnExit fun(completed:vim.SystemCompleted):nil
--- @alias commons.SpawnBlockWiseOpts {on_exit:commons.SpawnOnExit?,[string]:any}
--- @param cmd string[]
--- @param opts commons.SpawnBlockWiseOpts?
--- @return vim.SystemObj
M.blockwise = function(cmd, opts)
  opts = opts or {}
  opts.text = type(opts.text) == "boolean" and opts.text or true

  return vim.system(cmd, {
    cwd = opts.cwd,
    env = opts.env,
    clear_env = opts.clear_env,
    stdin = opts.stdin,
    text = opts.text,
    timeout = opts.timeout,
    detach = opts.detach,
  }, opts.on_exit)
end

--- @alias commons.SpawnLineWiseProcessor fun(line:string):any
--- @alias commons.SpawnLineWiseOpts {on_stdout:commons.SpawnLineWiseProcessor,on_stderr:commons.SpawnLineWiseProcessor?,on_exit:commons.SpawnOnExit?,[string]:any}
--- @param cmd string[]
--- @param opts commons.SpawnLineWiseOpts?
--- @return vim.SystemObj
M.linewise = function(cmd, opts)
  opts = opts or {}
  opts.text = type(opts.text) == "boolean" and opts.text or true

  if type(opts.on_exit) ~= "function" then
    opts.on_exit = function() end
  end
  if type(opts.on_stderr) ~= "function" then
    opts.on_stderr = function() end
  end

  assert(type(opts.on_stdout) == "function")
  assert(type(opts.on_stderr) == "function")
  assert(type(opts.on_exit) == "function")

  --- @param buffer string
  --- @param fn_line_processor commons.SpawnLineWiseProcessor
  --- @return integer
  local function _process(buffer, fn_line_processor)
    local str = require("fzfx.commons.str")

    local i = 1
    while i <= #buffer do
      local newline_pos = str.find(buffer, "\n", i)
      if not newline_pos then
        break
      end
      local line = buffer:sub(i, newline_pos - 1)
      fn_line_processor(line)
      i = newline_pos + 1
    end
    return i
  end

  local stdout_buffer = nil

  --- @param err string?
  --- @param data string?
  local function _handle_stdout(err, data)
    if err then
      error(
        string.format(
          "failed to read stdout on cmd:%s, error:%s",
          vim.inspect(cmd),
          vim.inspect(err)
        )
      )
      return
    end

    if data then
      -- append data to buffer
      stdout_buffer = stdout_buffer and (stdout_buffer .. data) or data
      -- search buffer and process each line
      local i = _process(stdout_buffer, opts.on_stdout)
      -- truncate the processed lines if still exists any
      stdout_buffer = i <= #stdout_buffer and stdout_buffer:sub(i, #stdout_buffer) or nil
    elseif stdout_buffer then
      -- foreach the data_buffer and find every line
      local i = _process(stdout_buffer, opts.on_stdout)
      if i <= #stdout_buffer then
        local line = stdout_buffer:sub(i, #stdout_buffer)
        opts.on_stdout(line)
        stdout_buffer = nil
      end
    end
  end

  local stderr_buffer = nil

  --- @param err string?
  --- @param data string?
  local function _handle_stderr(err, data)
    if err then
      error(
        string.format(
          "failed to read stderr on cmd:%s, error:%s",
          vim.inspect(cmd),
          vim.inspect(err)
        )
      )
      return
    end

    if data then
      stderr_buffer = stderr_buffer and (stderr_buffer .. data) or data
      local i = _process(stderr_buffer, opts.on_stderr)
      stderr_buffer = i <= #stderr_buffer and stderr_buffer:sub(i, #stderr_buffer) or nil
    elseif stderr_buffer then
      local i = _process(stderr_buffer, opts.on_stderr)
      if i <= #stderr_buffer then
        local line = stderr_buffer:sub(i, #stderr_buffer)
        opts.on_stderr(line)
        stderr_buffer = nil
      end
    end
  end

  return vim.system(cmd, {
    cwd = opts.cwd,
    env = opts.env,
    clear_env = opts.clear_env,
    ---@diagnostic disable-next-line: assign-type-mismatch
    stdin = opts.stdin,
    stdout = _handle_stdout,
    stderr = _handle_stderr,
    text = opts.text,
    timeout = opts.timeout,
    detach = opts.detach,
  }, opts.on_exit)
end

return M
