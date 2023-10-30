-- No Setup Need

--- @class CmdResult
--- @field stdout string[]?
--- @field stderr string[]?
--- @field code integer?
--- @field signal integer?
local CmdResult = {}

--- @return CmdResult
function CmdResult:new()
    local o = {
        stdout = {},
        stderr = {},
        code = nil,
        signal = nil,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @return boolean
function CmdResult:wrong()
    return type(self.stderr) == "table"
        and #self.stderr > 0
        and type(self.code) == "number"
        and self.code ~= 0
end

--- @class Cmd
--- @field source string[]
--- @field result CmdResult?
local Cmd = {}

--- @param source string[]
--- @return Cmd
function Cmd:run(source)
    local result = CmdResult:new()

    local sp = require("fzfx.spawn").Spawn:make(source, function(line)
        if type(line) == "string" then
            table.insert(result.stdout, line)
        end
    end, function(line)
        if type(line) == "string" then
            table.insert(result.stderr, line)
        end
    end) --[[@as Spawn]]
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
function Cmd:wrong()
    return self.result:wrong()
end

--- @class GitRootCmd
--- @field result CmdResult?
local GitRootCmd = {}

--- @return GitRootCmd
function GitRootCmd:run()
    local cmd = Cmd:run({ "git", "rev-parse", "--show-toplevel" })

    local o = {
        result = cmd.result,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @return boolean
function GitRootCmd:wrong()
    return self.result:wrong()
end

--- @return string?
function GitRootCmd:value()
    if self:wrong() then
        return nil
    end
    return (type(self.result.stdout) == "table" and #self.result.stdout > 0)
            and vim.trim(self.result.stdout[1])
        or nil
end

--- @class GitBranchCmd
--- @field result CmdResult?
local GitBranchCmd = {}

--- @param remotes boolean?
--- @return GitBranchCmd
function GitBranchCmd:run(remotes)
    local cmd = remotes and Cmd:run({ "git", "branch", "--remotes" })
        or Cmd:run({ "git", "branch" })

    local o = {
        result = cmd.result,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @return boolean
function GitBranchCmd:wrong()
    return self.result:wrong()
end

--- @return string[]?
function GitBranchCmd:value()
    if self:wrong() then
        return nil
    end
    return self.result.stdout
end

--- @return string?
function GitBranchCmd:current_branch()
    if self:wrong() then
        return nil
    end
    if type(self.result.stdout) == "table" and #self.result.stdout > 0 then
        for _, out in ipairs(self.result.stdout) do
            local line = vim.trim(out)
            if string.len(line) > 0 and line[1] == "*" then
                return line
            end
        end
    end
    return nil
end

--- @class GitCurrentBranchCmd
--- @field result CmdResult?
local GitCurrentBranchCmd = {}

--- @return GitCurrentBranchCmd
function GitCurrentBranchCmd:run()
    -- git rev-parse --abbrev-ref HEAD
    local cmd = Cmd:run({ "git", "rev-parse", "--abbrev-ref", "HEAD" })

    local o = {
        result = cmd.result,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @return boolean
function GitCurrentBranchCmd:wrong()
    return self.result:wrong()
end

--- @return string?
function GitCurrentBranchCmd:value()
    if self:wrong() then
        return nil
    end
    return (type(self.result.stdout) == "table" and #self.result.stdout > 0)
            and self.result.stdout[1]
        or nil
end

local M = {
    CmdResult = CmdResult,
    Cmd = Cmd,
    GitRootCmd = GitRootCmd,
    GitBranchCmd = GitBranchCmd,
    GitCurrentBranchCmd = GitCurrentBranchCmd,
}

return M
