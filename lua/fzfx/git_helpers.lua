local Command = require("fzfx.command").Command

--- @class GitRootCommand
--- @field result CommandResult?
local GitRootCommand = {
    result = nil,
}

--- @param result CommandResult
local function command_result_wrong(result)
    return type(result) == "table"
        and type(result.stderr) == "table"
        and #result.stderr > 0
        and type(result.exitcode) == "number"
        and result.exitcode ~= 0
end

--- @return GitRootCommand
function GitRootCommand:run()
    local cmd = Command:run({ "git", "rev-parse", "--show-toplevel" })
    return vim.tbl_deep_extend("force", vim.deepcopy(GitRootCommand), {
        result = cmd.result,
    })
end

--- @return boolean
function GitRootCommand:wrong()
    return command_result_wrong(self.result)
end

--- @return string?
function GitRootCommand:value()
    if self:wrong() then
        return nil
    end
    return (type(self.result.stdout) == "table" and #self.result.stdout > 0)
            and vim.fn.trim(self.result.stdout[1])
        or nil
end

--- @class GitBranchCommand
--- @field result CommandResult?
local GitBranchCommand = {
    result = nil,
}

--- @param remotes boolean?
--- @return GitBranchCommand
function GitBranchCommand:run(remotes)
    local cmd = remotes and Command:run({ "git", "branch", "--remotes" })
        or Command:run({ "git", "branch" })
    return vim.tbl_deep_extend("force", vim.deepcopy(GitBranchCommand), {
        result = cmd.result,
    })
end

--- @return boolean
function GitBranchCommand:wrong()
    return command_result_wrong(self.result)
end

--- @return string[]?
function GitBranchCommand:value()
    if self:wrong() then
        return nil
    end
    return self.result.stdout
end

local M = {
    GitRootCommand = GitRootCommand,
}

return M
