-- No Setup Need

local constants = require("fzfx.constants")

--- @param bufnr integer
--- @param name string
--- @return any
local function get_buf_option(bufnr, name)
    if vim.fn.has("nvim-0.8") > 0 then
        return vim.api.nvim_get_option_value(name, { buf = bufnr })
    else
        return vim.api.nvim_buf_get_option(bufnr, name)
    end
end

--- @param bufnr integer
--- @param name string
--- @param value any
--- @return any
local function set_buf_option(bufnr, name, value)
    if vim.fn.has("nvim-0.8") > 0 then
        return vim.api.nvim_set_option_value(name, value, { buf = bufnr })
    else
        return vim.api.nvim_buf_set_option(bufnr, name, value)
    end
end

--- @param bufnr integer?
--- @return boolean
local function is_buf_valid(bufnr)
    if bufnr == nil or type(bufnr) ~= "number" then
        return false
    end
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    return vim.api.nvim_buf_is_valid(bufnr)
        and vim.fn.buflisted(bufnr) > 0
        and type(bufname) == "string"
        and string.len(bufname) > 0
end

--- @param winnr integer
--- @param name string
--- @return any
local function get_win_option(winnr, name)
    if vim.fn.has("nvim-0.8") > 0 then
        return vim.api.nvim_get_option_value(name, { win = winnr })
    else
        return vim.api.nvim_win_get_option(winnr, name)
    end
end

--- @param winnr integer
--- @param name string
--- @param value any
--- @return any
local function set_win_option(winnr, name, value)
    if vim.fn.has("nvim-0.8") > 0 then
        return vim.api.nvim_set_option_value(name, value, { win = winnr })
    else
        return vim.api.nvim_win_set_option(winnr, name, value)
    end
end

--- @param s any
--- @return boolean
local function string_empty(s)
    return type(s) ~= "string" or string.len(s) == 0
end

--- @param s any
--- @return boolean
local function string_not_empty(s)
    return type(s) == "string" and string.len(s) > 0
end

--- @param s string
--- @param t string
--- @param start integer?
--- @return integer?
local function string_find(s, t, start)
    -- start = start or 1
    -- local result = vim.fn.stridx(s, c, start - 1)
    -- return result >= 0 and (result + 1) or nil

    start = start or 1
    for i = start, #s do
        local match = true
        for j = 1, #t do
            if i + j - 1 > #s then
                match = false
                break
            end
            local a = string.byte(s, i + j - 1)
            local b = string.byte(t, j)
            if a ~= b then
                match = false
                break
            end
        end
        if match then
            return i
        end
    end
    return nil
end

--- @param s string
--- @param t string
--- @param rstart integer?
--- @return integer?
local function string_rfind(s, t, rstart)
    -- rstart = rstart or 1
    -- local result = vim.fn.strridx(s, c, rstart - 1)
    -- return result >= 0 and (result + 1) or nil

    rstart = rstart or #s
    for i = rstart, 1, -1 do
        local match = true
        for j = 1, #t do
            if i + j - 1 > #s then
                match = false
                break
            end
            local a = string.byte(s, i + j - 1)
            local b = string.byte(t, j)
            if a ~= b then
                match = false
                break
            end
        end
        if match then
            return i
        end
    end
    return nil
end

