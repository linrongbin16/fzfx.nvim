local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")

local M = {}

M.SEPARATOR = consts.IS_WINDOWS and "\\" or "/"

--- @param p string
--- @param opts {backslash:boolean?,expand:boolean?}?
--- @return string
M.normalize = function(p, opts)
  opts = opts or { backslash = false, expand = false }
  opts.backslash = type(opts.backslash) == "boolean" and opts.backslash or false
  opts.expand = type(opts.expand) == "boolean" and opts.expand or false

  local result = p
  if string.match(result, [[\\]]) then
    result = string.gsub(result, [[\\]], [[\]])
  end
  if opts.backslash and string.match(result, [[\]]) then
    result = string.gsub(result, [[\]], [[/]])
  end
  return opts.expand and vim.fn.expand(vim.trim(result)) --[[@as string]]
    or vim.trim(result)
end

--- @param ... any
--- @return string
M.join = function(...)
  return table.concat({ ... }, M.SEPARATOR)
end

--- @param p string?
--- @return string
M.reduce2home = function(p)
  return vim.fn.fnamemodify(p or vim.fn.getcwd(), ":~") --[[@as string]]
end

--- @param p string?
--- @return string
M.reduce = function(p)
  return vim.fn.fnamemodify(p or vim.fn.getcwd(), ":~:.") --[[@as string]]
end

--- @param p string?
--- @return string
M.shorten = function(p)
  return vim.fn.pathshorten(M.reduce(p)) --[[@as string]]
end

--- @return string
M.make_pipe_name = function()
  if consts.IS_WINDOWS then
    return string.format([[\\.\pipe\nvim-pipe-%s]], strs.uuid())
  else
    return vim.fn.tempname() --[[@as string]]
  end
end

return M
