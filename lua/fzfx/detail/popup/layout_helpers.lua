local num = require("fzfx.commons.num")
local tbl = require("fzfx.commons.tbl")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")

local M = {}

--- @param total_size integer
--- @param value {start_value:integer,end_value:integer}
--- @return {start_value:integer,end_value:integer}
local function _adjust_boundary(total_size, value)
  local start_value = value.start_value
  local end_value = value.end_value

  if start_value < 0 then
    -- Too up
    local diff = math.floor(math.abs(start_value))
    start_value = 0
    end_value = end_value + diff
  elseif end_value > total_size - 1 then
    -- too down
    local diff = math.floor(math.abs(end_value - total_size + 1))
    end_value = total_size - 1
    start_value = start_value - diff
  end

  start_value = num.bound(start_value, 0, total_size - 1)
  end_value = num.bound(end_value, 0, total_size - 1)

  return { start_value = start_value, end_value = end_value }
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

--- @param relative "editor"|"win"|"cursor"
--- @param relative_winnr integer
--- @return integer
local function _get_total_width(relative, relative_winnr)
  if relative == "editor" then
    return vim.o.columns
  else
    return vim.api.nvim_win_get_width(relative_winnr)
  end
end

--- @param relative "editor"|"win"|"cursor"
--- @param relative_winnr integer
--- @return integer
local function _get_total_height(relative, relative_winnr)
  if relative == "editor" then
    return vim.o.lines
  else
    return vim.api.nvim_win_get_height(relative_winnr)
  end
end

--- @param width_opt number
--- @param total_width integer
--- @return integer
local function _get_width(width_opt, total_width)
  local value
  if width_opt > 1 then
    -- Absolute value
    value = width_opt
  else
    -- Relative value, i.e. percentage
    value = math.floor(width_opt * total_width)
  end
  return num.bound(value, 1, total_width)
end

--- @param height_opt number
--- @param total_height integer
--- @return integer
local function _get_height(height_opt, total_height)
  local value
  if height_opt > 1 then
    -- Absolute value
    value = height_opt
  else
    -- Relative value, i.e. percentage
    value = math.floor(height_opt * total_height)
  end
  return num.bound(value, 1, total_height)
end

--- @param opt number
--- @param total_size integer
--- @param opt_name string
--- @return integer
local function _get_center(opt, total_size, opt_name)
  log.ensure(
    (opt >= -0.5 and opt <= 0.5) or opt <= -1 or opt >= 1,
    string.format(
      "Popup window %s (%s) opts must in range [-0.5, 0.5] or (-inf, -1] or [1, +inf]",
      opt_name,
      vim.inspect(opt)
    )
  )

  local center
  if opt >= -0.5 and opt <= 0.5 then
    -- Relative value, i.e. percentage
    center = opt + 0.5
    center = total_size * center
  else
    -- Absolute value
    center = total_size * 0.5 + opt
  end

  return center
end

--- @param row_opt number
--- @param height integer
--- @param total_height integer
--- @return {start_row:integer,end_row:integer}
local function _get_row(row_opt, height, total_height)
  local center_row = _get_center(row_opt, total_height, "row")

  -- Note: row/col in `nvim_open_win` API is 0-indexed, so here minus 1.
  local start_row = math.floor(center_row - (height / 2)) - 1
  local end_row = math.floor(center_row + (height / 2)) - 1
  local adjusted = _adjust_boundary(total_height, { start_value = start_row, end_value = end_row })

  return { start_row = adjusted.start_value, end_row = adjusted.end_value }
end

--- @param col_opt number
--- @param width integer
--- @param total_width integer
--- @return {start_col:integer,end_col:integer}
local function _get_col(col_opt, width, total_width)
  local center_col = _get_center(col_opt, total_width, "col")

  -- Note: row/col in `nvim_open_win` API is 0-indexed, so here minus 1.
  local start_col = math.floor(center_col - (width / 2)) - 1
  local end_col = math.floor(center_col + (width / 2)) - 1
  local adjusted = _adjust_boundary(total_width, { start_value = start_col, end_value = end_col })

  return { start_col = adjusted.start_value, end_col = adjusted.end_value }
