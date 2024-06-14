local M = {}

--- @return {bufnr:integer, winnr:integer, tabnr: integer}
M.make_pipeline_context = function()
  return {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
end

return M