--- @param s string
--- @param t string?
--- @return string
local function string_ltrim(s, t)
    t = t or "\n\t\r "
    local i = 1
    while i <= #s do
        local c = string.byte(s, i)
        local contains = false
        for j = 1, #t do
            if string.byte(t, j) == c then
                contains = true
                break
            end
        end
        if not contains then
            break
        end
        i = i + 1
    end
    return s:sub(i, #s)
end

--- @param s string
--- @param t string?
--- @return string
local function string_rtrim(s, t)
    t = t or "\n\t\r "
    local i = #s
    while i >= 1 do
        local c = string.byte(s, i)
        local contains = false
        for j = 1, #t do
            if string.byte(t, j) == c then
                contains = true
                break
            end
        end
        if not contains then
            break
        end
        i = i - 1
    end
    return s:sub(1, i)
end

--- @param s string
--- @param delimiter string
--- @param opts {plain:boolean?,trimempty:boolean?}|nil
--- @return string[]
local function string_split(s, delimiter, opts)
    opts = opts or {
        plain = true,
        trimempty = true,
    }
    opts.plain = opts.plain == nil and true or opts.plain
    opts.trimempty = opts.trimempty == nil and true or opts.trimempty
    return vim.split(s, delimiter, opts)
end

--- @param s string
--- @param c string
local function string_startswith(s, c)
    local start_pos = 1
    local end_pos = #c
    if start_pos > end_pos then
        return false
    end
    return s:sub(start_pos, end_pos) == c
end

--- @param s string
--- @param c string
local function string_endswith(s, c)
    local start_pos = #s - #c + 1
    local end_pos = #s
    if start_pos > end_pos then
        return false
    end
    return s:sub(start_pos, end_pos) == c
end

--- @param s string
--- @return boolean
local function string_isspace(s)
    assert(string.len(s) == 1)
    return s:match("%s") ~= nil
end

--- @param s string
--- @return boolean
local function string_isalnum(s)
    assert(string.len(s) == 1)
    return s:match("%w") ~= nil
end

--- @param s string
--- @return boolean
local function string_isdigit(s)
    assert(string.len(s) == 1)
    return s:match("%d") ~= nil
end

--- @param s string
--- @return boolean
local function string_ishex(s)
    assert(string.len(s) == 1)
    return s:match("%x") ~= nil
end

--- @param s string
--- @return boolean
local function string_isalpha(s)
    assert(string.len(s) == 1)
    return s:match("%a") ~= nil
end

--- @param s string
--- @return boolean
local function string_islower(s)
    assert(string.len(s) == 1)
    return s:match("%l") ~= nil
end

--- @param s string
--- @return boolean
local function string_isupper(s)
    assert(string.len(s) == 1)
    return s:match("%u") ~= nil
end

--- @param left number?
--- @param value number
--- @param right number?
--- @return number
local function number_bound(left, value, right)
    return math.min(math.max(left or -2147483648, value), right or 2147483647)
end

-- list index `i` can be positive or negative. `n` is the length of list.
-- if i > 0, i is in range [1,n].
-- if i < 0, i is in range [-1,-n], -1 maps to last position (e.g. n), -n maps to first position (e.g. 1).
--- @param n integer
--- @param i integer
--- @return integer
local function list_index(n, i)
    assert(n > 0)
    assert((i >= 1 and i <= n) or (i <= -1 and i >= -n))
    return i > 0 and i or (n + i + 1)
end

--- @param content string
--- @return string[]
local function parse_flag_query(content)
    local query = ""
    local option = nil

    local flag_pos = string_find(content, "--")
    if type(flag_pos) == "number" and flag_pos > 0 then
        query = vim.trim(string.sub(content, 1, flag_pos - 1))
        option = vim.trim(string.sub(content, flag_pos + 2))
    else
        query = vim.trim(content)
    end
    return { query, option }
end

--- @class ShellOptsContext
--- @field shell string?
--- @field shellslash string?
--- @field shellcmdflag string?
--- @field shellxquote string?
--- @field shellquote string?
--- @field shellredir string?
--- @field shellpipe string?
--- @field shellxescape string?
local ShellOptsContext = {}

--- @return ShellOptsContext
function ShellOptsContext:save()
    local o = constants.is_windows
            and {
                shell = vim.o.shell,
                shellslash = vim.o.shellslash,
                shellcmdflag = vim.o.shellcmdflag,
                shellxquote = vim.o.shellxquote,
                shellquote = vim.o.shellquote,
                shellredir = vim.o.shellredir,
                shellpipe = vim.o.shellpipe,
                shellxescape = vim.o.shellxescape,
            }
        or {
            shell = vim.o.shell,
        }
    setmetatable(o, self)
    self.__index = self

    -- log.debug(
    --     "|fzfx.launch - ShellOptsContext:save| before, shell:%s, shellslash:%s, shellcmdflag:%s, shellxquote:%s, shellquote:%s, shellredir:%s, shellpipe:%s, shellxescape:%s",
    --     vim.inspect(vim.o.shell),
    --     vim.inspect(vim.o.shellslash),
    --     vim.inspect(vim.o.shellcmdflag),
    --     vim.inspect(vim.o.shellxquote),
    --     vim.inspect(vim.o.shellquote),
    --     vim.inspect(vim.o.shellredir),
    --     vim.inspect(vim.o.shellpipe),
    --     vim.inspect(vim.o.shellxescape)
    -- )

    if constants.is_windows then
        vim.o.shell = "cmd.exe"
        vim.o.shellslash = false
        vim.o.shellcmdflag = "/s /c"
        vim.o.shellxquote = '"'
        vim.o.shellquote = ""
        vim.o.shellredir = ">%s 2>&1"
        vim.o.shellpipe = "2>&1| tee"
        vim.o.shellxescape = ""
    else
        vim.o.shell = "sh"
    end

    -- log.debug(
    --     "|fzfx.launch - ShellOptsContext:save| after, shell:%s, shellslash:%s, shellcmdflag:%s, shellxquote:%s, shellquote:%s, shellredir:%s, shellpipe:%s, shellxescape:%s",
    --     vim.inspect(vim.o.shell),
    --     vim.inspect(vim.o.shellslash),
    --     vim.inspect(vim.o.shellcmdflag),
    --     vim.inspect(vim.o.shellxquote),
    --     vim.inspect(vim.o.shellquote),
    --     vim.inspect(vim.o.shellredir),
    --     vim.inspect(vim.o.shellpipe),
    --     vim.inspect(vim.o.shellxescape)
    -- )
    return o
end

function ShellOptsContext:restore()
    if constants.is_windows then
        vim.o.shell = self.shell
        vim.o.shellslash = self.shellslash
        vim.o.shellcmdflag = self.shellcmdflag
        vim.o.shellxquote = self.shellxquote
        vim.o.shellquote = self.shellquote
        vim.o.shellredir = self.shellredir
        vim.o.shellpipe = self.shellpipe
        vim.o.shellxescape = self.shellxescape
    else
        vim.o.shell = self.shell
    end
end

--- @param s string
--- @param special any?
--- @return string
local function shellescape(s, special)
    if constants.is_windows then
        local shellslash = vim.o.shellslash
        vim.o.shellslash = false
        local result = special ~= nil and vim.fn.shellescape(s, special)
            or vim.fn.shellescape(s)
        vim.o.shellslash = shellslash
        return result
    else
        return special ~= nil and vim.fn.shellescape(s, special)
            or vim.fn.shellescape(s)
    end
end

--- @class WindowOptsContext
--- @field bufnr integer
--- @field tabnr integer
--- @field winnr integer
local WindowOptsContext = {}

--- @return WindowOptsContext
function WindowOptsContext:save()
    local o = {
        bufnr = vim.api.nvim_get_current_buf(),
        winnr = vim.api.nvim_get_current_win(),
        tabnr = vim.api.nvim_get_current_tabpage(),
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @return nil
function WindowOptsContext:restore()
    if vim.api.nvim_tabpage_is_valid(self.tabnr) then
        vim.api.nvim_set_current_tabpage(self.tabnr)
    end
    if vim.api.nvim_win_is_valid(self.winnr) then
        vim.api.nvim_set_current_win(self.winnr)
    end
end

--- @class FileLineReader
--- @field filename string
--- @field handler integer
--- @field filesize integer
--- @field offset integer
--- @field batchsize integer
--- @field buffer string?
local FileLineReader = {}

--- @param filename string
--- @param batchsize integer?
--- @return FileLineReader?
function FileLineReader:open(filename, batchsize)
    local handler = vim.loop.fs_open(filename, "r", 438) --[[@as integer]]
    if type(handler) ~= "number" then
        error(
            string.format(
                "|fzfx.utils - FileLineReader:open| failed to fs_open file: %s",
                vim.inspect(filename)
            )
        )
        return nil
    end
    local fstat = vim.loop.fs_fstat(handler) --[[@as table]]
    if type(fstat) ~= "table" then
        error(
            string.format(
                "|fzfx.utils - FileLineReader:open| failed to fs_fstat file: %s",
                vim.inspect(filename)
            )
        )
        vim.loop.fs_close(handler)
        return nil
    end

    local o = {
        filename = filename,
        handler = handler,
        filesize = fstat.size,
        offset = 0,
        batchsize = batchsize or 4096,
        buffer = nil,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @return integer
function FileLineReader:_read_chunk()
    local chunksize = (self.filesize >= self.offset + self.batchsize)
            and self.batchsize
        or (self.filesize - self.offset)
    if chunksize <= 0 then
        return 0
    end
    local data, --[[@as string?]]
        read_err,
        read_name =
        vim.loop.fs_read(self.handler, chunksize, self.offset)
    if read_err then
        error(
            string.format(
                "|fzfx.utils - FileLineReader:_read_chunk| failed to fs_read file: %s, read_error:%s, read_name:%s",
                vim.inspect(self.filename),
                vim.inspect(read_err),
                vim.inspect(read_name)
            )
        )
        return -1
    end
    -- append to buffer
    self.buffer = self.buffer and (self.buffer .. data) or data --[[@as string]]
    self.offset = self.offset + #data
    return #data
end

--- @return boolean
function FileLineReader:has_next()
    self:_read_chunk()
    return self.buffer ~= nil and string.len(self.buffer) > 0
end

--- @return string?
function FileLineReader:next()
    --- @return string?
    local function impl()
        if self.buffer == nil then
            return nil
        end
        local nextpos = string_find(self.buffer, "\n")
        if nextpos then
            local line = self.buffer:sub(1, nextpos - 1)
            self.buffer = self.buffer:sub(nextpos + 1)
            return line
        else
            return nil
        end
    end

    repeat
        local nextline = impl()
        if nextline then
            return nextline
        end
    until self:_read_chunk() <= 0

    local nextline = impl()
    if nextline then
        return nextline
    else
        local buf = self.buffer
        self.buffer = nil
        return buf
    end
end

function FileLineReader:close()
    if self.handler then
        vim.loop.fs_close(self.handler)
        self.handler = nil
    end
end

--- @param filename string
--- @param opts {trim:boolean?}|nil
--- @return string?
local function readfile(filename, opts)
    opts = opts or { trim = true }
    opts.trim = opts.trim == nil and true or opts.trim

    local f = io.open(filename, "r")
    if f == nil then
        return nil
    end
    local content = vim.trim(f:read("*a"))
    f:close()
    return content
end

--- @param filename string
--- @return string[]?
local function readlines(filename)
    local reader = FileLineReader:open(filename) --[[@as FileLineReader]]
    if not reader then
        return nil
    end
    local results = {}
    while reader:has_next() do
        table.insert(results, reader:next())
    end
    reader:close()
    return results
end

--- @param filename string
--- @param content string
--- @return integer
local function writefile(filename, content)
    local f = io.open(filename, "w")
    if not f then
        return -1
    end
    f:write(content)
    f:close()
    return 0
end

--- @param filename string
--- @param lines string[]
--- @return integer
local function writelines(filename, lines)
    local f = io.open(filename, "w")
    if not f then
        return -1
    end
    assert(type(lines) == "table")
    for _, line in ipairs(lines) do
        assert(type(line) == "string")
        f:write(line .. "\n")
    end
    f:close()
    return 0
end

--- @alias AsyncSpawnLineConsumer fun(line:string):any
--- @class AsyncSpawn
--- @field cmds string[]
--- @field fn_out_line_consumer AsyncSpawnLineConsumer
--- @field fn_err_line_consumer AsyncSpawnLineConsumer
--- @field out_pipe uv_pipe_t
--- @field err_pipe uv_pipe_t
--- @field out_buffer string?
--- @field err_buffer string?
--- @field process_handle uv_process_t?
--- @field process_id integer|string|nil
--- @field _close_count integer
--- @field result {code:integer?,signal:integer?}?
local AsyncSpawn = {}

--- @param line string
local function dummy_stderr_line_consumer(line)
    -- if type(line) == "string" then
    --     io.write(string.format("AsyncSpawn:_on_stderr:%s", vim.inspect(line)))
    --     error(string.format("AsyncSpawn:_on_stderr:%s", vim.inspect(line)))
    -- end
end

--- @param cmds string[]
--- @param fn_out_line_consumer AsyncSpawnLineConsumer
--- @param fn_err_line_consumer AsyncSpawnLineConsumer?
--- @return AsyncSpawn?
function AsyncSpawn:make(cmds, fn_out_line_consumer, fn_err_line_consumer)
    local out_pipe = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    local err_pipe = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    if not out_pipe or not err_pipe then
        return nil
    end

    local o = {
        cmds = cmds,
        fn_out_line_consumer = fn_out_line_consumer,
        fn_err_line_consumer = fn_err_line_consumer
            or dummy_stderr_line_consumer,
        out_pipe = out_pipe,
        err_pipe = err_pipe,
        out_buffer = nil,
        err_buffer = nil,
        process_handle = nil,
        process_id = nil,
        _close_count = 0,
        result = nil,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param buffer string
--- @param fn_line_processor AsyncSpawnLineConsumer
--- @return integer
function AsyncSpawn:_consume_line(buffer, fn_line_processor)
    local i = 1
    while i <= #buffer do
        local newline_pos = string_find(buffer, "\n", i)
        if not newline_pos then
            break
        end
        local line = buffer:sub(i, newline_pos - 1)
        fn_line_processor(line)
        i = newline_pos + 1
    end
    return i
end

--- @param handle uv_handle_t
function AsyncSpawn:_close_handle(handle)
    if handle and not handle:is_closing() then
        handle:close(function()
            self._close_count = self._close_count + 1
            if self._close_count >= 3 then
                vim.loop.stop()
            end
        end)
    end
end

--- @param err string?
--- @param data string?
--- @return nil
function AsyncSpawn:_on_stdout(err, data)
    if err then
        self.out_pipe:read_stop()
        self:_close_handle(self.out_pipe)
        return
    end

    if data then
        -- append data to data_buffer
        self.out_buffer = self.out_buffer and (self.out_buffer .. data) or data
        self.out_buffer = self.out_buffer:gsub("\r\n", "\n")
        -- foreach the data_buffer and find every line
        local i = self:_consume_line(self.out_buffer, self.fn_out_line_consumer)
        -- truncate the printed lines if found any
        self.out_buffer = i <= #self.out_buffer
                and self.out_buffer:sub(i, #self.out_buffer)
            or nil
    else
        if self.out_buffer then
            -- foreach the data_buffer and find every line
            local i =
                self:_consume_line(self.out_buffer, self.fn_out_line_consumer)
            if i <= #self.out_buffer then
                local line = self.out_buffer:sub(i, #self.out_buffer)
                self.fn_out_line_consumer(line)
                self.out_buffer = nil
            end
        end
        self.out_pipe:read_stop()
        self:_close_handle(self.out_pipe)
    end
end

--- @param err string?
--- @param data string?
--- @return nil
function AsyncSpawn:_on_stderr(err, data)
    if err then
        io.write(
            string.format(
                "AsyncSpawn:_on_stderr, err:%s, data:%s",
                vim.inspect(err),
                vim.inspect(data)
            )
        )
        error(
            string.format(
                "AsyncSpawn:_on_stderr, err:%s, data:%s",
                vim.inspect(err),
                vim.inspect(data)
            )
        )
        self.err_pipe:read_stop()
        self:_close_handle(self.err_pipe)
        return
    end

    if data then
        -- append data to data_buffer
        self.err_buffer = self.err_buffer and (self.err_buffer .. data) or data
        self.err_buffer = self.err_buffer:gsub("\r\n", "\n")
        -- foreach the data_buffer and find every line
        local i = self:_consume_line(self.err_buffer, self.fn_err_line_consumer)
        -- truncate the printed lines if found any
        self.err_buffer = i <= #self.err_buffer
                and self.err_buffer:sub(i, #self.err_buffer)
            or nil
    else
        if self.err_buffer then
            -- foreach the data_buffer and find every line
            local i =
                self:_consume_line(self.err_buffer, self.fn_err_line_consumer)
            if i <= #self.err_buffer then
                local line = self.err_buffer:sub(i, #self.err_buffer)
                self.fn_err_line_consumer(line)
                self.err_buffer = nil
            end
        end
        self.err_pipe:read_stop()
        self:_close_handle(self.err_pipe)
    end
end

function AsyncSpawn:run()
    self.process_handle, self.process_id = vim.loop.spawn(self.cmds[1], {
        args = vim.list_slice(self.cmds, 2),
        stdio = { nil, self.out_pipe, self.err_pipe },
        hide = true,
        -- verbatim = true,
    }, function(code, signal)
        self.result = { code = code, signal = signal }
        self:_close_handle(self.process_handle)
    end)

    self.out_pipe:read_start(function(err, data)
        self:_on_stdout(err, data)
    end)
    self.err_pipe:read_start(function(err, data)
        self:_on_stderr(err, data)
    end)
    vim.loop.run()

    local max_timeout = 2 ^ 31
    vim.wait(max_timeout, function()
        return self._close_count == 3
    end)
end

local M = {
    get_buf_option = get_buf_option,
    set_buf_option = set_buf_option,
    is_buf_valid = is_buf_valid,
    set_win_option = set_win_option,
    get_win_option = get_win_option,
    string_empty = string_empty,
    string_not_empty = string_not_empty,
    string_find = string_find,
    string_rfind = string_rfind,
    string_ltrim = string_ltrim,
    string_rtrim = string_rtrim,
    string_split = string_split,
    string_startswith = string_startswith,
    string_endswith = string_endswith,
    string_isspace = string_isspace,
    string_isalnum = string_isalnum,
    string_isdigit = string_isdigit,
    string_ishex = string_ishex,
    string_isalpha = string_isalpha,
    string_islower = string_islower,
    string_isupper = string_isupper,
    number_bound = number_bound,
    list_index = list_index,
    parse_flag_query = parse_flag_query,
    ShellOptsContext = ShellOptsContext,
    shellescape = shellescape,
    WindowOptsContext = WindowOptsContext,
    FileLineReader = FileLineReader,
    readfile = readfile,
    readlines = readlines,
    writefile = writefile,
    writelines = writelines,
    AsyncSpawn = AsyncSpawn,
}

return M
