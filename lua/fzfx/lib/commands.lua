local str = require("fzfx.commons.str")
local spawn = require("fzfx.commons.spawn")
local async = require("fzfx.commons.async")

local M = {}

-- CommandResult {

--- @class fzfx.CommandResult
--- @field stdout string[]|nil
--- @field stderr string[]|nil
--- @field code integer?
--- @field signal integer?
local CommandResult = {}

--- @param stdout string[]|nil
--- @param stderr string[]|nil
--- @param code integer?
--- @param signal integer?
--- @return fzfx.CommandResult
function CommandResult:new(stdout, stderr, code, signal)
  local o = {
    stdout = stdout or {},
    stderr = stderr or {},
    code = code,
    signal = signal,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return boolean
function CommandResult:failed()
  return type(self.stderr) == "table"
    and #self.stderr > 0
    and type(self.code) == "number"
    and self.code ~= 0
end

M.CommandResult = CommandResult

-- CommandResult }

-- Commands {

--- @param source string[]
--- @param on_complete fun(result:fzfx.CommandResult):any
local function run_impl(source, on_complete)
  assert(type(on_complete) == "function", "The 2nd parameter must be callback function")

  local stdout_data = {}
  local stderr_data = {}

  local job = spawn.detached(source, {
    on_stdout = function(line)
      if str.not_empty(line) then
        table.insert(stdout_data, line)
      end
    end,
    on_stderr = function(line)
      if str.not_empty(line) then
        table.insert(stderr_data, line)
      end
    end,
  }, function(completed)
    local result = CommandResult:new(stdout_data, stderr_data, completed.exitcode, completed.signal)
    on_complete(result)
  end)
end

-- Convert callback-style function 'run_impl' into async-style.
--- @type async fun(source:string[]):fzfx.CommandResult
M.run = async.wrap(2, run_impl)

-- Get git repository root path.
--- @type async fun():fzfx.CommandResult
M.run_git_root = async.wrap(1, function(on_complete)
  run_impl({ "git", "rev-parse", "--show-toplevel" }, on_complete)
end)

-- Get git repository branches.
--- @type async fun():fzfx.CommandResult
M.run_git_branches = async.wrap(
  2,
  --- @param remote boolean?
  --- @param on_complete fun(result:fzfx.CommandResult):any
  function(remote, on_complete)
    if remote then
      run_impl({ "git", "branch", "--remotes" }, on_complete)
    else
      run_impl({ "git", "branch" }, on_complete)
    end
  end
)

-- Get git repository current branch.
--- @type async fun():fzfx.CommandResult
M.run_git_current_branch = async.wrap(1, function(on_complete)
  run_impl({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, on_complete)
end)

-- Get git repository remotes.
--- @type async fun():fzfx.CommandResult
M.run_git_remotes = async.wrap(1, function(on_complete)
  run_impl({ "git", "remote" }, on_complete)
end)

-- Commands }

return M
