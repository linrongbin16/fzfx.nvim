-- Zero Dependency

local constants = require("fzfx.constants")

--- @param l table?
--- @return boolean
local function list_empty(l)
    return l == nil or #l == 0
end

--- @param l any[]
--- @param f fun(k:any,v:any):boolean
local function list_filter(l, f)
    local result = {}
    for i, v in ipairs(l) do
        if f(i, v) then
            table.insert(result, v)
        end
    end
    return result
end

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
    t = t or "\n\t "
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
    t = t or "\n\t "
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

--- @class ShellOptsContext
--- @field shell string?
--- @field shellslash string?
--- @field shellcmdflag string?
--- @field shellxquote string?
--- @field shellquote string?
--- @field shellredir string?
--- @field shellpipe string?
--- @field shellxescape string?
local ShellOptsContext = {
    shell = nil,
    shellslash = nil,
    shellcmdflag = nil,
    shellxquote = nil,
    shellquote = nil,
    shellredir = nil,
    shellpipe = nil,
    shellxescape = nil,
}

--- @return ShellOptsContext
function ShellOptsContext:save()
    local ctx = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(ShellOptsContext),
        constants.is_windows
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
    )
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
    return ctx
end

--- @return nil
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
--- @class bufnr integer?
--- @class tabnr integer?
--- @class winnr integer?
local WindowOptsContext = {
    bufnr = nil,
    tabnr = nil,
    winnr = nil,
}

--- @return WindowOptsContext
function WindowOptsContext:save()
    return vim.tbl_deep_extend("force", vim.deepcopy(WindowOptsContext), {
        bufnr = vim.api.nvim_get_current_buf(),
        winnr = vim.api.nvim_get_current_win(),
        tabnr = vim.api.nvim_get_current_tabpage(),
    }) --[[@as WindowOptsContext]]
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

local M = {
    list_empty = list_empty,
    list_filter = list_filter,
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
    ShellOptsContext = ShellOptsContext,
    shellescape = shellescape,
    WindowOptsContext = WindowOptsContext,
}

return M
