-- Zero Dependency

local constants = require("fzfx.constants")

--- @param path string
--- @param backslash boolean?
--- @return string
local function normalize(path, backslash)
    backslash = backslash or false
    local result = path
    if string.match(result, [[\\]]) then
        result = string.gsub(result, [[\\]], [[\]])
    end
    if backslash and string.match(result, [[\]]) then
        result = string.gsub(result, [[\]], [[/]])
    end
    return vim.trim(result)
end

local function join(...)
    return table.concat({ ... }, constants.path_separator)
end

--- @return string
local function base_dir()
    return vim.fn["fzfx#nvim#base_dir"]()
end

--- @param path string?
--- @return string
local function shorten(path)
    local dir_path = vim.fn.fnamemodify(path or vim.fn.getcwd(), ":~:.")
    local shorten_path = vim.fn.pathshorten(dir_path)
    return shorten_path
end

local M = {
    -- path
    normalize = normalize,
    join = join,
    shorten = shorten,

    -- plugin dir
    base_dir = base_dir,
}

return M
