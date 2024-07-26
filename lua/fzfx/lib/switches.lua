local M = {}

--- @param value any
--- @return boolean
M._convert_boolean = function(value)
  if type(value) == "number" then
    return value > 0
  end
  if type(value) == "boolean" then
    return value
  end
  return false
end

--- @return boolean
M.buffer_previewer_disabled = function()
  return M._convert_boolean(vim.g.fzfx_disable_buffer_previewer)
end

--- @return boolean
M.bat_theme_autogen_enabled = function()
  return M._convert_boolean(vim.g.fzfx_enable_bat_theme_autogen)
end

return M
