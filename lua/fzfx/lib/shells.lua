local constants = require("fzfx.lib.constants")

local M = {}

-- Escape the Windows/DOS command line (cmd.exe) strings for Windows OS.
-- See:
-- * https://www.robvanderwoude.com/escapechars.php
-- * https://ss64.com/nt/syntax-esc.html
--- @param s string
--- @return string
M._shellescape_windows = function(s)
  local shellslash = vim.o.shellslash
  vim.o.shellslash = false
  local result = vim.fn.shellescape(s)
  vim.o.shellslash = shellslash
  return result
end

-- Escape shell strings for POSIX compatible OS.
--- @param s string
--- @return string
M._shellescape_posix = function(s)
  return vim.fn.shellescape(s)
end

--- @param s string
--- @return string
M.shellescape = function(s)
  if constants.IS_WINDOWS then
    return M._shellescape_windows(s)
  else
    return M._shellescape_posix(s)
  end
end

-- ShellContext {

--- @class fzfx.ShellContext
--- @field shell string?
--- @field shellslash string?
--- @field shellcmdflag string?
--- @field shellxquote string?
--- @field shellquote string?
--- @field shellredir string?
--- @field shellpipe string?
--- @field shellxescape string?
local ShellContext = {}

--- @return fzfx.ShellContext
function ShellContext:save()
  local o = constants.IS_WINDOWS
      and {
        shell = vim.o.shell,
        shellslash = vim.o.shellslash,
        shellcmdflag = vim.o.shellcmdflag,
        shellxquote = vim.o.shellxquote,
        shellquote = vim.o.shellquote,
        shellredir = vim.o.shellredir,
        shellpipe = vim.o.shellpipe,
        shellxescape = vim.o.shellxescape,
      }
    or {
      shell = vim.o.shell,
    }
  setmetatable(o, self)
  self.__index = self

  if constants.IS_WINDOWS then
    vim.o.shell = "cmd.exe"
    vim.o.shellslash = false
    vim.o.shellcmdflag = "/s /c"
    vim.o.shellxquote = '"'
    vim.o.shellquote = ""
    vim.o.shellredir = ">%s 2>&1"
    vim.o.shellpipe = "2>&1| tee"
    vim.o.shellxescape = ""
  else
    vim.o.shell = "sh"
  end

  return o
end

function ShellContext:restore()
  if constants.IS_WINDOWS then
    vim.o.shell = self.shell
    vim.o.shellslash = self.shellslash
    vim.o.shellcmdflag = self.shellcmdflag
    vim.o.shellxquote = self.shellxquote
    vim.o.shellquote = self.shellquote
    vim.o.shellredir = self.shellredir
    vim.o.shellpipe = self.shellpipe
    vim.o.shellxescape = self.shellxescape
  else
    vim.o.shell = self.shell
  end
end

M.ShellContext = ShellContext

-- ShellContext }

return M
