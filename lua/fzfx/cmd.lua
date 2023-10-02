-- No Setup Need

local constants = require("fzfx.constants")
local utils = require("fzfx.utils")

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

-- modified from: https://github.com/neovim/neovim/blob/master/runtime/lua/vim/_system.lua
local uv = (vim.fn.has("nvim-0.10") > 0 and vim.uv) and vim.uv or vim.loop

local _MAX_TIMEOUT = 2 ^ 31

local SIG = {
    HUP = 1, -- Hangup
    INT = 2, -- Interrupt from keyboard
    KILL = 9, -- Kill signal
    TERM = 15, -- Termination signal
    -- STOP = 17,19,23  -- Stop the process
}

--- @alias AsyncCmdLineProcessor fun(line:string):any
--- @alias AsyncCmdResult {code:integer|string,signal:integer|string}
--- @class AsyncCmd
--- @field fn_out_line_processor AsyncCmdLineProcessor
--- @field fn_err_line_processor AsyncCmdLineProcessor
--- @field out_pipe uv_pipe_t
--- @field err_pipe uv_pipe_t
--- @field out_buffer string?
--- @field err_buffer string?
--- @field process_handle uv_process_t
--- @field process_id integer
--- @field done boolean|"timeout"
--- @field result AsyncCmdResult?
local AsyncCmd = {}

--- @param line string
local function default_err_line_process(line)
    io.write(string.format("%s\n", vim.inspect(line)))
end

--- @param cmds string[]
--- @param fn_out_line_processor AsyncCmdLineProcessor
--- @param fn_err_line_processor AsyncCmdLineProcessor?
function AsyncCmd:run(cmds, fn_out_line_processor, fn_err_line_processor)
    local out_pipe = uv.new_pipe(false) --[[@as uv_pipe_t]]
    local err_pipe = uv.new_pipe(false) --[[@as uv_pipe_t]]
    if not out_pipe or not err_pipe then
        return nil
    end

    local o = {
        cmds = cmds,
        fn_out_line_processor = fn_out_line_processor,
        fn_err_line_processor = fn_err_line_processor
            or default_err_line_process,
        out_pipe = out_pipe,
        err_pipe = err_pipe,
        out_buffer = nil,
        err_buffer = nil,
        process_handle = nil,
        process_id = nil,
        done = false,
        result = nil,
    }
    setmetatable(o, self)
    self.__index = self

    o.process_handle, o.process_id = uv.spawn(cmds[1], {
        args = vim.list_slice(cmds, 2),
        stdio = { nil, o.out_pipe, o.err_pipe },
        hide = true,
    }, function(code, signal)
        self:_on_exit(code, signal)
    end)

    o.out_pipe:read_start(function(err, data)
        self:_on_stdout(err, data)
    end)
    o.err_pipe:read_start(function(err, data)
        self:_on_stderr(err, data)
    end)

    return o
end

function AsyncCmd:wait()
    local done = vim.wait(_MAX_TIMEOUT, function()
        return self.result ~= nil
    end)

    if not done then
        -- Send sigkill since this cannot be caught
        self:_timeout(SIG.KILL)
        vim.wait(_MAX_TIMEOUT, function()
            return self.result ~= nil
        end)
    end

    return self.result
end

--- @param signal integer|string
function AsyncCmd:_timeout(signal)
    self.done = "timeout"
    self:kill(signal or SIG.TERM)
end

--- @param signal integer|string
function AsyncCmd:kill(signal)
    self.process_handle:kill(signal)
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

---@param handle uv_handle_t?
local function _close_handle(handle)
    if handle and not handle:is_closing() then
        handle:close()
    end
end

function AsyncCmd:_close()
    _close_handle(self.process_handle)
    _close_handle(self.out_pipe)
    _close_handle(self.err_pipe)
end

--- @param code integer
--- @param signal integer
function AsyncCmd:_on_exit(code, signal)
    self:_close()

    local check = assert(uv.new_check())
    check:start(function()
        if not self.out_pipe:is_closing() then
            return
        end
        if not self.err_pipe:is_closing() then
            return
        end
        check:stop()
        check:close()

        if self.done == nil then
            self.done = true
        end

        if
            not constants.is_windows
            and code == 0
            and self.done == "timeout"
        then
            code = 124
        end
        if constants.is_windows and code == 1 and self.done == "timeout" then
            code = 124
        end

        self.result = {
            code = code,
            signal = signal,
        }
    end)
end

--- @param err string?
--- @param data string?
--- @return nil
function AsyncCmd:_on_stdout(err, data)
    if err then
        self.out_pipe:read_stop()
        self.out_pipe:close()
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
        self.err_pipe:read_stop()
        self.err_pipe:close()
    end

    if data then
        -- append data to buffer
        self.err_buffer = self.err_buffer and (self.err_buffer .. data) or data
        self.err_buffer = self.err_buffer:gsub("\r\n", "\n")

        -- foreach the buffer and find every line
        local pos =
            self:_consume_line(self.err_buffer, self.fn_err_line_processor)
        -- truncate the printed lines if found any
        self.err_buffer = pos <= #self.err_buffer and self.err_buffer:sub(pos)
            or nil
    else
        if self.err_buffer then
            -- foreach the buffer and find every line
            local i =
                self:_consume_line(self.err_buffer, self.fn_err_line_processor)
            if i <= #self.err_buffer then
                local line = self.err_buffer:sub(i, #self.err_buffer)
                self.fn_err_line_processor(line)
                self.err_buffer = nil
            end
        end
        self.err_pipe:read_stop()
        self.err_pipe:close()
    end
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
