local num = require("fzfx.commons.num")

local M = {}

--- @alias fzfx.BufferPopupWindowPreviewFileContentView {top:integer,bottom:integer,center:integer,highlight:integer?}

-- calculate bottom line from top line
--- @param top_line integer top line
--- @param content_lines integer content lines count
--- @param view_height integer window/view height
M.calculate_bottom_by_top = function(top_line, content_lines, view_height)
  return num.bound(top_line + view_height - 1, 1, content_lines)
end

-- calculate top line from bottom line
--- @param bottom_line integer bottom line
--- @param content_lines integer content lines count
--- @param view_height integer window/view height
M.calculate_top_by_bottom = function(bottom_line, content_lines, view_height)
  return num.bound(bottom_line - view_height + 1, 1, content_lines)
end

-- adjust top/bottom line based on content lines count and view height
--- @param top integer top line
--- @param bottom integer bottom line
--- @param content_lines integer content lines count
--- @param view_height integer window/view height
--- @return integer, integer top line and bottom line
M.adjust_top_and_bottom = function(top, bottom, content_lines, view_height)
  if top <= 1 then
    -- log.debug(
    --   "|_adjust_view|-1 top(%s) <= 1, bottom:%s, lines_count:%s, win_height:%s",
    --   vim.inspect(top),
    --   vim.inspect(bottom),
    --   vim.inspect(lines_count),
    --   vim.inspect(win_height)
    -- )
    bottom = M.calculate_bottom_by_top(top, content_lines, view_height)
    -- log.debug(
    --   "|_adjust_view|-2 top(%s) <= 1, bottom:%s, lines_count:%s, win_height:%s",
    --   vim.inspect(top),
    --   vim.inspect(bottom),
    --   vim.inspect(lines_count),
    --   vim.inspect(win_height)
    -- )
  elseif bottom >= content_lines then
    -- log.debug(
    --   "|_adjust_view|-3 bottom(%s) >= lines_count(%s), top:%s, win_height:%s",
    --   vim.inspect(bottom),
    --   vim.inspect(lines_count),
    --   vim.inspect(top),
    --   vim.inspect(win_height)
    -- )
    top = M.calculate_top_by_bottom(bottom, content_lines, view_height)
    -- log.debug(
    --   "|_adjust_view|-4 bottom(%s) >= lines_count(%s), top:%s, win_height:%s",
    --   vim.inspect(bottom),
    --   vim.inspect(lines_count),
    --   vim.inspect(top),
    --   vim.inspect(win_height)
    -- )
  end
  return top, bottom
end

-- make a view that start from the 1st line of the content
--- @param content_lines integer
--- @param win_height integer
--- @return fzfx.BufferPopupWindowPreviewFileContentView
M.make_top_view = function(content_lines, win_height)
  local top = 1
  local bottom = M.calculate_bottom_by_top(top, content_lines, win_height)
  top, bottom = M.adjust_top_and_bottom(top, bottom, content_lines, win_height)
  return { top = top, bottom = bottom, center = math.ceil((top + bottom) / 2), highlight = nil }
end

-- make a view that the focused line is in the middle/center, and it's also the highlighted line.
--- @param content_lines integer
--- @param win_height integer
--- @param center_line integer
--- @return fzfx.BufferPopupWindowPreviewFileContentView
M.make_center_view = function(content_lines, win_height, center_line)
  local top = num.bound(center_line - math.ceil(win_height / 2), 1, content_lines)
  local bottom = M.calculate_bottom_by_top(top, content_lines, win_height)
  top, bottom = M.adjust_top_and_bottom(top, bottom, content_lines, win_height)
  return { top = top, bottom = bottom, center = center_line, highlight = center_line }
end

-- make a view that already know the top/bottom/highlighted line, but needs to be adjusted.
--- @param content_lines integer
--- @param win_height integer
--- @param top_line integer
--- @param bottom_line integer
--- @param highlight_line integer?
M.make_range_view = function(content_lines, win_height, top_line, bottom_line, highlight_line)
  top_line, bottom_line = M.adjust_top_and_bottom(top_line, bottom_line, content_lines, win_height)
  local center_line = math.ceil((top_line + bottom_line) / 2)
  return { top = top_line, bottom = bottom_line, center = center_line, highlight = highlight_line }
end

return M
