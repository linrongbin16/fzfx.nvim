local line_helpers = require("fzfx.line_helpers")

--- @package
--- @param opts {no_icon:boolean?}?
--- @return PreviewerLabel
local function _make_find_previewer_label(opts)
    --- @param line string?
    --- @param context PipelineContext
    --- @return string?
    local function impl(line, context)
        if type(line) ~= "string" or string.len(line) == 0 then
            return nil
        end
        return vim.fn.fnamemodify(line_helpers.parse_find(line, opts), ":t")
    end
    return impl
end

--- @param line string?
--- @param context PipelineContext
--- @return string?
local function find_previewer_label(line, context)
    local f = _make_find_previewer_label()
    return f(line, context)
end

local M = {
    find_previewer_label = find_previewer_label,
}

return M
