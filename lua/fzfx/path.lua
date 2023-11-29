-- No Setup Need

local ps = require("fzfx.lib.paths")

--- @param path string
--- @param opts {backslash:boolean?,expand:boolean?}?
--- @return string
local function normalize(path, opts)
  opts = opts or {}
  opts.backslash = type(opts.backslash) == "boolean" and opts.backslash or false
  opts.expand = type(opts.expand) == "boolean" and opts.expand or false

  local result = path
  if string.match(result, [[\\]]) then
    result = string.gsub(result, [[\\]], [[\]])
  end
  if opts.backslash and string.match(result, [[\]]) then
    result = string.gsub(result, [[\]], [[/]])
  end
  return opts.expand and vim.fn.expand(vim.trim(result)) --[[@as string]]
    or vim.trim(result)
end

local function join(...)
  return table.concat({ ... }, ps.SEPARATOR)
end

--- @param p string?
--- @return string
local function reduce2home(p)
  return vim.fn.fnamemodify(p or vim.fn.getcwd(), ":~") --[[@as string]]
end

--- @param p string?
--- @return string
local function reduce(p)
  return vim.fn.fnamemodify(p or vim.fn.getcwd(), ":~:.") --[[@as string]]
end

--- @param p string?
--- @return string
local function shorten(p)
  return vim.fn.pathshorten(reduce(p)) --[[@as string]]
end

local M = {
  normalize = normalize,
  join = join,
  shorten = shorten,
  reduce = reduce,
  reduce2home = reduce2home,
}

return M
