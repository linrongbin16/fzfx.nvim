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

function CmdResult:new()
    return vim.tbl_deep_extend("force", vim.deepcopy(CmdResult), {
        stdout = {},
        stderr = {},
        exitcode = nil,
    })
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

local M = {
    Cmd = Cmd,
}

return M
