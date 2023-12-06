local M = {}

--- @param t any?
--- @return boolean
M.tbl_empty = function(t)
  return type(t) ~= "table" or vim.tbl_isempty(t)
end

--- @param t any?
--- @return boolean
M.tbl_not_empty = function(t)
  return type(t) == "table" and not vim.tbl_isempty(t)
end

--- @param l any?
--- @return boolean
M.list_empty = function(l)
  return type(l) ~= "table" or #l == 0
end

--- @param l any?
--- @return boolean
M.list_not_empty = function(l)
  return type(l) == "table" and #l > 0
end

-- list index `i` support both positive or negative. `n` is the length of list.
-- if i > 0, i is in range [1,n].
-- if i < 0, i is in range [-1,-n], -1 maps to last position (e.g. n), -n maps to first position (e.g. 1).
--- @param i integer
--- @param n integer
--- @return integer
M.list_index = function(i, n)
  assert(n > 0)
  assert((i >= 1 and i <= n) or (i <= -1 and i >= -n))
  return i > 0 and i or (n + i + 1)
end

-- json like field indexing via dot `.` delimiter and get value.
-- for example `t = { a = { b = 1 } }` and `field = 'a.b'` will return `1`.
--
--- @param t table?
--- @param field string
M.tbl_get = function(t, field)
  local cur = t --[[@as table]]
  local field_splits = vim.split(field, ".", { plain = true, trimempty = true })
  for _, f in ipairs(field_splits) do
    if M.tbl_not_empty(cur) and cur[f] ~= nil then
      cur = cur[f]
    else
      return nil
    end
  end
  return cur
end

return M
