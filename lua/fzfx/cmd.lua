-- No Setup Need

local utils = require("fzfx.utils")

--- @class CmdResult
--- @field stdout string[]?
--- @field stderr string[]?
--- @field code integer|string|nil
--- @field signal integer|string|nil
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

--- @alias AsyncCmdLineProcessor fun(line:string):any
--- @class AsyncCmd
--- @field cmd string[]
--- @field fn_out_line_processor AsyncCmdLineProcessor
--- @field fn_err_line_processor AsyncCmdLineProcessor
--- @field out_pipe uv_pipe_t
--- @field err_pipe uv_pipe_t
--- @field out_buffer string?
--- @field err_buffer string?
--- @field handle uv_process_t?
--- @field pid integer|string|nil
--- @field result CmdResult?
local AsyncCmd = {}

--- @param line string
local function default_err_line_processor(line)
    if type(line) == "string" then
        io.write(vim.trim(line) .. "\n")
    end
end

--- @param cmd string[]
--- @param fn_out_line_processor AsyncCmdLineProcessor
--- @param fn_err_line_processor AsyncCmdLineProcessor?
--- @return AsyncCmd?
function AsyncCmd:open(cmd, fn_out_line_processor, fn_err_line_processor)
    local out_pipe = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    local err_pipe = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    if not out_pipe or not err_pipe then
        return nil
    end

    local o = {
        cmd = cmd,
        fn_out_line_processor = fn_out_line_processor,
        fn_err_line_processor = fn_err_line_processor
            or default_err_line_processor,
        out_pipe = out_pipe,
        err_pipe = err_pipe,
        out_buffer = nil,
        err_buffer = nil,
        handle = nil,
        pid = nil,
        result = nil,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param buffer string
--- @param fn_line_processor AsyncCmdLineProcessor
--- @return integer
function AsyncCmd:_consume_line(buffer, fn_line_processor)
    local i = 1
    while i <= #buffer do
        local newline_pos = utils.string_find(buffer, "\n", i)
        if not newline_pos then
            break
        end
        local line = buffer:sub(i, newline_pos - 1)
        fn_line_processor(line)
        i = newline_pos + 1
    end
    return i
end

--- @param code integer?
--- @param signal integer?
--- @return nil
function AsyncCmd:on_exit(code, signal)
    if self.handle and not self.handle:is_closing() then
        self.handle:close(function()
            vim.loop.stop()
        end)
    end
end

--- @param err string?
--- @param data string?
--- @return nil
function AsyncCmd:on_stdout(err, data)
    if err then
        self:on_exit(130)
        return
    end

    if not data then
        if self.out_buffer then
            -- foreach the data_buffer and find every line
            local i =
                self:_consume_line(self.out_buffer, self.fn_out_line_processor)
            if i <= #self.out_buffer then
                local line = self.out_buffer:sub(i, #self.out_buffer)
                self.fn_out_line_processor(line)
                self.out_buffer = nil
            end
        end
        self.out_pipe:close()
        self:on_exit(0)
        return
    end

    -- append data to data_buffer
    self.out_buffer = self.out_buffer and (self.out_buffer .. data) or data
    -- foreach the data_buffer and find every line
    local i = self:_consume_line(self.out_buffer, self.fn_out_line_processor)
    -- truncate the printed lines if found any
    self.out_buffer = i <= #self.out_buffer
            and self.out_buffer:sub(i, #self.out_buffer)
        or nil
end

--- @param err string?
--- @param data string?
--- @return nil
function AsyncCmd:on_stderr(err, data)
    if err then
        io.write(
            string.format(
                "err:%s, data:%s",
                vim.inspect(err),
                vim.inspect(data)
            )
        )
        self.err_pipe:close()
        self:on_exit(130)
    end
end

function AsyncCmd:run()
    local process_handler, process_id = vim.loop.spawn(self.cmd[1], {
        args = vim.list_slice(self.cmd, 2),
        stdio = { nil, self.out_pipe, self.err_pipe },
        hide = true,
        -- verbatim = true,
    }, function(code, signal)
        self:on_exit(code, signal)
    end)

    self.handle = process_handler
    self.pid = process_id

    self.out_pipe:read_start(function(err, data)
        self:on_stdout(err, data)
    end)
    self.err_pipe:read_start(function(err, data)
        self:on_stderr(err, data)
    end)
    vim.loop.run()
end

--- @return boolean
function CmdResult:wrong()
    return type(self.stderr) == "table"
        and #self.stderr > 0
        and type(self.code) == "number"
        and self.code ~= 0
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
        result.code = exitcode
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

local M = {
    AsyncCmd = AsyncCmd,
    CmdResult = CmdResult,
    Cmd = Cmd,
    GitRootCmd = GitRootCmd,
    GitBranchCmd = GitBranchCmd,
    GitCurrentBranchCmd = GitCurrentBranchCmd,
}

return M
