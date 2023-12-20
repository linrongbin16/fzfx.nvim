local constants = require("fzfx.lib.constants")

local M = {}

--- @param s string
--- @param special any?
--- @return string
M.shellescape = function(s, special)
  if constants.IS_WINDOWS then
    local shellslash = vim.o.shellslash
    vim.o.shellslash = false
    local result = special ~= nil and vim.fn.shellescape(s, special)
      or vim.fn.shellescape(s)
    vim.o.shellslash = shellslash
    return result
  else
    return special ~= nil and vim.fn.shellescape(s, special)
      or vim.fn.shellescape(s)
  end
end

return M
