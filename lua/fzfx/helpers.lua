local log = require("fzfx.log")
local env = require("fzfx.env")
local path = require("fzfx.path")
local color = require("fzfx.color")
local conf = require("fzfx.config")

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
        "|fzfx.helpers - get_visual_lines| mode:%s, start_pos:%s, end_pos:%s",
        vim.inspect(mode),
        vim.inspect(start_pos),
        vim.inspect(end_pos)
    )
    log.debug(
        "|fzfx.helper - get_visual_lines| line_start:%s, line_end:%s, column_start:%s, column_end:%s",
        vim.inspect(line_start),
        vim.inspect(line_end),
        vim.inspect(column_start),
        vim.inspect(column_end)
    )

    local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
    if #lines == 0 then
        log.debug("|fzfx.helpers - get_visual_lines| empty lines")
        return ""
    end

    local cursor_pos = vim.fn.getpos(".")
    local cursor_line = cursor_pos[2]
    local cursor_column = cursor_pos[3]
    log.debug(
        "|fzfx.helpers - get_visual_lines| cursor_pos:%s, cursor_line:%s, cursor_column:%s",
        vim.inspect(cursor_pos),
        vim.inspect(cursor_line),
        vim.inspect(cursor_column)
    )
    if mode == "v" or mode == "\22" then
        local offset = string.lower(vim.o.selection) == "inclusive" and 1 or 2
        lines[#lines] = string.sub(lines[#lines], 1, column_end - offset + 1)
        lines[1] = string.sub(lines[1], column_start)
        log.debug(
            "|fzfx.helpers - get_visual_lines| v or \\22, lines:%s",
            vim.inspect(lines)
        )
    elseif mode == "V" then
        if #lines == 1 then
            lines[1] = vim.fn.trim(lines[1])
        end
        log.debug(
            "|fzfx.helpers - get_visual_lines| V, lines:%s",
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

-- fzf opts {

-- color design based on doc: https://man.archlinux.org/man/fzf.1.en
-- we can assume:
-- BG group
--  * bg (background): Normal bg (s:dark_bg)
--  * bg+ (background current line): CursorLine bg
--  * info (info line: right side numbers): PreProc fg
--  * border (border): Ignore bg (not sure, s:dark_bg + 3, candidates: MatchParen, Ignore, DiffChange)
--  * spinner (input indicator: > ): Statement bg (not sure, candidates: Statement, diffAdded)
--  * hl (highlighted substring): Comment bg
-- FG group
--  * fg (text): Normal fg (s:dark_fg)
--  * header (text): Comment fg
--  * fg+ (text): Normal fg (s:dark_fg)
--  * pointer (pointer to current line): Exception fg
--  * marker (selected lines): Keyword fg
--  * prompt (prompt text): Conditional fg
--  * hl+ (highlighted substring current line): Statement fg (not sure, candidates: Statement, diffAdded)
local function make_fzf_color_opts(opts) end

--- @param opts Config
--- @return string|nil
local function make_fzf_opts(opts)
    if opts == nil or #opts == 0 then
        return nil
    end
    local result = {}
    for _, o in ipairs(opts) do
        if type(o) == "string" and string.len(o) > 0 then
            table.insert(result, o)
        elseif type(o) == "table" and #o == 2 then
            local k = o[1]
            local v = o[2]
            table.insert(
                result,
                string.format("%s %s", k, vim.fn.shellescape(v))
            )
        else
            log.throw(
                "|fzfx.helpers - make_fzf_opts| invalid fzf option: %s",
                vim.inspect(o)
            )
        end
    end
    return table.concat(result, " ")
end

-- fzf opts }

-- provider switch {

--- @class Switch
--- @field name string|nil
--- @field current string|nil
--- @field next string|nil
--- @field tempfile string|nil
local Switch = {
    name = nil,
    current = nil,
    next = nil,
    tempfile = nil,
}

--- @param name string
--- @param current string
--- @param next string
--- @return Switch
function Switch:new(name, current, next)
    local switch = vim.tbl_deep_extend("force", vim.deepcopy(Switch), {
        name = name,
        current = current,
        next = next,
        tempfile = env.debug_enable() and path.join(
            vim.fn.stdpath("data"),
            "fzfx.nvim",
            "switch_" .. name
        ) or vim.fn.tempname(),
    })
    vim.fn.writefile({ switch.current }, switch.tempfile, "b")
    log.debug("|fzfx.helpers - Switch:new| switch:%s", vim.inspect(switch))
    return switch
end

function Switch:switch()
    local tmp = self.next
    self.next = self.current
    self.current = tmp
    vim.fn.writefile({ self.current }, self.tempfile, "b")
end

-- provider switch }

local M = {
    visual_select = visual_select,
    make_fzf_opts = make_fzf_opts,
    Switch = Switch,
}

return M
