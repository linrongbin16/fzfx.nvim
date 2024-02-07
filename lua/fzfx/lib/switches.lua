local M = {}

--- @return boolean
M.buffer_previewer_disabled = function()
  return (
    type(vim.g.fzfx_disable_buffer_previewer) == "number"
    and vim.g.fzfx_disable_buffer_previewer > 0
  )
    or (
      type(vim.g.fzfx_disable_buffer_previewer) == "boolean" and vim.g.fzfx_disable_buffer_previewer
    )
end

return M
