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

--- @param args_list string[]
--- @param option string?
--- @param delimiter string?
--- @return string[]
M.append_options = function(args_list, option, delimiter)
  assert(type(args_list) == "table")

  delimiter = delimiter or " "

  if strs.not_empty(option) then
    local option_splits = strs.split(option --[[@as string]], delimiter)
    for _, o in ipairs(option_splits) do
      if strs.not_empty(o) then
        table.insert(args_list, o)
      end
    end
  end

  return args_list
end

return M
