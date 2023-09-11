-- Zero Dependency

--- @class CmdResult
--- @field stdout string[]?
--- @field stderr string[]?
--- @field exitcode integer?
local CmdResult = {
    stdout = nil,
    stderr = nil,
    exitcode = nil,
}

--- @return CmdResult
function CmdResult:new()
    return vim.tbl_deep_extend("force", vim.deepcopy(CmdResult), {
        stdout = {},
        stderr = {},
        exitcode = nil,
    })
end

--- @return boolean
function CmdResult:wrong()
    return type(self.stderr) == "table"
        and #self.stderr > 0
        and type(self.exitcode) == "number"
        and self.exitcode ~= 0
end

--- @class Cmd
--- @field source string|string[]|nil
--- @field jobid integer?
--- @field result CmdResult?
--- @field opts table<string, any>?
local Cmd = {
    source = nil,
    jobid = nil,
    result = nil,
    opts = nil,
}

--- @param source string|string[]
--- @param opts table<string, any>?
--- @return Cmd
function Cmd:run(source, opts)
    local detach_opt = (
        type(opts) == "table"
        and type(opts.detach) == "boolean"
        and opts.detach
    )
            and true
        or false
    local c = vim.tbl_deep_extend("force", vim.deepcopy(Cmd), {
        cmd = source,
        detach = detach_opt,
        jobid = nil,
        result = CmdResult:new(),
    })

    local function on_stdout(chanid, data, name)
        if type(data) == "table" then
            for _, d in ipairs(data) do
                if type(d) == "string" and string.len(d) > 0 then
                    table.insert(c.result.stdout, d)
                end
            end
        end
    end

    local function on_stderr(chanid, data, name)
        if type(data) == "table" then
            for _, d in ipairs(data) do
                if type(d) == "string" and string.len(d) > 0 then
                    table.insert(c.result.stderr, d)
                end
            end
        end
    end

    local function on_exit(jobid2, exitcode, event)
        c.result.exitcode = exitcode
    end

    local on_stdout_opt = (
        type(opts) == "table" and type(opts.on_stdout) == "function"
    )
            and opts.on_stdout
        or on_stdout
    local on_stderr_opt = (
        type(opts) == "table" and type(opts.on_stderr) == "function"
    )
            and opts.on_stderr
        or on_stderr

    local on_exit_opt = (
        type(opts) == "table" and type(opts.on_exit) == "function"
    )
            and opts.on_exit
        or on_exit
    local stdout_buffered_opt = (
        type(opts) == "table"
        and type(opts.stdout_buffered) == "boolean"
        and opts.stdout_buffered
    )
            and true
        or false
    local stderr_buffered_opt = (
        type(opts) == "table"
        and type(opts.stderr_buffered) == "boolean"
        and opts.stderr_buffered
    )
            and true
        or false

    local jobid = vim.fn.jobstart(source, {
        on_stdout = on_stdout_opt,
        on_stderr = on_stderr_opt,
        on_exit = on_exit_opt,
        stdout_buffered = stdout_buffered_opt,
        stderr_buffered = stderr_buffered_opt,
    })
    c.jobid = jobid
    if not detach_opt then
        vim.fn.jobwait({ jobid })
    end
    return c
end

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
    return self.result:wrong()
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
    Cmd = Cmd,
    GitRootCmd = GitRootCmd,
    GitBranchCmd = GitBranchCmd,
    GitCurrentBranchCmd = GitCurrentBranchCmd,
}

return M
