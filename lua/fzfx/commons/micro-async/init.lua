---@mod micro-async

---@alias micro-async.SelectOpts { prompt: string?, format_item: nil|fun(item: any): string, kind: string? }

---@alias micro-async.InputOpts { prompt: string?, default: string?, completion: string?, highlight: fun(text: string) }

---@class micro-async.Cancellable
---@field cancel fun(self: micro-async.Cancellable)
---@field is_cancelled fun(self: micro-async.Cancellable): boolean

---@class micro-async.Task: micro-async.Cancellable
---@field thread thread
---@field resume fun(self: micro-async.Task, ...: any):micro-async.Cancellable?

local yield = coroutine.yield
local resume = coroutine.resume
local running = coroutine.running

---@type table<thread, micro-async.Task>
---@private
local handles = setmetatable({}, {
  __mode = "k",
})

---@private
local function is_cancellable(task)
  return type(task) == "table"
    and vim.is_callable(task.cancel)
    and vim.is_callable(task.is_cancelled)
end

---@param fn fun(...): ...
---@return micro-async.Task
---@private
local function new_task(fn)
  local thread = coroutine.create(fn)
  local cancelled = false

  local task = {}
  local current = nil

  function task:cancel()
    if not cancelled then
      cancelled = true
      if current and not current:is_cancelled() then
        current:cancel()
      end
    end
  end

  function task:resume(...)
    if not cancelled then
      local ok, rv = resume(thread, ...)
      if not ok then
        self:cancel()
        error(rv)
      end
      if is_cancellable(rv) then
        current = rv
      end
    end
  end

  handles[thread] = task

  return task
end

local Async = {}

---@text Create a callback function that resumes the current or specified coroutine when called.
---
---@param co thread | nil The thread to resume, defaults to the running one.
---@return fun(args:...)
function Async.callback(co)
  co = co or running()
  return function(...)
    if co and handles[co] then
      handles[co]:resume(...)
    end
  end
end

---@text Create a callback function that resumes the current or specified coroutine when called,
---and is wrapped in `vim.schedule` to ensure the API is safe to call.
---
---@param co thread | nil The thread to resume, defaults to the running one.
---@return fun(args:...)
function Async.scheduled_callback(co)
  co = co or running()
  return function(...)
    handles[co]:resume(...)
  end
end

---@text Create an async function that can be called from a synchronous context.
---Cannot return values as it is non-blocking.
---
---@param fn fun(...):...
---@return fun(...): micro-async.Task
function Async.void(fn)
  local task = new_task(fn)
  return function(...)
    task:resume(...)
    return task
  end
end

---@text Run a function asynchronously and call the callback with the result.
---
---@param fn fun(...):...
---@param cb fun(...)
---@param ... any
---@return micro-async.Task
function Async.run(fn, cb, ...)
  local task = new_task(function(...)
    cb(fn(...))
  end)
  task:resume(...)
  return task
end

---@text Run an async function syncrhonously and return the result.
---@text WARNING: This will completely block Neovim's main thread!
---
---@param fn fun(...):...
---@param timeout_ms integer?
---@param ... any
---@return boolean
---@return any ...
function Async.block_on(fn, timeout_ms, ...)
  local done, result = false, nil
  Async.run(fn, function(...)
    result, done = { ... }, true
  end, ...)
  vim.wait(timeout_ms or 1000, function()
    return done
  end)
  return done, result and unpack(result)
end

---@text Wrap a callback-style function to be async. Add an additional `callback` parameter at the
---end of function, to yield value on its callback. And the `argc` parameter should be parameters
---count + 1 (with an additional `callback` parameter).
---
---@param fn fun(...): ...any
---@param argc integer
---@return fun(...): ...
function Async.wrap(fn, argc)
  return function(...)
    local args = { ... }
    args[argc] = Async.callback()
    return yield(fn(unpack(args)))
  end
end

---@text Wrap a callback-style function to be async, with the callback wrapped in `vim.schedule_wrap`
---to ensure it is safe to call the nvim API.
---
---@param fn fun(...): ...any
---@param argc integer
---@return fun(...): ...
function Async.scheduled_wrap(fn, argc)
  return function(...)
    local args = { ... }
    args[argc] = Async.scheduled_callback()
    return yield(fn(unpack(args)))
  end
end

---@text Yields to the Neovim scheduler
---
---@async
function Async.schedule()
  return yield(vim.schedule(Async.callback()))
end

---@text Yields the current task, resuming when the specified timeout has elapsed.
---
---@async
---@param timeout integer
function Async.defer(timeout)
  yield({
    ---@type uv_timer_t
    timer = vim.defer_fn(Async.callback(), timeout),
    cancel = function(self)
      if not self.timer:is_closing() then
        if self.timer:is_active() then
          self.timer:stop()
        end
        self.timer:close()
      end
    end,
    is_cancelled = function(self)
      return self.timer:is_closing()
    end,
  })
end

---@text Wrapper that creates and queues a work request, yields, and resumes the current task with the results.
---
---@async
---@param fn fun(...):...
---@param ... ...uv.aliases.threadargs
---@return ...uv.aliases.threadargs
function Async.work(fn, ...)
  local uv = require("fzfx.commons.micro-async.uv")
  return uv.queue_work(uv.new_work(fn), ...)
end

---@text Async vim.system
---
---@async
---@param cmd string[] Command to run
---@param opts table Options to pass to `vim.system`
Async.system = function(cmd, opts)
  return yield(vim.system(cmd, opts, Async.callback()))
end

---@text Join multiple async functions and call the callback with the results.
---@param ... fun():...
function Async.join(...)
  local thunks = { ... }
  local remaining = #thunks
  local results = {}
  local wrapped = function()
    for i, thunk in ipairs(thunks) do
      results[i] = { thunk() }
      remaining = remaining - 1
      if remaining == 0 then
        return unpack(results)
      end
    end
  end
  return wrapped()
end

---@module "commons.micro-async.lsp"
---@private
Async.lsp = nil

---@module "commons.micro-async.uv"
---@private
Async.uv = nil

---@private
Async.ui = {}

---@async
---@param items any[]
---@param opts micro-async.SelectOpts
---@return any|nil, integer|nil
Async.ui.select = function(items, opts)
  vim.ui.select(items, opts, Async.callback())

  local win = vim.api.nvim_get_current_win()

  local cancelled = false
  return yield({
    cancel = function()
      vim.api.nvim_win_close(win, true)
      cancelled = true
    end,
    is_cancelled = function()
      return cancelled
    end,
  })
end

---@async
---@param opts micro-async.InputOpts
---@return string|nil
Async.ui.input = function(opts)
  return yield(vim.ui.input(opts, Async.scheduled_callback()))
end

setmetatable(Async, {
  __index = function(_, k)
    local ok, mod = pcall(require, "commons.micro-async." .. k)
    if ok then
      return mod
    end
  end,
})

return Async
