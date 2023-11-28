local M = {}

-- math
M.INT32_MAX = 2147483647
M.INT32_MIN = -2147483648

--- @param value number
--- @param left number?  by default INT32_MIN
--- @param right number?  by default INT32_MAX
--- @return number
M.bound = function(value, left, right)
  return math.min(math.max(left or M.INT32_MIN, value), right or M.INT32_MAX)
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
    string.format("%x", math.random(1, M.INT32_MAX)),
  }, delimiter)
end

local UniqueIdInteger = 0

--- @alias fzfx.UniqueId string
--- @return UniqueId
M.unique_id = function()
  if UniqueIdInteger >= M.INT32_MAX then
    UniqueIdInteger = 1
  else
    UniqueIdInteger = UniqueIdInteger + 1
  end
  return tostring(UniqueIdInteger)
end

return M
