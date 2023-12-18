local M = {}

M.FileLineReader = require("fzfx.commons.fileios").FileLineReader

--- @param filename string
--- @param opts {trim:boolean?}|nil  by default opts={trim=true}
--- @return string?
M.readfile = function(filename, opts)
  opts = opts or { trim = true }
  opts.trim = type(opts.trim) == "boolean" and opts.trim or true
  return require("fzfx.commons.fileios").readfile(filename, opts)
end

--- @param filename string
--- @param on_complete fun(data:string?):nil
--- @param opts {trim:boolean?}|nil  by default opts={trim=true}
M.asyncreadfile = function(filename, on_complete, opts)
  opts = opts or { trim = true }
  opts.trim = type(opts.trim) == "boolean" and opts.trim or true
  return require("fzfx.commons.fileios").asyncreadfile(
    filename,
    on_complete,
    opts
  )
end

--- @param filename string
--- @return string[]|nil
M.readlines = function(filename)
  return require("fzfx.commons.fileios").readlines(filename)
end

--- @param filename string
--- @param content string
--- @return integer
M.writefile = function(filename, content)
  return require("fzfx.commons.fileios").writefile(filename, content)
end

--- @param filename string
--- @param content string
--- @param on_complete fun(bytes:integer?):any
M.asyncwritefile = function(filename, content, on_complete)
  return require("fzfx.commons.fileios").asyncwritefile(
    filename,
    content,
    on_complete
  )
end

--- @param filename string
--- @param lines string[]
--- @return integer
M.writelines = function(filename, lines)
  return require("fzfx.commons.fileios").writelines(filename, lines)
end

return M
