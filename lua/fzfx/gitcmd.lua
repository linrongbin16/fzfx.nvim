-- Zero Dependency

local Cmd = require("fzfx.cmd").Cmd

--- @class GitRootCmd
--- @field result CmdResult?
local GitRootCmd = {
    result = nil,
}

--- @param result CmdResult
local function cmd_result_wrong(result)
    return type(result) == "table"
        and type(result.stderr) == "table"
        and #result.stderr > 0
        and type(result.exitcode) == "number"
        and result.exitcode ~= 0
end

--- @return GitRootCmd
function GitRootCmd:run()
    local cmd = Cmd:run({ "git", "rev-parse", "--show-toplevel" })
    return vim.tbl_deep_extend("force", vim.deepcopy(GitRootCmd), {
        result = cmd.result,
    })
end

--- @return boolean
function GitRootCmd:wrong()
    return cmd_result_wrong(self.result)
end

--- @return string?
function GitRootCmd:value()
    if self:wrong() then
        return nil
    end
    return (type(self.result.stdout) == "table" and #self.result.stdout > 0)
            and vim.fn.trim(self.result.stdout[1])
        or nil
end

--- @class GitBranchCmd
--- @field result CmdResult?
local GitBranchCmd = {
    result = nil,
}

--- @param remotes boolean?
--- @return GitBranchCmd
function GitBranchCmd:run(remotes)
    local cmd = remotes and Cmd:run({ "git", "branch", "--remotes" })
        or Cmd:run({ "git", "branch" })
    return vim.tbl_deep_extend("force", vim.deepcopy(GitBranchCmd), {
        result = cmd.result,
    })
end

--- @return boolean
function GitBranchCmd:wrong()
    return cmd_result_wrong(self.result)
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
            local trim_out = vim.fn.trim(out)
            if string.len(trim_out) > 0 and trim_out[1] == "*" then
                return trim_out
            end
        end
    end
    return nil
end

--- @class GitCurrentBranchCmd
--- @field result CmdResult?
local GitCurrentBranchCmd = {
    result = nil,
}

--- @return GitCurrentBranchCmd
function GitCurrentBranchCmd:run()
    -- git rev-parse --abbrev-ref HEAD
    local cmd = Cmd:run({ "git", "rev-parse", "--abbrev-ref", "HEAD" })
    return vim.tbl_deep_extend("force", vim.deepcopy(GitCurrentBranchCmd), {
        result = cmd.result,
    })
end

--- @return boolean
function GitCurrentBranchCmd:wrong()
    return cmd_result_wrong(self.result)
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
    GitRootCmd = GitRootCmd,
    GitBranchCmd = GitBranchCmd,
    GitCurrentBranchCmd = GitCurrentBranchCmd,
}

return M