end

--- @param row_opt number
--- @param height integer
--- @param total_height integer
--- @param cursor_relative_row integer
--- @return {start_row:integer,end_row:integer}
local function _get_cursor_row(row_opt, height, total_height, cursor_relative_row)
  local start_row
  if row_opt > -1 and row_opt < 1 then
    start_row = math.floor(total_height * row_opt) + cursor_relative_row
  else
    start_row = row_opt + cursor_relative_row
  end

  local expected_end_row = start_row + height
  local reversed_expected_start_row = start_row - 1 - height
  -- If the popup window is outside of window bottom, it will overwrite/cover the cursor
  -- thus we would place it in upper-side of cursor
  if expected_end_row > total_height and reversed_expected_start_row >= 1 then
    -- Reverse the anchor, i.e. move the popup window upside of the cursor.
    start_row = reversed_expected_start_row
  else
    -- Keep the anchor, i.e. popup window is still downside of the cursor.
  end

  local end_row = start_row + height
  local adjusted = _adjust_boundary(total_height, { start_value = start_row, end_value = end_row })

  return { start_row = adjusted.start_value, end_row = adjusted.end_value }
end

--- @param col_opt number
--- @param width integer
--- @param total_width integer
--- @param cursor_relative_col integer
--- @return {start_col:integer,end_col:integer}
local function _get_cursor_col(col_opt, width, total_width, cursor_relative_col)
  local center_col = _get_center(col_opt, total_width, "col")

  -- Note: row/col in `nvim_open_win` API is 0-indexed, so here minus 1.
  local start_col = math.floor(center_col - (width / 2)) - 1
  local end_col = math.floor(center_col + (width / 2)) - 1

  -- Difference between center-based and cursor-based.
  local diff = cursor_relative_col - start_col
  start_col = cursor_relative_col
  end_col = end_col + diff

  local adjusted = _adjust_boundary(total_width, { start_value = start_col, end_value = end_col })

  return { start_col = adjusted.start_value, end_col = adjusted.end_value }
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

  -- Total width/height
  local total_width = _get_total_width(win_opts.relative, relative_winnr)
  local total_height = _get_total_height(win_opts.relative, relative_winnr)

  -- Width/height
  local width = _get_width(win_opts.width, total_width)
  local height = _get_height(win_opts.height, total_height)

  -- Row/column
  local row = _get_row(win_opts.row, height, total_height)
  local col = _get_col(win_opts.col, width, total_width)

  local result = {
    total_height = total_height,
    total_width = total_width,
    height = height,
    width = width,
    start_row = row.start_row,
    end_row = row.end_row,
    start_col = col.start_col,
    end_col = col.end_col,
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
  log.ensure(
    win_opts.relative == "cursor",
    string.format(
      "|make_cursor_layout| relative (%s) must be cursor",
      vim.inspect(win_opts.relative)
    )
  )

  -- Total width/height.
  local total_width = _get_total_width(win_opts.relative, relative_winnr)
  local total_height = _get_total_height(win_opts.relative, relative_winnr)

  -- Cursor.
  local cursor_pos = vim.api.nvim_win_get_cursor(relative_winnr)
  local cursor_relative_row = cursor_pos[1] - relative_win_first_line
  local cursor_relative_col = cursor_pos[2]

  -- Width/height.
  local width = _get_width(win_opts.width, total_width)
  local height = _get_height(win_opts.height, total_height)

  -- Row/col.
  local row = _get_cursor_row(win_opts.row, height, total_height, cursor_relative_row)
  local col = _get_cursor_col(win_opts.col, width, total_width, cursor_relative_col)

  local result = {
    total_height = total_height,
    total_width = total_width,
    height = height,
    width = width,
    start_row = row.start_row,
    end_row = row.end_row,
    start_col = col.start_col,
    end_col = col.end_col,
  }

  return result
end

return M
