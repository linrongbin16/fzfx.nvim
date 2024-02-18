local numbers = require("fzfx.commons.numbers")
local apis = require("fzfx.commons.apis")
local fileios = require("fzfx.commons.fileios")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")

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

-- calculate window size by percentage (0.0 < value < 1.0) or integer (value >= 1.0)
--- @package
--- @param value number
--- @param size integer
--- @return integer
M.get_window_size = function(value, size)
  return numbers.bound(value > 1 and value or math.floor(size * value), 1, size)
end

-- calculate window position shift by offset and (optional) additional_offset
--- @param total_size integer
--- @param size integer
--- @param shift number
--- @param additional_offset integer?
--- @return number
M.shift_window_pos = function(total_size, size, shift, additional_offset)
  additional_offset = additional_offset or 0
  local left_size = total_size - size
  local half_left_size = math.floor(left_size * 0.5)
  if shift >= 0 then
    local offset = shift < 1 and math.floor(left_size * shift) or shift
    return numbers.bound(half_left_size + offset + additional_offset, 0, left_size)
  else
    local offset = shift > -1 and math.floor(left_size * shift) or shift
    return numbers.bound(half_left_size + offset + additional_offset, 0, left_size)
  end
end

--- @param win_opts {relative:"editor"|"win"|"cursor",height:number,width:number,row:number,col:number}
--- @param fzf_preview_window_opts fzfx.FzfPreviewWindowOpts?
--- @return {height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer,provider:{height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}?,previewer:{height:integer,width:integer,start_row:integer,end_row:integer,start_col:integer,end_col:integer}?}
M.get_layout = function(win_opts, fzf_preview_window_opts)
  local total_width = win_opts.relative == "editor" and vim.o.columns
    or vim.api.nvim_win_get_width(0)
  local total_height = win_opts.relative == "editor" and vim.o.lines
    or vim.api.nvim_win_get_height(0)

  local width = numbers.bound(
    win_opts.width > 1 and win_opts.width or math.floor(win_opts.width * total_width),
    1,
    total_width
  )
  local height = numbers.bound(
    win_opts.height > 1 and win_opts.height or math.floor(win_opts.height * total_height),
    1,
    total_height
  )

  log.ensure(
    (win_opts.row >= -0.5 and win_opts.row <= 0.5) or win_opts.row <= -1 or win_opts.row >= 1,
    "buffer provider window row (%s) opts must in range [-0.5, 0.5] or (-inf, -1] or [1, +inf]",
    vim.inspect(win_opts)
  )
  log.ensure(
    (win_opts.col >= -0.5 and win_opts.col <= 0.5) or win_opts.col <= -1 or win_opts.col >= 1,
    "buffer provider window col (%s) opts must in range [-0.5, 0.5] or (-inf, -1] or [1, +inf]",
    vim.inspect(win_opts)
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

  local start_row = math.max(math.floor(center_row - (height / 2)), 0)
  local end_row = math.min(math.floor(center_row + (height / 2)), total_height - 1)
  local start_col = math.max(math.floor(center_col - (width / 2)), 0)
  local end_col = math.max(math.floor(center_col + (width / 2)), total_width - 1)

  local result = {
    height = height,
    width = width,
    start_row = start_row,
    end_row = end_row,
    start_col = start_col,
    end_col = end_col,
  }

  if type(fzf_preview_window_opts) == "table" then
    local provider_layout = {}
    local previewer_layout = {}
    if
      fzf_preview_window_opts.position == "left"
      or fzf_preview_window_opts.position == "right"
    then
      if fzf_preview_window_opts.size_is_percent then
        previewer_layout.width =
          math.floor(width - (width / 100 * fzf_preview_window_opts.size) - 1)
      else
        previewer_layout.width = math.max(width - fzf_preview_window_opts.size - 1, 1)
      end
      provider_layout.width = math.max(width - previewer_layout.width - 2, 1)
      provider_layout.height = height
      previewer_layout.height = height

      -- the layout looks like
      --
      -- |      |       |
      -- | left | right |
      -- |      |       |

      if fzf_preview_window_opts.position == "left" then
        previewer_layout.start_col = start_col
        previewer_layout.end_col = start_col + previewer_layout.width
        provider_layout.start_col = end_col - provider_layout.width
        provider_layout.end_col = end_col
      else
        -- | provider | previewer |
        provider_layout.start_col = start_col
        provider_layout.end_col = start_col + provider_layout.width
        previewer_layout.start_col = end_col - previewer_layout.width
        previewer_layout.end_col = end_col
      end
      provider_layout.start_row = start_row
      provider_layout.end_row = end_row
      previewer_layout.start_row = start_row
      previewer_layout.end_row = end_row
    elseif
      fzf_preview_window_opts
      and (fzf_preview_window_opts.position == "up" or fzf_preview_window_opts.position == "down")
    then
      if fzf_preview_window_opts.size_is_percent then
        previewer_layout.height =
          math.floor(height - (height / 100 * fzf_preview_window_opts.size) - 1)
      else
        previewer_layout.height = math.max(height - fzf_preview_window_opts.size - 1, 1)
      end
      provider_layout.height = math.max(height - previewer_layout.height - 2, 1)
      provider_layout.width = width
      previewer_layout.width = width

      -- the layout looks like
      --
      -- ----------
      --    left
      -- ----------
      --    right
      -- ----------

      if fzf_preview_window_opts.position == "up" then
        previewer_layout.start_row = start_row
        previewer_layout.end_row = start_row + previewer_layout.width
        provider_layout.start_row = end_row - provider_layout.width
        provider_layout.end_row = end_row
      else
        provider_layout.start_row = start_row
        provider_layout.end_row = start_row + provider_layout.width
        previewer_layout.start_row = end_row - previewer_layout.width
        previewer_layout.end_row = end_row
      end
      provider_layout.start = start_col
      provider_layout.end_col = end_col
      previewer_layout.start_col = start_col
      previewer_layout.end_col = end_col
    end
    result.provider = provider_layout
    result.previewer = previewer_layout
  end

  return result
end

return M
