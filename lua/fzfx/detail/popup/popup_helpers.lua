local num = require("fzfx.commons.num")
local tbl = require("fzfx.commons.tbl")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")

local M = {}

-- WindowOptsContext {

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

-- WindowOptsContext }

-- ShellOptsContext {

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

-- ShellOptsContext }

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

--- @param relative_winnr integer
--- @param relative_win_first_line integer the first line number of window (e.g. the view), from `vim.fn.line("w0")`
--- @param win_opts {relative:"editor"|"win"|"cursor",height:number,width:number,row:number,col:number}
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts?
--- @return {height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer,provider:{height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}?,previewer:{height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}?}
M.make_center_layout = function(
  relative_winnr,
  ---@diagnostic disable-next-line: unused-local
  relative_win_first_line,
  win_opts,
  fzf_preview_window_opts
)
  log.ensure(
    type(relative_winnr) == "number" and vim.api.nvim_win_is_valid(relative_winnr),
    string.format(
      "|make_center_layout| relative_winnr (%s) must be a valid window number",
      vim.inspect(relative_winnr)
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

  local center_row
  local center_col
  if win_opts.row >= -0.5 and win_opts.row <= 0.5 then
    center_row = win_opts.row + 0.5
    center_row = total_height * center_row
  else
    center_row = total_height * 0.5 + win_opts.row
  end
  if win_opts.col >= -0.5 and win_opts.col <= 0.5 then
    center_col = win_opts.col + 0.5
    center_col = total_width * center_col
  else
    center_col = total_width * 0.5 + win_opts.col
  end
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

  local start_row = math.floor(center_row - (height / 2)) - 1
  local end_row = math.floor(center_row + (height / 2)) - 1
  local start_col = math.floor(center_col - (width / 2)) - 1
  local end_col = math.floor(center_col + (width / 2)) - 1

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

  -- log.debug(string.format("|make_center_layout| base_layout:%s", vim.inspect(result)))
  local internal_layout = M._make_internal_layout(result, fzf_preview_window_opts)
  result.provider = tbl.tbl_get(internal_layout, "provider")
  result.previewer = tbl.tbl_get(internal_layout, "previewer")

  return result
end

--- @param relative_winnr integer
--- @param relative_win_first_line integer the first line number of window (e.g. the view), from `vim.fn.line("w0")`
--- @param win_opts {relative:"editor"|"win"|"cursor",height:number,width:number,row:number,col:number}
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts?
--- @return {height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer,provider:{height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}?,previewer:{height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}?}
M.make_cursor_layout = function(
  relative_winnr,
  relative_win_first_line,
  win_opts,
  fzf_preview_window_opts
)
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
  local win_first_line = relative_win_first_line
  local cursor_relative_row = cursor_pos[1] - win_first_line
  local cursor_relative_col = cursor_pos[2]
  log.debug(
    string.format(
      "|make_cursor_layout| total height/width:%s/%s, cursor:%s, win first line:%s, cursor relative row/col:%s/%s",
      vim.inspect(total_height),
      vim.inspect(total_width),
      vim.inspect(cursor_pos),
      vim.inspect(win_first_line),
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
  local start_col

  if win_opts.row > -1 and win_opts.row < 1 then
    start_row = math.floor(total_height * win_opts.row) + cursor_relative_row
  else
    start_row = win_opts.row + cursor_relative_row
  end
  local end_row = start_row + height

  if win_opts.col > -1 and win_opts.col < 1 then
    start_col = math.floor(total_width * win_opts.col) + cursor_relative_col
  else
    start_col = win_opts.col + cursor_relative_col
  end
  local end_col = start_col + width

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

  log.debug(string.format("|make_cursor_layout| base_layout:%s", vim.inspect(result)))
  local internal_layout = M._make_internal_layout(result, fzf_preview_window_opts)
  result.provider = tbl.tbl_get(internal_layout, "provider")
  result.previewer = tbl.tbl_get(internal_layout, "previewer")

  return result
end

--- @param base_layout {total_height:integer,total_width:integer,height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts?
--- @return {provider:{height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}?,previewer:{height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}?}?
M._make_internal_layout = function(base_layout, fzf_preview_window_opts)
  --- @param v number
  --- @return number
  local function bound_row(v)
    return num.bound(v, 0, base_layout.total_height - 1)
  end

  --- @param v number
  --- @return number
  local function bound_col(v)
    return num.bound(v, 0, base_layout.total_width - 1)
  end

  --- @param v number
  --- @return number
  local function bound_height(v)
    return num.bound(v, 1, base_layout.height)
  end

  --- @param v number
  --- @return number
  local function bound_width(v)
    return num.bound(v, 1, base_layout.width)
  end

  if type(fzf_preview_window_opts) == "table" then
    local provider_layout = {}
    local previewer_layout = {}
    if
      fzf_preview_window_opts.position == "left"
      or fzf_preview_window_opts.position == "right"
    then
      if fzf_preview_window_opts.size_is_percent then
        previewer_layout.width =
          bound_width(math.floor((base_layout.width / 100 * fzf_preview_window_opts.size) - 1))
      else
        previewer_layout.width = bound_width(fzf_preview_window_opts.size - 1)
      end
      provider_layout.width = bound_width(base_layout.width - previewer_layout.width - 2)
      provider_layout.height = base_layout.height
      previewer_layout.height = base_layout.height

      -- the layout looks like
      --
      -- |      |       |
      -- | left | right |
      -- |      |       |

      if fzf_preview_window_opts.position == "left" then
        -- |           |          |
        -- | previewer | provider |
        -- |           |          |
        previewer_layout.start_col = base_layout.start_col
        previewer_layout.end_col = bound_col(base_layout.start_col + previewer_layout.width)
        provider_layout.start_col = bound_col(base_layout.end_col - provider_layout.width)
        provider_layout.end_col = base_layout.end_col
      else
        -- |          |           |
        -- | provider | previewer |
        -- |          |           |
        provider_layout.start_col = base_layout.start_col
        provider_layout.end_col = bound_col(base_layout.start_col + provider_layout.width)
        previewer_layout.start_col = bound_col(base_layout.end_col - previewer_layout.width)
        previewer_layout.end_col = base_layout.end_col
      end
      provider_layout.start_row = base_layout.start_row
      provider_layout.end_row = base_layout.end_row
      previewer_layout.start_row = base_layout.start_row
      previewer_layout.end_row = base_layout.end_row
    elseif
      fzf_preview_window_opts
      and (fzf_preview_window_opts.position == "up" or fzf_preview_window_opts.position == "down")
    then
      if fzf_preview_window_opts.size_is_percent then
        previewer_layout.height =
          bound_height(math.floor(base_layout.height / 100 * fzf_preview_window_opts.size) - 1)
      else
        previewer_layout.height = bound_height(fzf_preview_window_opts.size - 1)
      end
      provider_layout.height = bound_height(base_layout.height - previewer_layout.height - 2)
      provider_layout.width = base_layout.width
      previewer_layout.width = base_layout.width

      -- the layout looks like
      --
      -- ---------
      --    up
      -- ---------
      --   down
      -- ---------

      if fzf_preview_window_opts.position == "up" then
        -- -------------
        --   previewer
        -- -------------
        --   provider
        -- -------------
        previewer_layout.start_row = base_layout.start_row
        previewer_layout.end_row = bound_row(base_layout.start_row + previewer_layout.height)
        provider_layout.start_row = bound_row(base_layout.end_row - provider_layout.height)
        provider_layout.end_row = base_layout.end_row
      else
        -- -------------
        --   provider
        -- -------------
        --   previewer
        -- -------------
        provider_layout.start_row = base_layout.start_row
        provider_layout.end_row = bound_row(base_layout.start_row + provider_layout.height)
        previewer_layout.start_row = bound_row(base_layout.end_row - previewer_layout.height)
        previewer_layout.end_row = base_layout.end_row
      end
      provider_layout.start_col = base_layout.start_col
      provider_layout.end_col = base_layout.end_col
      previewer_layout.start_col = base_layout.start_col
      previewer_layout.end_col = base_layout.end_col
    end
    -- log.debug("|get_layout| result-2:%s", vim.inspect(result))
    return { provider = provider_layout, previewer = previewer_layout }
  end

  return nil
end

-- layout }

-- constants {

M.FLOAT_WIN_STYLE = "minimal"
M.FLOAT_WIN_ZINDEX = 60

-- constants }

return M
