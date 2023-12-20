local M = {}

-- math
M.INT32_MAX = require("fzfx.commons.numbers").INT32_MAX
M.INT32_MIN = require("fzfx.commons.numbers").INT32_MIN

M.eq = require("fzfx.commons.numbers").eq
M.ne = require("fzfx.commons.numbers").ne
M.le = require("fzfx.commons.numbers").le
M.lt = require("fzfx.commons.numbers").lt
M.ge = require("fzfx.commons.numbers").ge
M.gt = require("fzfx.commons.numbers").gt

--- @param n integer?
--- @return boolean
M.positive = function(n)
  return type(n) == "number" and n > 0
end

--- @param n integer?
--- @return boolean
M.negative = function(n)
  return type(n) == "number" and n < 0
end

--- @param n integer?
--- @return boolean
M.non_negative = function(n)
  return type(n) == "number" and n >= 0
end

--- @param n integer?
--- @return boolean
M.non_positive = function(n)
  return type(n) == "number" and n <= 0
end

--- @param value number
--- @param left number?  by default INT32_MIN
--- @param right number?  by default INT32_MAX
--- @return number
M.bound = function(value, left, right)
  return math.min(math.max(left or M.INT32_MIN, value), right or M.INT32_MAX)
end

local IncrementId = 0

--- @return integer
M.inc_id = function()
  if IncrementId >= M.INT32_MAX then
    IncrementId = 1
  else
    IncrementId = IncrementId + 1
  end
  return IncrementId
end

return M
