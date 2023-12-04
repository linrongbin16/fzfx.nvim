local strs = require("fzfx.lib.strings")

local M = {}

--- @param query string
--- @param flag string?
--- @return {payload:string,option:string?}
M.parse_flagged = function(query, flag)
  flag = flag or "--"
  local payload = ""
  local option = nil

  local flag_pos = strs.find(query, flag)
  if type(flag_pos) == "number" and flag_pos > 0 then
    payload = vim.trim(string.sub(query, 1, flag_pos - 1))
    option = vim.trim(string.sub(query, flag_pos + 2))
  else
    payload = vim.trim(query)
  end
  return { payload = payload, option = option }
end

return M
