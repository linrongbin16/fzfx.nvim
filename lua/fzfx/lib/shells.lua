local M = {}

-- Escape the Windows/DOS command line (cmd.exe) strings for Windows OS.
--
-- References:
-- * https://www.robvanderwoude.com/escapechars.php
-- * https://ss64.com/nt/syntax-esc.html
-- * https://stackoverflow.com/questions/562038/escaping-double-quotes-in-batch-script
--
--- @param s string
--- @return string
M._escape_windows = function(s)
  local shellslash = vim.o.shellslash
  vim.o.shellslash = false
  local result = vim.fn.shellescape(s)
  vim.o.shellslash = shellslash
  return result
end

-- Escape shell strings for POSIX compatible OS.
--- @param s string
--- @return string
M._escape_posix = function(s)
  return vim.fn.shellescape(s)
end

--- @param s string
--- @return string
M.escape = function(s)
  if require("fzfx.commons.platform").IS_WINDOWS then
    return M._escape_windows(s)
  else
    return M._escape_posix(s)
  end
end

return M
