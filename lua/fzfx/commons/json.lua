local M = {}

--- @param t table?
--- @return string?
M.encode = function(t)
  if t == nil then
    return nil
  end
  return require("fzfx.commons._json").encode(t)
end

--- @param j string?
--- @return table?
M.decode = function(j)
  if j == nil then
    return nil
  end
  return require("fzfx.commons._json").decode(j)
end

return M
