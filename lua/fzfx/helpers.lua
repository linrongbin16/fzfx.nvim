local log = require("fzfx.log")
local env = require("fzfx.env")

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

-- job.stdout buffer {

--- @class StdoutLine
--- @field data string[]
--- @field done boolean
local StdoutLine = {
    data = {},
    done = false,
}

function StdoutLine:new()
    return vim.tbl_deep_extend("force", vim.deepcopy(StdoutLine), {})
end

--- @param raw_data string
function StdoutLine:push(raw_data)
    assert(
        type(raw_data) == "string",
        string.format(
            "|fzfx.helpers - StdoutLine:push| error! stdout line data must be a valid string! raw_data:%s",
            vim.inspect(raw_data)
        )
    )
    if string.len(raw_data) > 0 then
        table.insert(self.data, raw_data)
    end
    if string.len(raw_data) == 0 then
        self.done = true
    end
    log.debug(
        "|fzfx.helpers - StdoutLine:push| self.data:%s, raw_data:%s",
        vim.inspect(self.data),
        vim.inspect(raw_data)
    )
end

function StdoutLine:finished()
    return self.done
end

function StdoutLine:print()
    return table.concat(self.data, "")
end

-- FIFO buffer, push at tail, cut from head
--- @class StdoutBuffer
--- @field lines StdoutLine[]
local StdoutBuffer = {
    lines = {},
}

function StdoutBuffer:new()
    return vim.tbl_deep_extend("force", vim.deepcopy(StdoutBuffer), {})
end

-- push at tail
--- @param raw_data string
--- @return nil
function StdoutBuffer:push(raw_data)
    local last_line = self:last()
    if last_line ~= nil and not last_line:finished() then
        last_line:push(raw_data)
        log.debug(
            "|fzfx.helpers - StdoutBuffer:push| last_line, self:%s, raw_data:%s",
            vim.inspect(self),
            vim.inspect(raw_data)
        )
    else
        local new_line = StdoutLine:new()
        new_line:push(raw_data)
        table.insert(self.lines, new_line)
        log.debug(
            "|fzfx.helpers - StdoutBuffer:push| new_line, self:%s, raw_data:%s",
            vim.inspect(self),
            vim.inspect(raw_data)
        )
    end
end

-- cut from head
--- @param pos integer
--- @return nil
function StdoutBuffer:cut(pos)
    assert(
        pos > 0,
        "|fzfx.helpers - StdoutBuffer:cut| error! pos '%s' cannot be less or equal than 0",
        vim.inspect(pos)
    )
    if #self.lines == 0 then
        log.debug(
            "|fzfx.helpers - StdoutBuffer:pop| error! nil, pos:%s, self:%s, result:nil",
            vim.inspect(pos),
            vim.inspect(self)
        )
        return
    end
    assert(
        pos <= #self.lines,
        "|fzfx.helpers - StdoutBuffer:cut| error! pos '%s' cannot be greater than #self.lines '%s'",
        vim.inspect(pos),
        vim.inspect(#self.lines)
    )
    if pos > #self.lines then
        pos = #self.lines
    end
    local result = self.lines[1]
    table.remove(self.lines, #self.lines)
    log.debug(
        "|fzfx.helpers - StdoutBuffer:pop| self:%s, result:%s",
        vim.inspect(self),
        vim.inspect(result)
    )
    return result
end

--- @return StdoutLine|nil
function StdoutBuffer:last()
    log.debug("|fzfx.helpers - StdoutBuffer:last| self:%s", vim.inspect(self))
    if #self.lines == 0 then
        return nil
    end
    return self.lines[#self.lines]
end

--- @return StdoutLine|nil
function StdoutBuffer:first()
    log.debug("|fzfx.helpers - StdoutBuffer:first| self:%s", vim.inspect(self))
    if #self.lines == 0 then
        return nil
    end
    return self.lines[1]
end

--- @return integer
function StdoutBuffer:size()
    log.debug("|fzfx.helpers - StdoutBuffer:size| self:%s", vim.inspect(self))
    return #self.lines
end

--- @param index integer
--- @return StdoutLine|nil
function StdoutBuffer:get(index)
    log.debug(
        "|fzfx.helpers - StdoutBuffer:get| self:%s, index:%s",
        vim.inspect(self),
        vim.inspect(index)
    )
    if #self.lines == 0 then
        return nil
    end
    return self.lines[index]
end

-- job.stdout buffer }

local M = {
    visual_select,
    StdoutLine = StdoutLine,
    StdoutBuffer = StdoutBuffer,
}

return M
