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

--- @alias AsyncCmdLineConsumer fun(line:string):any
--- @class AsyncCmd
--- @field cmds string[]
--- @field fn_line_consumer AsyncCmdLineConsumer
--- @field out_pipe uv_pipe_t
--- @field err_pipe uv_pipe_t
--- @field out_buffer string?
local AsyncCmd = {}

--- @param cmds string[]
--- @param fn_line_consumer AsyncCmdLineConsumer
--- @return AsyncCmd?
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
        out_buffer = nil,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param buffer string
--- @param fn_line_processor AsyncCmdLineConsumer
--- @return integer
function AsyncCmd:consume_line(buffer, fn_line_processor)
    local i = 1
    while i <= #buffer do
        local newline_pos = require("fzfx.utils").string_find(buffer, "\n", i)
        if not newline_pos then
            break
        end
        local line = buffer:sub(i, newline_pos - 1)
        fn_line_processor(line)
        i = newline_pos + 1
    end
    return i
end

--- @alias AsyncCmdRunOptOnExit fun(code:integer?,signal:integer?):any
--- @alias AsyncCmdRunOpts {on_exit:AsyncCmdRunOptOnExit?}
--- @param opts AsyncCmdRunOpts?
function AsyncCmd:start(opts)
    local user_on_exit_invoked = false

    --- @param code integer?
    ---@param signal integer?
    local function on_exit(code, signal)
        if not self.out_pipe:is_closing() then
            self.out_pipe:close(function(err)
                if self.err_pipe:is_closing() then
                    if
                        type(opts) == "table"
                        and type(opts.on_exit) == "function"
                        and not user_on_exit_invoked
                    then
                        opts.on_exit(code, signal)
                        user_on_exit_invoked = true
                    end
                end
            end)
        end
        if not self.err_pipe:is_closing() then
            self.err_pipe:close(function(err)
                if self.out_pipe:is_closing() then
                    if
                        type(opts) == "table"
                        and type(opts.on_exit) == "function"
                        and not user_on_exit_invoked
                    then
                        opts.on_exit(code, signal)
                        user_on_exit_invoked = true
                    end
                end
            end)
        end
    end

    local process_handler, process_id = vim.loop.spawn(self.cmds[1], {
        args = vim.list_slice(self.cmds, 2),
        stdio = { nil, self.out_pipe, self.err_pipe },
        -- verbatim = true,
    }, function(exit_code, exit_signal)
        self.out_pipe:read_stop()
        self.err_pipe:read_stop()
        self.out_pipe:shutdown(function(err)
            on_exit(exit_code, exit_signal)
        end)
        self.err_pipe:shutdown(function(err)
            on_exit(exit_code, exit_signal)
        end)
    end)

    --- @param err string?
    --- @param data string?
    local function on_stdout(err, data)
        if err then
            on_exit(130)
            return
        end

        if not data then
            if self.out_buffer then
                -- foreach the data_buffer and find every line
                local i =
                    self:consume_line(self.out_buffer, self.fn_line_consumer)
                if i <= #self.out_buffer then
                    local line = self.out_buffer:sub(i, #self.out_buffer)
                    self.fn_line_consumer(line)
                    self.out_buffer = nil
                end
            end
            on_exit(0)
            return
        end

        -- append data to data_buffer
        self.out_buffer = self.out_buffer and (self.out_buffer .. data) or data
        -- foreach the data_buffer and find every line
        local i = self:consume_line(self.out_buffer, self.fn_line_consumer)
        -- truncate the printed lines if found any
        self.out_buffer = i <= #self.out_buffer
                and self.out_buffer:sub(i, #self.out_buffer)
            or nil
    end

    local function on_stderr(err, data)
        -- io.write(
        --     string.format(
        --         "err:%s, data:%s\n",
        --         vim.inspect(err_err),
        --         vim.inspect(err_data)
        --     )
        -- )
        if err then
            io.write(
                string.format(
                    "err:%s, data:%s",
                    vim.inspect(err),
                    vim.inspect(data)
                )
            )
            on_exit(130)
        end
    end

    self.out_pipe:read_start(on_stdout)
    self.err_pipe:read_start(on_stderr)
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
