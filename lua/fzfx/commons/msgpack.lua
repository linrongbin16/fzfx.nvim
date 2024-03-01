local M = {}

--- @param t table?
--- @return string?
M.pack = function(t)
  if t == nil then
    return nil
  end
  return require("fzfx.commons._MessagePack").pack(t)
end

--- @param m string?
--- @return table?
M.unpack = function(m)
  if m == nil then
    return nil
  end
  return require("fzfx.commons._MessagePack").unpack(m)
end

return M
