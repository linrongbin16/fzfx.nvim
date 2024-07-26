local M = {}

--- @return boolean
M.buffer_previewer_disabled = function()
  local value = vim.g.fzfx_disable_buffer_previewer
  if type(value) == "number" then
    return value > 0
  end
  if type(value) == "boolean" then
    return value
  end
  return false
end

--- @return boolean
M.bat_theme_autogen_enabled = function()
  local value = vim.g.fzfx_enable_bat_theme_autogen
  if type(value) == "number" then
    return value > 0
  end
  if type(value) == "boolean" then
    return value
  end
  return false
end

return M
