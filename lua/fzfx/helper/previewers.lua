local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")
local tbl = require("fzfx.commons.tbl")
local num = require("fzfx.commons.num")

local consts = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local bat_themes_helper = require("fzfx.helper.bat_themes")

local M = {}

-- bat utils {

--- @return string
M._bat_style = function()
  local style = "numbers,changes"
  if str.not_empty(vim.env["BAT_STYLE"]) then
    style = vim.env["BAT_STYLE"]
  end
  return "--style=" .. style
end

--- @return string
M._bat_theme = function()
  local theme = "base16"
  if str.not_empty(vim.env["BAT_THEME"]) then
    theme = vim.env["BAT_THEME"]
    return "--theme=" .. theme
  end

  if consts.HAS_BAT and vim.opt.termguicolors then
    local colorname = vim.g.colors_name --[[@as string]]
    if str.not_empty(colorname) then
      local theme_config_file = bat_themes_helper.get_theme_config_filename(colorname) --[[@as string]]
      if str.not_empty(theme_config_file) and path.isfile(theme_config_file) then
        local theme_name = bat_themes_helper.get_theme_name(colorname) --[[@as string]]
        if str.not_empty(theme_name) then
          return "--theme=" .. theme_name
        end
      end
    end
  end

  return "--theme=" .. theme
end

-- bat utils }

-- preview fd/find results with cat/bat {

-- Generate the cat/bat shell command in strings list, for previewing fd/find results.
--- @param filename string
--- @return string[]
M._fzf_preview_find = function(filename)
  if consts.HAS_BAT then
    local style = M._bat_style()
    local theme = M._bat_theme()
    -- "bat --style=%s --theme=%s --color=always --pager=never -- %s"
    local bat_command = {
      consts.BAT,
      style,
      theme,
      "--color=always",
      "--pager=never",
    }
    table.insert(bat_command, "--")
    table.insert(bat_command, filename)
    return bat_command
  else
    -- "cat -n -- %s"
    return {
      consts.CAT,
      "-n",
      "--",
      filename,
    }
  end
end

M.fzf_preview_find = function() end

M._buf_preview_find = function() end

M.buf_preview_find = function() end

-- preview fd/find results with cat/bat }

-- for rg/grep, the line number is the 2nd column split by colon ':'.
-- so we set fzf's option '--preview-window=+{2}-/2' + '--delimiter=:' (see live_grep).
-- the `+{2}-/2` indicates:
--   1. the 2nd column (split by colon ':') is the line number
--   2. set it as the highlight line
--   3. place it in the center (1/2) of the whole preview window
--
--- @param filename string
--- @param lineno integer?
--- @return string[]
M.preview_files = function(filename, lineno)
  if consts.HAS_BAT then
    local style = M._bat_style()
    local theme = M._bat_theme()

    -- "%s --style=%s --theme=%s --color=always --pager=never --highlight-line=%s -- %s"
    local bat_command = {
      consts.BAT,
      style,
      theme,
      "--color=always",
      "--pager=never",
    }
    if type(lineno) == "number" then
      table.insert(bat_command, "--highlight-line=" .. lineno)
    end
    table.insert(bat_command, "--")
    table.insert(bat_command, filename)
    return bat_command
  else
    -- "cat %s"
    return {
      consts.CAT,
      "-n",
      "--",
      filename,
    }
  end
end

--- @param line string
--- @return string[]
M.preview_files_find = function(line)
  local parsed = parsers_helper.parse_find(line)
  return M.preview_files(parsed.filename)
end

-- preview files with nvim buffer.
--- @param line string
--- @return {filename:string}
M.buffer_preview_files_find = function(line)
  local parsed = parsers_helper.parse_find(line)
  return { filename = parsed.filename }
end

-- files }

-- live grep {

--- @param line string
--- @return string[]
M.preview_files_grep = function(line)
  local parsed = parsers_helper.parse_grep(line)
  return M.preview_files(parsed.filename, parsed.lineno)
end

--- @param line string
--- @return {filename:string,lineno:integer?}?
M.buffer_preview_files_grep = function(line)
  local parsed = parsers_helper.parse_grep(line)
  return { filename = parsed.filename, lineno = parsed.lineno }
end

--- @param line string
--- @param context fzfx.PipelineContext
--- @return string[]|nil
M.preview_files_grep_no_filename = function(line, context)
  local bufnr = tbl.tbl_get(context, "bufnr")
  if not num.ge(bufnr, 0) or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = path.normalize(filename, { double_backslash = true, expand = true })
  local parsed = parsers_helper.parse_grep_no_filename(line)
  return M.preview_files_with_line_range(filename, parsed.lineno)
end

--- @param line string
--- @param context fzfx.PipelineContext
--- @return {filename:string,lineno:integer?}?
M.buffer_preview_files_grep_no_filename = function(line, context)
  local bufnr = tbl.tbl_get(context, "bufnr")
  if not num.ge(bufnr, 0) or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = path.normalize(filename, { double_backslash = true, expand = true })
  local parsed = parsers_helper.parse_grep_no_filename(line)
  return { filename = filename, lineno = parsed.lineno }
end

-- live grep }

-- previewer window {

local PREVIEW_WINDOW_OFFSET = 6

--- @return integer
M.get_preview_window_width = function()
  local win_width = vim.api.nvim_win_get_width(0)
  return math.floor(math.max(3, win_width / 2 - PREVIEW_WINDOW_OFFSET))
end

--- @return integer
M.get_preview_window_center = function()
  local win_height = vim.api.nvim_win_get_height(0)
  return math.floor(math.max(3, win_height / 2 - PREVIEW_WINDOW_OFFSET))
end

-- previewer window }

-- git commits {

--- @param commit string
--- @return string?
M._make_preview_git_commit = function(commit)
  if consts.HAS_DELTA then
    local win_width = M.get_preview_window_width()
    return string.format([[git show %s | delta -n --tabs 4 --width %d]], commit, win_width)
  else
    return string.format([[git show --color=always %s]], commit)
  end
end

M.preview_git_commit = function(line)
  if str.isspace(line:sub(1, 1)) then
    return nil
  end
  local first_space_pos = str.find(line, " ")
  local commit = line:sub(1, first_space_pos - 1)
  return M._make_preview_git_commit(commit)
end

-- git commits }

-- vim commands/keymaps {

-- for self-rendered lines (unlike rg/grep), we don't have the line number split by colon ':'.
-- thus we cannot set fzf's option '--preview-window=+{2}-/2' or '--delimiter=:' (see `preview_files`).
-- so we set `--line-range=40:` (in bat) to place the highlight line in the center of the preview window.
--
--- @param filename string
--- @param lineno integer
--- @return string[]
M.preview_files_with_line_range = function(filename, lineno)
  if consts.HAS_BAT then
    local style = M._bat_style()
    local theme = M._bat_theme()

    -- "%s --style=%s --theme=%s --color=always --pager=never --highlight-line=%s -- %s"
    local bat_command = {
      consts.BAT,
      style,
      theme,
      "--color=always",
      "--pager=never",
    }
    table.insert(bat_command, "--highlight-line=" .. lineno)
    table.insert(bat_command, "--line-range")
    table.insert(
      bat_command,
      string.format("%d:", math.max(lineno - M.get_preview_window_center(), 1))
    )
    table.insert(bat_command, "--")
    table.insert(bat_command, filename)
    return bat_command
  else
    -- "cat %s"
    return {
      "cat",
      filename,
    }
  end
end

-- vim commands/keymaps }

return M
