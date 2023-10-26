-- No Setup Need

local constants = require("fzfx.constants")

--- @param path string
--- @param opts {transform_backslash:boolean?}?
--- @return string
local function normalize(path, opts)
    opts = opts or {}
    opts.transform_backslash = opts.transform_backslash or false

    local result = path
    if string.match(result, [[\\]]) then
        result = string.gsub(result, [[\\]], [[\]])
    end
    if opts.transform_backslash and string.match(result, [[\]]) then
        result = string.gsub(result, [[\]], [[/]])
    end
    return vim.trim(result)
end

local function join(...)
    return table.concat({ ... }, constants.path_separator)
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

--- @param p string?
--- @return string
local function reduce2home(p)
    return vim.fn.fnamemodify(p or vim.fn.getcwd(), ":~")
end

local M = {
    normalize = normalize,
    join = join,
    shorten = shorten,
    reduce = reduce,
    reduce2home = reduce2home,
}

return M
