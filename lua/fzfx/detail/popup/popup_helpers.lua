local num = require("fzfx.commons.num")
local tbl = require("fzfx.commons.tbl")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")

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

-- layout {

--- @param total_height integer
--- @param total_width integer
--- @param layout {start_row:integer,end_row:integer,start_col:integer,end_col:integer}
--- @return {start_row:integer,end_row:integer,start_col:integer,end_col:integer}
M._adjust_layout_bound = function(total_height, total_width, layout)
  --- @param v number
  --- @return number
  local function bound_row(v)
    return num.bound(v, 0, total_height - 1)
  end

  --- @param v number
  --- @return number
  local function bound_col(v)
    return num.bound(v, 0, total_width - 1)
  end

  local start_row = layout.start_row
  local end_row = layout.end_row
  local start_col = layout.start_col
  local end_col = layout.end_col

  if start_row <= 0 then
    -- too up
    local diff_row = math.floor(math.abs(start_row))
    start_row = 0
    end_row = end_row + diff_row
  elseif end_row >= total_height - 1 then
    -- too down
    local diff_row = math.floor(math.abs(end_row - total_height + 1))
    end_row = total_height - 1
    start_row = start_row - diff_row
  end

  start_row = bound_row(start_row)
  end_row = bound_row(end_row)

  if start_col <= 0 then
    -- too left
    local diff_col = math.floor(math.abs(start_col))
    start_col = 0
    end_col = end_col + diff_col
  elseif end_col >= total_width - 1 then
    -- too right
    local diff_col = math.floor(math.abs(end_col - total_width + 1))
    end_col = total_width - 1
    start_col = start_col - diff_col
  end

  start_col = bound_col(start_col)
  end_col = bound_col(end_col)

  return { start_row = start_row, end_row = end_row, start_col = start_col, end_col = end_col }
end

--- @param win_opts {relative:"editor"|"win"|"cursor",height:number,width:number,row:number,col:number}
--- @param total_height integer
--- @return integer
M._get_center_row = function(win_opts, total_height)
  local center_row
  if win_opts.row >= -0.5 and win_opts.row <= 0.5 then
    center_row = win_opts.row + 0.5
    center_row = total_height * center_row
  else
    center_row = total_height * 0.5 + win_opts.row
  end
  return center_row
end

--- @param win_opts {relative:"editor"|"win"|"cursor",height:number,width:number,row:number,col:number}
--- @param total_width integer
--- @return integer
M._get_center_col = function(win_opts, total_width)
  local center_col
  if win_opts.col >= -0.5 and win_opts.col <= 0.5 then
    center_col = win_opts.col + 0.5
    center_col = total_width * center_col
  else
    center_col = total_width * 0.5 + win_opts.col
  end
  return center_col
end

--- @param relative_winnr integer
--- @param relative_win_first_line integer the first line number of window (e.g. the view), from `vim.fn.line("w0")`
--- @param win_opts {relative:"editor"|"win"|"cursor",height:number,width:number,row:number,col:number}
--- @return {height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}
M.make_center_layout = function(relative_winnr, relative_win_first_line, win_opts)
  log.ensure(
    type(relative_winnr) == "number" and vim.api.nvim_win_is_valid(relative_winnr),
    string.format(
      "|make_center_layout| relative_winnr (%s) must be a valid window number",
      vim.inspect(relative_winnr)
    )
  )
  log.ensure(
    type(relative_win_first_line) == "number" and relative_win_first_line >= 0,
    string.format(
      "|make_center_layout| relative_win_first_line (%s) must be a positive number",
      vim.inspect(relative_win_first_line)
    )
  )

  local total_width = win_opts.relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(relative_winnr)
  local total_height = win_opts.relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(relative_winnr)

  local width = num.bound(
    win_opts.width > 1 and win_opts.width or math.floor(win_opts.width * total_width),
    1,
    total_width
  )
  local height = num.bound(
    win_opts.height > 1 and win_opts.height or math.floor(win_opts.height * total_height),
    1,
    total_height
  )

  log.ensure(
    (win_opts.row >= -0.5 and win_opts.row <= 0.5) or win_opts.row <= -1 or win_opts.row >= 1,
    string.format(
      "popup window row (%s) opts must in range [-0.5, 0.5] or (-inf, -1] or [1, +inf]",
      vim.inspect(win_opts.row)
    )
  )
  log.ensure(
    (win_opts.col >= -0.5 and win_opts.col <= 0.5) or win_opts.col <= -1 or win_opts.col >= 1,
    string.format(
      "popup window col (%s) opts must in range [-0.5, 0.5] or (-inf, -1] or [1, +inf]",
      vim.inspect(win_opts.col)
    )
  )

  local center_row = M._get_center_row(win_opts, total_height)
  local center_col = M._get_center_col(win_opts, total_width)
  -- log.debug(
  --   "|get_layout| win_opts:%s, center(row/col):%s/%s, height/width:%s/%s, total(height/width):%s/%s, row(start/end):%s/%s, col(start/end):%s/%s",
  --   vim.inspect(win_opts),
  --   vim.inspect(center_row),
  --   vim.inspect(center_col),
  --   vim.inspect(height),
  --   vim.inspect(width),
  --   vim.inspect(total_height),
  --   vim.inspect(total_width),
  --   vim.inspect(center_row - (height / 2)),
  --   vim.inspect(center_row + (height / 2)),
  --   vim.inspect(center_col - (width / 2)),
  --   vim.inspect(center_col + (width / 2))
  -- )

  local start_row = (center_row - math.ceil(height / 2)) - 1
  local end_row = (center_row + math.ceil(height / 2)) - 1
  local start_col = (center_col - math.ceil(width / 2)) - 1
  local end_col = (center_col + math.ceil(width / 2)) - 1

  local adjust_layout = M._adjust_layout_bound(
    total_height,
    total_width,
    { start_row = start_row, end_row = end_row, start_col = start_col, end_col = end_col }
  )

  start_row = adjust_layout.start_row
  end_row = adjust_layout.end_row
  start_col = adjust_layout.start_col
  end_col = adjust_layout.end_col

  local result = {
    total_height = total_height,
    total_width = total_width,
    height = height,
    width = width,
    start_row = start_row,
    end_row = end_row,
    start_col = start_col,
    end_col = end_col,
  }

  return result
end

--- @param relative_winnr integer
--- @param relative_win_first_line integer the first line number of window (e.g. the view), from `vim.fn.line("w0")`
--- @param win_opts {relative:"editor"|"win"|"cursor",height:number,width:number,row:number,col:number}
--- @return {height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}
M.make_cursor_layout = function(relative_winnr, relative_win_first_line, win_opts)
  log.ensure(
    type(relative_winnr) == "number" and vim.api.nvim_win_is_valid(relative_winnr),
    string.format(
      "|make_cursor_layout| relative_winnr (%s) must be a valid window number",
      vim.inspect(relative_winnr)
    )
  )
  log.ensure(
    type(relative_win_first_line) == "number" and relative_win_first_line >= 0,
    string.format(
      "|make_cursor_layout| relative_win_first_line (%s) must be a positive number",
      vim.inspect(relative_win_first_line)
    )
  )

  local total_width = vim.api.nvim_win_get_width(relative_winnr)
  local total_height = vim.api.nvim_win_get_height(relative_winnr)
  local cursor_pos = vim.api.nvim_win_get_cursor(relative_winnr)
  local cursor_relative_row = cursor_pos[1] - relative_win_first_line
  local cursor_relative_col = cursor_pos[2]
  log.debug(
    string.format(
      "|make_cursor_layout| total height/width:%s/%s, cursor:%s, relative_win_first_line:%s, cursor relative row/col:%s/%s",
      vim.inspect(total_height),
      vim.inspect(total_width),
      vim.inspect(cursor_pos),
      vim.inspect(relative_win_first_line),
      vim.inspect(cursor_relative_row),
      vim.inspect(cursor_relative_col)
    )
  )

  local width = num.bound(
    win_opts.width > 1 and win_opts.width or math.floor(win_opts.width * total_width),
    1,
    total_width
  )
  local height = num.bound(
    win_opts.height > 1 and win_opts.height or math.floor(win_opts.height * total_height),
    1,
    total_height
  )

  local start_row
  local end_row
  if win_opts.row > -1 and win_opts.row < 1 then
    start_row = math.floor(total_height * win_opts.row) + cursor_relative_row
  else
    start_row = win_opts.row + cursor_relative_row
  end

  local expected_end_row = start_row + height
  local reversed_expected_start_row = start_row - 1 - height
  -- if cursor based popup window is too beyond bottom, it will cover the cursor
  -- thus we would place it in upper-side of cursor
  log.debug(
    string.format(
      "|make_cursor_layout| height/width:%s/%s, start_row:%s, start_row + height(%s) > total_height(%s):%s, start_row - 3 - height(%s) >= 1:%s",
      vim.inspect(height),
      vim.inspect(width),
      vim.inspect(start_row),
      vim.inspect(expected_end_row),
      vim.inspect(total_height),
      vim.inspect(expected_end_row > total_height),
      vim.inspect(reversed_expected_start_row),
      vim.inspect(reversed_expected_start_row >= 1)
    )
  )
  if expected_end_row > total_height and reversed_expected_start_row >= 1 then
    -- Reverse the anchor, i.e. move the popup window upside of the cursor.
    start_row = reversed_expected_start_row
    end_row = start_row + height
  else
    -- Keep the anchor, i.e. popup window is still downside of the cursor.
    end_row = start_row + height
  end

  local center_col = M._get_center_col(win_opts, total_width)
  local start_col = (center_col - math.ceil(width / 2)) - 1
  local end_col = (center_col + math.ceil(width / 2)) - 1

  local adjust_layout = M._adjust_layout_bound(
    total_height,
    total_width,
    { start_row = start_row, end_row = end_row, start_col = start_col, end_col = end_col }
  )

  start_row = adjust_layout.start_row
  end_row = adjust_layout.end_row
  start_col = adjust_layout.start_col
  end_col = adjust_layout.end_col

  local result = {
    total_height = total_height,
    total_width = total_width,
    height = height,
    width = width,
    start_row = start_row,
    end_row = end_row,
    start_col = start_col,
    end_col = end_col,
  }

  return result
end

-- layout }

-- constants {

M.FLOAT_WIN_STYLE = "minimal"
M.FLOAT_WIN_ZINDEX = 60
M.FLOAT_WIN_BORDER = "none"

-- constants }

return M
