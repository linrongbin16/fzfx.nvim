local constants = require("fzfx.lib.constants")

local M = {}

-- buffers {

--- @param bufnr integer
--- @param name string
--- @return any
M.get_buf_option = function(bufnr, name)
  if vim.fn.has("nvim-0.8") > 0 then
    return vim.api.nvim_get_option_value(name, { buf = bufnr })
  else
    return vim.api.nvim_buf_get_option(bufnr, name)
  end
end

--- @param bufnr integer
--- @param name string
--- @param value any
--- @return any
M.set_buf_option = function(bufnr, name, value)
  if vim.fn.has("nvim-0.8") > 0 then
    return vim.api.nvim_set_option_value(name, value, { buf = bufnr })
  else
    return vim.api.nvim_buf_set_option(bufnr, name, value)
  end
end

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

-- buffers }

-- windows {

--- @param winnr integer
--- @param name string
--- @return any
M.get_win_option = function(winnr, name)
  if vim.fn.has("nvim-0.8") > 0 then
    return vim.api.nvim_get_option_value(name, { win = winnr })
  else
    return vim.api.nvim_win_get_option(winnr, name)
  end
end

--- @param winnr integer
--- @param name string
--- @param value any
--- @return any
M.set_win_option = function(winnr, name, value)
  if vim.fn.has("nvim-0.8") > 0 then
    return vim.api.nvim_set_option_value(name, value, { win = winnr })
  else
    return vim.api.nvim_win_set_option(winnr, name, value)
  end
end

--- @class fzfx.WindowOptsContext
--- @field bufnr integer
--- @field tabnr integer
--- @field winnr integer
local WindowOptsContext = {}

--- @return fzfx.WindowOptsContext
function WindowOptsContext:save()
  local o = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function WindowOptsContext:restore()
  if vim.api.nvim_tabpage_is_valid(self.tabnr) then
    vim.api.nvim_set_current_tabpage(self.tabnr)
  end
  if vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_set_current_win(self.winnr)
  end
end

M.WindowOptsContext = WindowOptsContext

-- windows }

-- shell {

--- @class fzfx.ShellOptsContext
--- @field shell string?
--- @field shellslash string?
--- @field shellcmdflag string?
--- @field shellxquote string?
--- @field shellquote string?
--- @field shellredir string?
--- @field shellpipe string?
--- @field shellxescape string?
local ShellOptsContext = {}

--- @return fzfx.ShellOptsContext
function ShellOptsContext:save()
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

function ShellOptsContext:restore()
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

M.ShellOptsContext = ShellOptsContext

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

-- shell }

return M
