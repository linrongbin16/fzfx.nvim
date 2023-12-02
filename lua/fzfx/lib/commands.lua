local spawn = require("fzfx.lib.spawn")

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
  local sp = spawn.Spawn:make(source, {
    on_stdout = function(line)
      if type(line) == "string" then
        table.insert(result.stdout, line)
      end
    end,
    on_stderr = function(line)
      if type(line) == "string" then
        table.insert(result.stderr, line)
      end
    end,
    blocking = true,
  })
  sp:run()

  if type(sp.result) == "table" then
    result.code = sp.result.code
    result.signal = sp.result.signal
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
  return (type(self.result.stdout) == "table" and #self.result.stdout > 0)
      and self.result.stdout[1]
    or nil
end

M.GitCurrentBranchCommand = GitCurrentBranchCommand

-- GitCurrentBranchCommand }

return M
