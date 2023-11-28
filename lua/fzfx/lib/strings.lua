local M = {}

--- @param s any
--- @return boolean
M.empty = function(s)
  return type(s) ~= "string" or string.len(s) == 0
end

--- @param s any
--- @return boolean
M.not_empty = function(s)
  return type(s) == "string" and string.len(s) > 0
end

--- @param s any
--- @return boolean
M.blank = function(s)
  return type(s) ~= "string" or string.len(vim.trim(s)) == 0
end

--- @param s any
--- @return boolean
M.not_blank = function(s)
  return type(s) == "string" and string.len(vim.trim(s)) > 0
end

--- @param s string
--- @param t string
--- @param start integer?  by default start=1
--- @return integer?
M.find = function(s, t, start)
  start = start or 1
  for i = start, #s do
    local match = true
    for j = 1, #t do
      if i + j - 1 > #s then
        match = false
        break
      end
      local a = string.byte(s, i + j - 1)
      local b = string.byte(t, j)
      if a ~= b then
        match = false
        break
      end
    end
    if match then
      return i
    end
  end
  return nil
end

--- @param s string
--- @param t string
--- @param rstart integer?  by default rstart=#s
--- @return integer?
M.rfind = function(s, t, rstart)
  rstart = rstart or #s
  for i = rstart, 1, -1 do
    local match = true
    for j = 1, #t do
      if i + j - 1 > #s then
        match = false
        break
      end
      local a = string.byte(s, i + j - 1)
      local b = string.byte(t, j)
      if a ~= b then
        match = false
        break
      end
    end
    if match then
      return i
    end
  end
  return nil
end

--- @param s string
--- @param t string?  by default t is whitespace
--- @return string
M.ltrim = function(s, t)
  t = t or "\n\t\r "
  local i = 1
  while i <= #s do
    local c = string.byte(s, i)
    local contains = false
    for j = 1, #t do
      if string.byte(t, j) == c then
        contains = true
        break
      end
    end
    if not contains then
      break
    end
    i = i + 1
  end
  return s:sub(i, #s)
end

--- @param s string
--- @param t string?  by default t is whitespace
--- @return string
M.rtrim = function(s, t)
  t = t or "\n\t\r "
  local i = #s
  while i >= 1 do
    local c = string.byte(s, i)
    local contains = false
    for j = 1, #t do
      if string.byte(t, j) == c then
        contains = true
        break
      end
    end
    if not contains then
      break
    end
    i = i - 1
  end
  return s:sub(1, i)
end

--- @param s string
--- @param delimiter string
--- @param opts {plain:boolean?,trimempty:boolean?}|nil  by default opts={plain=true,trimempty=true}
--- @return string[]
M.split = function(s, delimiter, opts)
  opts = opts or {
    plain = true,
    trimempty = true,
  }
  opts.plain = opts.plain == nil and true or opts.plain
  opts.trimempty = opts.trimempty == nil and true or opts.trimempty
  return vim.split(s, delimiter, opts)
end

--- @param s string
--- @param t string
--- @return boolean
M.startswith = function(s, t)
  assert(type(s) == "string")
  assert(type(t) == "string")
  return string.len(s) >= string.len(t) and s:sub(1, #t) == t
end

--- @param s string
--- @param t string
--- @return boolean
M.endswith = function(s, t)
  assert(type(s) == "string")
  assert(type(t) == "string")
  return string.len(s) >= string.len(t) and s:sub(#s - #t + 1) == t
end

--- @param s string
--- @return boolean
M.isspace = function(s)
  assert(string.len(s) == 1)
  return s:match("%s") ~= nil
end

--- @param s string
--- @return boolean
M.isalnum = function(s)
  assert(string.len(s) == 1)
  return s:match("%w") ~= nil
end

--- @param s string
--- @return boolean
M.isdigit = function(s)
  assert(string.len(s) == 1)
  return s:match("%d") ~= nil
end

--- @param s string
--- @return boolean
M.ishex = function(s)
  assert(string.len(s) == 1)
  return s:match("%x") ~= nil
end

--- @param s string
--- @return boolean
M.isalpha = function(s)
  assert(string.len(s) == 1)
  return s:match("%a") ~= nil
end

--- @param s string
--- @return boolean
M.islower = function(s)
  assert(string.len(s) == 1)
  return s:match("%l") ~= nil
end

--- @param s string
--- @return boolean
M.isupper = function(s)
  assert(string.len(s) == 1)
  return s:match("%u") ~= nil
end

--- @param delimiter string?  by default '-'
--- @return string
M.uuid = function(delimiter)
  delimiter = delimiter or "-"
  local secs, ms = vim.loop.gettimeofday()
  return table.concat({
    string.format("%x", vim.loop.os_getpid()),
    string.format("%x", secs),
    string.format("%x", ms),
    string.format("%x", math.random(1, require("fzfx.lib.numbers").INT32_MAX)),
  }, delimiter)
end

return M
