local constants = require("fzfx.lib.constants")

local M = {}

-- `shellescape` implementation for `sh`.
--- @param s string
--- @return string
M._sh_shellescape = function(s)
  -- Force use 'sh' when escaping
  local saved_shell = vim.o.shell
  vim.o.shell = "sh"
  local result = vim.fn.shellescape(s)
  vim.o.shell = saved_shell
  return result
end

-- References:
-- https://learn.microsoft.com/en-us/archive/blogs/twistylittlepassagesallalike/everyone-quotes-command-line-arguments-the-wrong-way
-- https://stackoverflow.com/questions/6714165/powershell-stripping-double-quotes-from-command-line-arguments
--
-- `shellescape` implementation for Windows `cmd.exe`.
--- @param s string
--- @return string
M._cmd_shellescape = function(s) end

-- Compatible version of `vim.fn.shellescape` that works for both Windows and *NIX.
--- @param s string
--- @param special any?
--- @return string
M.shellescape = function(s, special)
  if constants.IS_WINDOWS then
    local shellslash = vim.o.shellslash
    vim.o.shellslash = false
    local result = special ~= nil and vim.fn.shellescape(s, special) or vim.fn.shellescape(s)
    vim.o.shellslash = shellslash
    return result
  else
    return special ~= nil and vim.fn.shellescape(s, special) or vim.fn.shellescape(s)
  end
end

-- Reference:
-- https://learn.microsoft.com/en-us/archive/blogs/twistylittlepassagesallalike/everyone-quotes-command-line-arguments-the-wrong-way
-- https://ss64.com/nt/syntax-esc.html
--
-- Make a shell command string from arguments list, that works for both Windows and *NIX.
--
--- @param args string[]
--- @return string
M.shellcommand = function(args) end

return M
