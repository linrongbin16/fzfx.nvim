local log = require("fzfx.log")
local path = require("fzfx.path")
local env = require("fzfx.env")
local color = require("fzfx.color")

-- vim {

local function table_filter(f, t)
    local result = {}
    for k, v in pairs(t) do
        if f(k, v) then
            result[k] = v
        end
    end
    return result
end

local function list_filter(f, l)
    local result = {}
    for i, v in ipairs(l) do
        if f(i, v) then
            table.insert(result, v)
        end
    end
    return result
end

-- vim }

-- visual select {

--- @param mode string
--- @return string
local function get_visual_lines(mode)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local line_start = start_pos[2]
    local column_start = start_pos[3]
    local line_end = end_pos[2]
    local column_end = end_pos[3]
    line_start = math.min(line_start, line_end)
    line_end = math.max(line_start, line_end)
    column_start = math.min(column_start, column_end)
    column_end = math.max(column_start, column_end)
    log.debug(
        "|fzfx.utils - get_visual_lines| mode:%s, start_pos:%s, end_pos:%s",
        vim.inspect(mode),
        vim.inspect(start_pos),
        vim.inspect(end_pos)
    )
    log.debug(
        "|fzfx.utils - get_visual_lines| line_start:%s, line_end:%s, column_start:%s, column_end:%s",
        vim.inspect(line_start),
        vim.inspect(line_end),
        vim.inspect(column_start),
        vim.inspect(column_end)
    )

    local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
    if #lines == 0 then
        log.debug("|fzfx.utils - get_visual_lines| empty lines")
        return ""
    end

    local cursor_pos = vim.fn.getpos(".")
    local cursor_line = cursor_pos[2]
    local cursor_column = cursor_pos[3]
    log.debug(
        "|fzfx.utils - get_visual_lines| cursor_pos:%s, cursor_line:%s, cursor_column:%s",
        vim.inspect(cursor_pos),
        vim.inspect(cursor_line),
        vim.inspect(cursor_column)
    )
    if mode == "v" or mode == "\22" then
        local offset = string.lower(vim.o.selection) == "inclusive" and 1 or 2
        lines[#lines] = string.sub(lines[#lines], 1, column_end - offset + 1)
        lines[1] = string.sub(lines[1], column_start)
        log.debug(
            "|fzfx.utils - get_visual_lines| v or \\22, lines:%s",
            vim.inspect(lines)
        )
    elseif mode == "V" then
        if #lines == 1 then
            lines[1] = vim.fn.trim(lines[1])
        end
        log.debug(
            "|fzfx.utils - get_visual_lines| V, lines:%s",
            vim.inspect(lines)
        )
    end
    return table.concat(lines, "\n")
end

--- @return string
local function visual_select()
    vim.cmd([[ execute "normal! \<ESC>" ]])
    local mode = vim.fn.visualmode()
    if mode == "v" or mode == "V" or mode == "\22" then
        return get_visual_lines(mode)
    end
    return ""
end

-- visual select }

--- @class FileSwitch
--- @field value string|nil
--- @field next string|nil
--- @field swap string|nil
local FileSwitch = {
    value = nil,
    next = nil,
    swap = nil,
}

--- @param name string
--- @param value string[]
--- @param next_value string[]
--- @return FileSwitch
function FileSwitch:new(name, value, next_value)
    local init = env.debug_enable()
            and {
                value = string.format(
                    "%s%sfzfx.nvim%s%s_value",
                    vim.fn.stdpath("data"),
                    path.sep(),
                    path.sep(),
                    name
                ),
                next = string.format(
                    "%s%sfzfx.nvim%s%s_next",
                    vim.fn.stdpath("data"),
                    path.sep(),
                    path.sep(),
                    name
                ),
                swap = string.format(
                    "%s%sfzfx.nvim%s%s_swap",
                    vim.fn.stdpath("data"),
                    path.sep(),
                    path.sep(),
                    name
                ),
            }
        or {
            value = path.tempname(),
            next = path.tempname(),
            swap = path.tempname(),
        }
    --- @type FileSwitch
    local switch = vim.tbl_deep_extend("force", vim.deepcopy(FileSwitch), init)
    vim.fn.writefile(value, switch.value, "b")
    vim.fn.writefile(next_value, switch.next, "b")
    return switch
end

--- @return string
function FileSwitch:switch()
    -- value => swap, next => value, swap => next
    return string.format(
        "mv %s %s && mv %s %s && mv %s %s",
        self.value,
        self.swap,
        self.next,
        self.value,
        self.swap,
        self.next
    )
end

local ShellContext = {
    nvim_path = nil,
}

--- @param action string
--- @return string
local function unrestricted_mode_header(action)
    return string.format(
        ":: Press %s to unrestricted mode",
        color.magenta(string.upper(action))
    )
end

--- @param action string
--- @return string
local function restricted_mode_header(action)
    return string.format(
        ":: Press %s to restricted mode",
        color.magenta(string.upper(action))
    )
end

local M = {
    table_filter = table_filter,
    list_filter = list_filter,
    visual_select = visual_select,
    FileSwitch = FileSwitch,
    unrestricted_mode_header = unrestricted_mode_header,
    restricted_mode_header = restricted_mode_header,
}

return M
