local str = require("fzfx.commons.str")
local tbl = require("fzfx.commons.tbl")
local spawn = require("fzfx.commons.spawn")

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

-- Command {

--- @class fzfx.Command
--- @field source string[]
--- @field result fzfx.CommandResult?
local Command = {}

--- @param source string[]
--- @return fzfx.Command
function Command:run(source)
  local result = CommandResult:new()
  local sp = spawn.run(source, {
    on_stdout = function(line)
      if str.not_empty(line) then
        table.insert(result.stdout, line)
      end
    end,
    on_stderr = function(line)
      if str.not_empty(line) then
        table.insert(result.stderr, line)
      end
    end,
  })
  local completed = sp:wait()
  if tbl.tbl_not_empty(completed) and completed.code then
    result.code = completed.code
  end
  if tbl.tbl_not_empty(completed) and completed.signal then
    result.signal = completed.signal
  end

  local o = {
    source = source,
    result = result,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return boolean
function Command:failed()
  return self.result:failed()
end

M.Command = Command

-- Command }

-- AsyncCommand {

--- @class fzfx.AsyncCommand
--- @field source string[]
--- @field spawn_obj vim.SystemObj
local AsyncCommand = {}

--- @param source string[]
--- @param on_complete fun(result: fzfx.CommandResult):nil
--- @return fzfx.AsyncCommand
function AsyncCommand:run(source, on_complete)
  assert(type(on_complete) == "function")

  local result = CommandResult:new()
  local spawn_obj = spawn.run(source, {
    on_stdout = function(line)
      if str.not_empty(line) then
        table.insert(result.stdout, line)
      end
    end,
    on_stderr = function(line)
      if str.not_empty(line) then
        table.insert(result.stderr, line)
      end
    end,
  }, function(completed)
    if tbl.tbl_not_empty(completed) and completed.code then
      result.code = completed.code
    end
    if tbl.tbl_not_empty(completed) and completed.signal then
      result.signal = completed.signal
    end
    on_complete(result)
  end)

  local o = {
    source = source,
    spawn_obj = spawn_obj,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

-- AsyncCommand }

-- GitRootCommand {

--- @class fzfx.GitRootCommand
--- @field result fzfx.CommandResult?
local GitRootCommand = {}

--- @return fzfx.GitRootCommand
function GitRootCommand:run()
  local cmd = Command:run({ "git", "rev-parse", "--show-toplevel" })
  local o = {
    result = cmd.result,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return boolean
function GitRootCommand:failed()
  return self.result:failed()
end

--- @return string?
function GitRootCommand:output()
  if self:failed() then
    return nil
  end
  return (type(self.result.stdout) == "table" and #self.result.stdout > 0)
      and vim.trim(self.result.stdout[1])
    or nil
end

M.GitRootCommand = GitRootCommand

-- GitRootCommand }

-- GitRootAsyncCommand {

--- @class fzfx.GitRootAsyncCommand
--- @field async_command fzfx.AsyncCommand?
local GitRootAsyncCommand = {}

--- @param on_complete fun(result: fzfx.CommandResult):nil
--- @return fzfx.GitRootAsyncCommand
function GitRootAsyncCommand:run(on_complete)
  local acommand = AsyncCommand:run({ "git", "rev-parse", "--show-toplevel" }, on_complete)
  local o = {
    async_command = acommand,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

M.GitRootAsyncCommand = GitRootAsyncCommand

-- GitRootAsyncCommand }

-- GitBranchesCommand {

--- @class fzfx.GitBranchesCommand
--- @field result fzfx.CommandResult?
local GitBranchesCommand = {}

--- @param remotes boolean?
--- @return fzfx.GitBranchesCommand
function GitBranchesCommand:run(remotes)
  local cmd = remotes and Command:run({ "git", "branch", "--remotes" })
    or Command:run({ "git", "branch" })

  local o = {
    result = cmd.result,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return boolean
function GitBranchesCommand:failed()
  return self.result:failed()
end

--- @return string[]?
function GitBranchesCommand:output()
  if self:failed() then
    return nil
  end
  return self.result.stdout
end

M.GitBranchesCommand = GitBranchesCommand

-- GitBranchesCommand }

-- GitBranchesAsyncCommand {

--- @class fzfx.GitBranchesAsyncCommand
--- @field async_command fzfx.AsyncCommand?
local GitBranchesAsyncCommand = {}

--- @param remotes boolean?
--- @param on_complete fun(result: fzfx.CommandResult):nil
--- @return fzfx.GitBranchesAsyncCommand
function GitBranchesAsyncCommand:run(remotes, on_complete)
  local cmd = remotes and AsyncCommand:run({ "git", "branch", "--remotes" }, on_complete)
    or AsyncCommand:run({ "git", "branch" }, on_complete)

  local o = {
    async_command = cmd,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

M.GitBranchesAsyncCommand = GitBranchesAsyncCommand

-- GitBranchesAsyncCommand }

-- GitCurrentBranchCommand {

--- @class fzfx.GitCurrentBranchCommand
--- @field result fzfx.CommandResult?
local GitCurrentBranchCommand = {}

--- @return fzfx.GitCurrentBranchCommand
function GitCurrentBranchCommand:run()
  -- git rev-parse --abbrev-ref HEAD
  local cmd = Command:run({ "git", "rev-parse", "--abbrev-ref", "HEAD" })

  local o = {
    result = cmd.result,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return boolean
function GitCurrentBranchCommand:failed()
  return self.result:failed()
end

--- @return string?
function GitCurrentBranchCommand:output()
  if self:failed() then
    return nil
  end
  return (type(self.result.stdout) == "table" and #self.result.stdout > 0) and self.result.stdout[1]
    or nil
end

M.GitCurrentBranchCommand = GitCurrentBranchCommand

-- GitCurrentBranchCommand }

-- GitCurrentBranchAsyncCommand {

--- @class fzfx.GitCurrentBranchAsyncCommand
--- @field async_command fzfx.AsyncCommand?
local GitCurrentBranchAsyncCommand = {}

--- @param on_complete fun(result: fzfx.CommandResult):nil
--- @return fzfx.GitCurrentBranchAsyncCommand
function GitCurrentBranchAsyncCommand:run(on_complete)
  -- git rev-parse --abbrev-ref HEAD
  local acommand = AsyncCommand:run({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, on_complete)

  local o = {
    async_command = acommand,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

M.GitCurrentBranchAsyncCommand = GitCurrentBranchAsyncCommand

-- GitCurrentBranchAsyncCommand }

-- GitRemotesCommand {

--- @class fzfx.GitRemotesCommand
--- @field result fzfx.CommandResult?
local GitRemotesCommand = {}

--- @return fzfx.GitRemotesCommand
function GitRemotesCommand:run()
  -- git rev-parse --abbrev-ref HEAD
  local cmd = Command:run({ "git", "remote" })

  local o = {
    result = cmd.result,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return boolean
function GitRemotesCommand:failed()
  return self.result:failed()
end

--- @return string[]|nil
function GitRemotesCommand:output()
  if self:failed() then
    return nil
  end
  return (type(self.result.stdout) == "table" and #self.result.stdout > 0) and self.result.stdout
    or nil
end

M.GitRemotesCommand = GitRemotesCommand

-- GitRemotesCommand }

-- GitRemotesAsyncCommand {

--- @class fzfx.GitRemotesAsyncCommand
--- @field async_command fzfx.AsyncCommand?
local GitRemotesAsyncCommand = {}

--- @param on_complete fun(result: fzfx.CommandResult):nil
--- @return fzfx.GitRemotesAsyncCommand
function GitRemotesAsyncCommand:run(on_complete)
  -- git rev-parse --abbrev-ref HEAD
  local acommand = AsyncCommand:run({ "git", "remote" }, on_complete)

  local o = {
    async_command = acommand,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

M.GitRemotesAsyncCommand = GitRemotesAsyncCommand

-- GitRemotesAsyncCommand }

return M
