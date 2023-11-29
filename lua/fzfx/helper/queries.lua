local strs = require("fzfx.lib.strings")

local M = {}

--- @param content string
--- @param flag string?
--- @return {payload:string,option:string?}
M.parse_flagged = function(content, flag)
  flag = flag or "--"
  local payload = ""
  local option = nil

  local flag_pos = strs.find(content, flag)
  if type(flag_pos) == "number" and flag_pos > 0 then
    payload = vim.trim(string.sub(content, 1, flag_pos - 1))
    option = vim.trim(string.sub(content, flag_pos + 2))
  else
    payload = vim.trim(content)
  end
  return { payload = payload, option = option }
end

return M
