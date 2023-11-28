local M = {}

--- @param t any?
--- @return boolean
M.tbl_empty = function(t)
  return t == nil or vim.tbl_isempty(t)
end

--- @param t any?
--- @return boolean
M.tbl_not_empty = function(t)
  return t ~= nil and not vim.tbl_isempty(t)
end

--- @param l any?
--- @return boolean
M.list_empty = function(l)
  return l == nil or #l == 0
end

--- @param l any?
--- @return boolean
M.list_not_empty = function(l)
  return l ~= nil and #l > 0
end

-- list index `i` support both positive or negative. `n` is the length of list.
-- if i > 0, i is in range [1,n].
-- if i < 0, i is in range [-1,-n], -1 maps to last position (e.g. n), -n maps to first position (e.g. 1).
--- @param n integer
--- @param i integer
--- @return integer
M.list_index = function(n, i)
  assert(n > 0)
  assert((i >= 1 and i <= n) or (i <= -1 and i >= -n))
  return i > 0 and i or (n + i + 1)
end

return M
