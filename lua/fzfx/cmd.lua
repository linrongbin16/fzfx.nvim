-- No Setup Need

local constants = require("fzfx.constants")
local utils = require("fzfx.utils")
local system = require("fzfx.system")

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

--- @alias AsyncCmdLineProcessor fun(line:string):any
--- @class AsyncCmd
--- @field fn_out_line_processor AsyncCmdLineProcessor
--- @field out_pipe uv_pipe_t
--- @field err_pipe uv_pipe_t
--- @field out_buffer string?
local AsyncCmd = {}

--- @param cmds string[]
--- @param fn_out_line_processor AsyncCmdLineProcessor
function AsyncCmd:run(cmds, fn_out_line_processor)
    return system.run(cmds, {
        stdin = nil,
        stdout = function(err, data)
            self:_on_stdout(err, data)
        end,
        -- stderr = function(err, data)
        --     self:_on_stderr(err, data)
        -- end,
        text = true,
    })
end

--- @param buffer string
--- @param fn_out_line_processor AsyncCmdLineProcessor
--- @return integer
function AsyncCmd:_consume_line(buffer, fn_out_line_processor)
    local i = 1
    while i <= #buffer do
        local newline_pos = utils.string_find(buffer, "\n", i)
        if not newline_pos then
            break
        end
        local line = buffer:sub(i, newline_pos - 1)
        fn_out_line_processor(line)
        i = newline_pos + 1
    end
    return i
end

--- @param err string?
--- @param data string?
--- @return nil
function AsyncCmd:_on_stdout(err, data)
    if err then
        error(err)
    end

    if data then
        -- append data to buffer
        self.out_buffer = self.out_buffer and (self.out_buffer .. data) or data
        self.out_buffer = self.out_buffer:gsub("\r\n", "\n")

        -- foreach the buffer and find every line
        local pos =
            self:_consume_line(self.out_buffer, self.fn_out_line_processor)
        -- truncate the printed lines if found any
        self.out_buffer = pos <= #self.out_buffer and self.out_buffer:sub(pos)
            or nil
    else
        if self.out_buffer then
            -- foreach the buffer and find every line
            local i =
                self:_consume_line(self.out_buffer, self.fn_out_line_processor)
            if i <= #self.out_buffer then
                local line = self.out_buffer:sub(i, #self.out_buffer)
                self.fn_out_line_processor(line)
                self.out_buffer = nil
            end
        end
        self.out_pipe:read_stop()
        self.out_pipe:close()
    end
end

--- @param err string?
--- @param data string?
--- @return nil
function AsyncCmd:_on_stderr(err, data)
    if err then
        error(err)
    end

    -- if data then
    --     -- append data to buffer
    --     self.err_buffer = self.err_buffer and (self.err_buffer .. data) or data
    --     self.err_buffer = self.err_buffer:gsub("\r\n", "\n")
    --
    --     -- foreach the buffer and find every line
    --     local pos =
    --         self:_consume_line(self.err_buffer, self.fn_err_line_processor)
    --     -- truncate the printed lines if found any
    --     self.err_buffer = pos <= #self.err_buffer and self.err_buffer:sub(pos)
    --         or nil
    -- else
    --     if self.err_buffer then
    --         -- foreach the buffer and find every line
    --         local i =
    --             self:_consume_line(self.err_buffer, self.fn_err_line_processor)
    --         if i <= #self.err_buffer then
    --             local line = self.err_buffer:sub(i, #self.err_buffer)
    --             self.fn_err_line_processor(line)
    --             self.err_buffer = nil
    --         end
    --     end
    --     self.err_pipe:read_stop()
    --     self.err_pipe:close()
    -- end
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
