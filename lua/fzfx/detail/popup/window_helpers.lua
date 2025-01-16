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

-- constants {

M.FLOAT_WIN_STYLE = "minimal"
M.FLOAT_WIN_ZINDEX = 60
M.FLOAT_WIN_BORDER = "none"

-- constants }

return M
