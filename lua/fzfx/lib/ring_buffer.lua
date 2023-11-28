local M = {}

--- @class fzfx.RingBuffer
--- @field pos integer
--- @field queue any[]
--- @field maxsize integer
local RingBuffer = {}

--- @param maxsize integer
--- @return fzfx.RingBuffer
function RingBuffer:new(maxsize)
  local o = {
    pos = 0,
    queue = {},
    maxsize = maxsize,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param item any
--- @return integer
function RingBuffer:push(item)
  if #self.queue < self.maxsize then
    self.pos = self.pos + 1
    table.insert(self.queue, item)
  else
    if self.pos == #self.queue then
      self.pos = 1
    else
      self.pos = self.pos + 1
    end
    self.queue[self.pos] = item
  end
  return self.pos
end

-- get the item on pos, or the last pushed item
--- @param pos integer?
--- @return any?
function RingBuffer:get(pos)
  pos = pos or self.pos
  if #self.queue == 0 or pos == 0 then
    return nil
  else
    return self.queue[pos]
  end
end

-- iterate from oldest to newest, usage:
--
-- ```lua
--  local p = ring_buffer:begin()
--  while p ~= nil then
--    local item = ring_buffer:get(p)
--    p = ring_buffer:next(p)
--  end
-- ```
--
--- @return integer?
function RingBuffer:begin()
  if #self.queue == 0 or self.pos == 0 then
    return nil
  end
  if self.pos == #self.queue then
    return 1
  else
    return self.pos + 1
  end
end

-- iterate from oldest to newest
--- @param pos integer
--- @return integer?
function RingBuffer:next(pos)
  if #self.queue == 0 or pos == 0 then
    return nil
  end
  if pos == self.pos then
    return nil
  end
  if pos == #self.queue then
    return 1
  else
    return pos + 1
  end
end

-- iterate from newest to oldest, usage:
--
-- ```lua
--  local p = ring_buffer:rbegin()
--  while p ~= nil then
--    local item = ring_buffer:get(p)
--    p = ring_buffer:rnext()
--  end
-- ```
--
--- @return integer?
function RingBuffer:rbegin()
  if #self.queue == 0 or self.pos == 0 then
    return nil
  end
  return self.pos
end

-- iterate from newest to oldest
--- @param pos integer
--- @return integer?
function RingBuffer:rnext(pos)
  if #self.queue == 0 or pos == 0 then
    return nil
  end
  if self.pos == 1 and pos == #self.queue then
    return nil
  elseif pos == self.pos then
    return nil
  end
  if pos == 1 then
    return #self.queue
  else
    return pos - 1
  end
end

M.RingBuffer = RingBuffer

return M
