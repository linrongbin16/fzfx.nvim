local constants = require("fzfx.lib.constants")

local M = {}

-- WindowContext {

--- @class fzfx.WindowContext
--- @field tabnr integer
--- @field winnr integer
--- @field win_first_line integer
--- @field win_last_line integer
local WindowContext = {}

--- @return fzfx.WindowContext
function WindowContext:save()
  local winnr = vim.api.nvim_get_current_win()
  local o = {
    winnr = winnr,
    win_first_line = vim.fn.line("w0", winnr),
    win_last_line = vim.fn.line("w$", winnr),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function WindowContext:restore()
  if vim.api.nvim_tabpage_is_valid(self.tabnr) then
    vim.api.nvim_set_current_tabpage(self.tabnr)
  end
  if vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_set_current_win(self.winnr)
  end
end

--- @return integer
function WindowContext:get_winnr()
  return self.winnr
end

--- @return integer
function WindowContext:get_win_first_line()
  return self.win_first_line
end

--- @return integer
function WindowContext:get_win_last_line()
  return self.win_last_line
end

--- @return integer
function WindowContext:get_tabnr()
  return self.tabnr
end

M.WindowContext = WindowContext

-- WindowContext }

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

-- constants {

M.FLOAT_WIN_STYLE = "minimal"
M.FLOAT_WIN_ZINDEX = 60
M.FLOAT_WIN_BORDER = "none"

-- constants }

return M
