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

--- @param parser fun(line:string,context:VimCommandsPipelineContext|VimKeyMapsPipelineContext):table|string
--- @param default_value string
--- @return fun(line:string,context:VimCommandsPipelineContext|VimKeyMapsPipelineContext):string?
local function _make_vim_command_previewer_label(parser, default_value)
    --- @param line string?
    --- @param context VimCommandsPipelineContext
    --- @return string
    local function impl(line, context)
        if type(line) ~= "string" or string.len(line) == 0 then
            return ""
        end
        local parsed = parser(line, context)
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
        return default_value
    end
    return impl
end

local vim_command_previewer_label = _make_vim_command_previewer_label(
    line_helpers.parse_vim_command,
    "Definition"
)
local vim_keymap_previewer_label = _make_vim_command_previewer_label(
    line_helpers.parse_vim_keymap,
    "Definition"
)

--- @param parser fun(line:string):table|string
--- @return fun(line:string):string?
local function _make_ls_previewer_label(parser)
    --- @param line string
    --- @return string?
    local function impl(line)
        if type(line) ~= "string" or string.len(line) == 0 then
            return ""
        end
        return parser(line) --[[@as string]]
    end
    return impl
end

local ls_previewer_label = _make_ls_previewer_label(line_helpers.parse_ls)
local lsd_previewer_label = _make_ls_previewer_label(line_helpers.parse_lsd)
local eza_previewer_label = _make_ls_previewer_label(line_helpers.parse_eza)

local M = {
    -- find/buffers/git files
    _make_find_previewer_label = _make_find_previewer_label,
    find_previewer_label = find_previewer_label,

    -- rg/grep
    _make_rg_previewer_label = _make_rg_previewer_label,
    rg_previewer_label = rg_previewer_label,
    _make_grep_previewer_label = _make_grep_previewer_label,
    grep_previewer_label = grep_previewer_label,

    -- command/keymap
    _make_vim_command_previewer_label = _make_vim_command_previewer_label,
    vim_command_previewer_label = vim_command_previewer_label,
    vim_keymap_previewer_label = vim_keymap_previewer_label,

    -- file explorer
    _make_ls_previewer_label = _make_ls_previewer_label,
    ls_previewer_label = ls_previewer_label,
    lsd_previewer_label = lsd_previewer_label,
    eza_previewer_label = eza_previewer_label,
}

return M
