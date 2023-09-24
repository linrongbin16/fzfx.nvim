-- No Setup Need

local constants = require("fzfx.constants")

--- @param bufnr integer
--- @param name string
--- @return any
local function get_buf_option(bufnr, name)
    if vim.fn.has("nvim-0.7") > 0 then
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
    if vim.fn.has("nvim-0.7") > 0 then
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
    if vim.fn.has("nvim-0.7") > 0 then
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
    if vim.fn.has("nvim-0.7") > 0 then
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
--- @param c string
--- @param start integer?
--- @return integer?
local function string_find(s, c, start)
    start = start or 1
    for i = start, #s do
        if string.byte(s, i) == string.byte(c) then
            return i
        end
    end
    return nil
end

--- @param s string
--- @param c string
--- @param rstart integer?
--- @return integer?
local function string_rfind(s, c, rstart)
    rstart = rstart or #s
    for i = rstart, 1, -1 do
        if string.byte(s, i) == string.byte(c) then
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
--- @param delimiter string?
--- @param filter_empty boolean?
--- @return string[]
local function string_split(s, delimiter, filter_empty)
    delimiter = delimiter or " \t\n\r"
    filter_empty = filter_empty ~= nil and filter_empty or true

    --- @param v string
    --- @return boolean
    local function delim_contains(v)
        return string_find(delimiter, v) ~= nil
    end

    local result = {}
    local prev = 1
    local i = 1
    while i <= #s do
        local c = s:sub(i, i)
        if delim_contains(c) then
            local item = s:sub(prev, i - 1)
            if not filter_empty or string.len(item) > 0 then
                table.insert(result, item)
            end
            prev = i + 1
        end
        i = i + 1
    end
    if prev <= #s then
        local item = s:sub(prev, #s)
        if not filter_empty or string.len(item) > 0 then
            table.insert(result, s:sub(prev, #s))
        end
    end
    return result
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

--- @param left number?
--- @param value number
--- @param right number?
--- @return number
local function number_bound(left, value, right)
    return math.min(math.max(left or -2147483648, value), right or 2147483647)
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
--- @return string?
local function readfile(filename)
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
    number_bound = number_bound,
    parse_flag_query = parse_flag_query,
    ShellOptsContext = ShellOptsContext,
    shellescape = shellescape,
    WindowOptsContext = WindowOptsContext,
    FileLineReader = FileLineReader,
    readfile = readfile,
    readlines = readlines,
}

return M
