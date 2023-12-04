local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")
local cmds = require("fzfx.lib.commands")
local colors = require("fzfx.lib.colors")
local paths = require("fzfx.lib.paths")
local fs = require("fzfx.lib.filesystems")
local tbls = require("fzfx.lib.tables")

local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local queries_helper = require("fzfx.helper.queries")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")

local M = {}

-- files {

--- @return string, string
M._bat_style_theme = function()
  local style = "numbers,changes"
  if
    type(vim.env["BAT_STYLE"]) == "string"
    and string.len(vim.env["BAT_STYLE"]) > 0
  then
    style = vim.env["BAT_STYLE"]
  end
  local theme = "base16"
  if
    type(vim.env["BAT_THEME"]) == "string"
    and string.len(vim.env["BAT_THEME"]) > 0
  then
    theme = vim.env["BAT_THEME"]
  end
  return style, theme
end

--- @param filename string
--- @param lineno integer?
--- @return fun():string[]
M._make_preview_files = function(filename, lineno)
  --- @return string[]
  local function impl()
    if consts.HAS_BAT then
      local style, theme = M._bat_style_theme()
      -- "%s --style=%s --theme=%s --color=always --pager=never --highlight-line=%s -- %s"
      return type(lineno) == "number"
          and {
            consts.BAT,
            "--style=" .. style,
            "--theme=" .. theme,
            "--color=always",
            "--pager=never",
            "--highlight-line=" .. lineno,
            "--",
            filename,
          }
        or {
          consts.BAT,
          "--style=" .. style,
          "--theme=" .. theme,
          "--color=always",
          "--pager=never",
          "--",
          filename,
        }
    else
      -- "cat %s"
      return {
        "cat",
        filename,
      }
    end
  end
  return impl
end

--- @param line string
--- @return string[]
M._preview_files_find = function(line)
  local parsed = parsers_helper.parse_find(line)
  local f = M._make_preview_files(parsed.filename)
  return f()
end

M.preview_files_restricted_mode = M._preview_files_find
M.preview_files_unrestricted_mode = M._preview_files_find

-- files }

-- live grep {

--- @param line string
--- @return string[]
M._preview_files_grep = function(line)
  local parsed = parsers_helper.parse_grep(line)
  local f = M._make_preview_files(parsed.filename, parsed.lineno)
  return f()
end

M.preview_live_grep_restricted_mode = M._preview_files_grep
M.preview_live_grep_unrestricted_mode = M._preview_files_grep
M.preview_live_grep_buffer_mode = M._preview_files_grep

-- live grep }

return M
