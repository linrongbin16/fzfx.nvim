-- No Setup Need

--- @class CmdResult
--- @field stdout string[]?
--- @field stderr string[]?
--- @field exitcode integer?
local CmdResult = {}

--- @return CmdResult
function CmdResult:new()
    local o = {
        stdout = {},
        stderr = {},
        exitcode = nil,
    }
    setmetatable(o, self)
    self.__index = self
    return o
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
    local result = CmdResult:new()

    local function on_stdout(chanid, data, name)
        if type(data) == "table" then
            for _, d in ipairs(data) do
                if type(d) == "string" and string.len(d) > 0 then
                    table.insert(result.stdout, d)
                end
            end
        end
    end

    local function on_stderr(chanid, data, name)
        if type(data) == "table" then
            for _, d in ipairs(data) do
                if type(d) == "string" and string.len(d) > 0 then
                    table.insert(result.stderr, d)
                end
            end
        end
    end

    local function on_exit(jobid2, exitcode, event)
        result.exitcode = exitcode
    end

    local jobid = vim.fn.jobstart(source, {
        on_stdout = on_stdout,
        on_stderr = on_stderr,
        on_exit = on_exit,
        stdout_buffered = true,
        stderr_buffered = true,
    })
    vim.fn.jobwait({ jobid })

    local o = {
        source = source,
        jobid = jobid,
        result = result,
        opts = opts,
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

--- @class AsyncCmd
--- @field cmds string[]
--- @field fn_line_consumer fun(line:string):any
--- @field out_pipe uv_pipe_t
--- @field err_pipe uv_pipe_t
--- @field buffer string?
local AsyncCmd = {}

--- @param cmds string[]
--- @param fn_line_consumer fun(line:string):any
function AsyncCmd:open(cmds, fn_line_consumer)
    local out_pipe = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    local err_pipe = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    if not out_pipe or not err_pipe then
        return nil
    end

    local o = {
        cmds = cmds,
        fn_line_consumer = fn_line_consumer,
        out_pipe = out_pipe,
        err_pipe = err_pipe,
        buffer = nil,
    }

    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param data string?
function AsyncCmd:consume(data)
    if data then
        self.buffer = self.buffer and (self.buffer .. data) or data
    end

    local utils = require("fzfx.utils")
    local i = 1
    while i <= #self.buffer do
        local newline_pos = utils.string_find(self.buffer, "\n", i)
        if not newline_pos then
            break
        end
        local line = self.buffer:sub(i, newline_pos - 1)
        self.fn_line_consumer(line)
        i = newline_pos + 1
    end
    self.buffer = i >= #self.buffer and nil or self.buffer:sub(i, #self.buffer)
end

--- @param opts {detach}
function AsyncCmd:run()
    local process_handler, process_id = vim.loop.spawn(self.cmds[1], {
        args = vim.list_slice(self.cmds, 2),
        stdio = { nil, self.out_pipe, self.err_pipe },
    }, function(code, signal)
        self.out_pipe:read_stop()
        self.err_pipe:read_stop()
        self:close()
    end)

    --- @type string?
    local buffer = nil

    --- @param err string?
    --- @param data string?
    local function on_stdout(err, data)
        if err then
            self:close()
            return
        end

        self:consume(data)

        if not data then
            if type(buffer) == "string" and string.len(buffer) > 0 then
                self.fn_line_consumer(buffer)
                buffer = nil
            end
            self:close()
        end
    end

    local function on_stderr(err, data)
        self:close()
    end

    self.out_pipe:read_start(on_stdout)
    self.err_pipe:read_start(on_stderr)
    vim.loop.run()
end

function AsyncCmd:close()
    self.out_pipe:shutdown(function(shutdown_err)
        self.out_pipe:close(function(close_err)
            vim.loop.stop()
        end)
    end)
    self.err_pipe:shutdown(function(shutdown_err)
        self.err_pipe:close(function(close_err)
            if self.out_pipe():is_closing() then
                vim.loop.stop()
            end
        end)
    end)
end

local M = {
    CmdResult = CmdResult,
    Cmd = Cmd,
    GitRootCmd = GitRootCmd,
    GitBranchCmd = GitBranchCmd,
    GitCurrentBranchCmd = GitCurrentBranchCmd,
    AsyncCmd = AsyncCmd,
}

return M
