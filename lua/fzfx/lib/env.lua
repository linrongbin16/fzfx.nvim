local M = {}

--- @return boolean
M.debug_enabled = function()
  return tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"
end

--- @return boolean
M.icon_enabled = function()
  return type(vim.env._FZFX_NVIM_DEVICONS_PATH) == "string"
    and string.len(vim.env._FZFX_NVIM_DEVICONS_PATH) > 0
end

return M
