local M = {}

--- @param bufnr integer?
--- @return boolean
M.buf_is_valid = function(bufnr)
  if type(bufnr) ~= "number" then
    return false
  end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.fn.buflisted(bufnr) > 0
    and type(bufname) == "string"
    and string.len(bufname) > 0
end

return M
