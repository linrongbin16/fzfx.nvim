-- No Setup Need

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

--- @param p string?
--- @return string
local function shorten(p)
    local dir_path = vim.fn.fnamemodify(p or vim.fn.getcwd(), ":~:.")
    local shorten_path = vim.fn.pathshorten(dir_path)
    return shorten_path
end

--- @param p string?
--- @return string
local function reduce(p)
    return vim.fn.fnamemodify(p or vim.fn.getcwd(), ":~:.")
end

local M = {
    -- path
    normalize = normalize,
    join = join,
    shorten = shorten,
    reduce = reduce,

    -- plugin dir
    base_dir = base_dir,
}

return M
