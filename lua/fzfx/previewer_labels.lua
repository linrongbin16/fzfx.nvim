local line_helpers = require("fzfx.line_helpers")

--- @package
--- @param opts {no_icon:boolean?}?
--- @return PreviewerLabel
local function _make_find_previewer_label(opts)
    --- @param line string?
    --- @return string?
    local function impl(line)
        if type(line) ~= "string" or string.len(line) == 0 then
            return ""
        end
        return vim.fn.fnamemodify(line_helpers.parse_find(line, opts), ":t")
    end
    return impl
end

--- @param line string?
--- @return string?
local function find_previewer_label(line)
    local f = _make_find_previewer_label()
    return f(line)
end

--- @package
--- @param opts {no_icon:boolean?}?
--- @return PreviewerLabel
local function _make_rg_previewer_label(opts)
    --- @param line string?
    --- @return string?
    local function impl(line)
        if type(line) ~= "string" or string.len(line) == 0 then
            return ""
        end
        local parsed = line_helpers.parse_rg(line, opts)
        return string.format(
            "%s:%d:%d",
            vim.fn.fnamemodify(parsed.filename, ":t"),
            parsed.lineno,
            parsed.column
        )
    end
    return impl
end

--- @param line string?
--- @return string?
local function rg_previewer_label(line)
    local f = _make_rg_previewer_label()
    return f(line)
end

--- @package
--- @param opts {no_icon:boolean?}?
--- @return PreviewerLabel
local function _make_grep_previewer_label(opts)
    --- @param line string?
    --- @return string?
    local function impl(line)
        if type(line) ~= "string" or string.len(line) == 0 then
            return ""
        end
        local parsed = line_helpers.parse_grep(line, opts)
        return string.format(
            "%s:%d",
            vim.fn.fnamemodify(parsed.filename, ":t"),
            parsed.lineno
        )
    end
    return impl
end

--- @param line string?
--- @return string?
local function grep_previewer_label(line)
    local f = _make_grep_previewer_label()
    return f(line)
end

--- @param line string?
--- @param context VimCommandsPipelineContext
--- @return string
local function vim_commands_previewer_label(line, context)
    if type(line) ~= "string" or string.len(line) == 0 then
        return ""
    end
    local parsed = line_helpers.parse_vim_command(line, context)
    if
        type(parsed) == "table"
        and type(parsed.filename) == "string"
        and string.len(parsed.filename) > 0
        and type(parsed.lineno) == "number"
    then
        return string.format(
            "%s:%d",
            vim.fn.fnamemodify(parsed.filename, ":t"),
            parsed.lineno
        )
    end
    return "Description"
end

local M = {
    -- find/buffers/git files
    _make_find_previewer_label = _make_find_previewer_label,
    find_previewer_label = find_previewer_label,

    -- rg/grep
    _make_rg_previewer_label = _make_rg_previewer_label,
    rg_previewer_label = rg_previewer_label,
    _make_grep_previewer_label = _make_grep_previewer_label,
    grep_previewer_label = grep_previewer_label,
}

return M
