local M = {}

-- Detect whether the global `fzfx_disable_buffer_previewer` variable is been set.
-- Returns `true` only if the variable is a positive number, or a `true` boolean.
-- Otherwise returns `false`.
--- @return boolean
M.buffer_previewer_disabled = function()
  local v = vim.g.fzfx_disable_buffer_previewer
  if type(v) == "number" and v > 0 then
    return true
  end
  if type(v) == "boolean" then
    return v
  end
  return false
end

return M
