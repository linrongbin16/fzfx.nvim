local parsers = require("fzfx.helper.parsers")
local strs = require("fzfx.lib.strings")
local tbls = require("fzfx.lib.tables")

local M = {}

--- @param line string?
--- @return string
M.label_find = function(line)
  if strs.empty(line) then
    return ""
  end
  local parsed = parsers.parse_find(line --[[@as string]])
  return vim.fn.fnamemodify(parsed.filename, ":t") or ""
end

--- @param line string?
--- @return string
M.label_rg = function(line)
  if strs.empty(line) then
    return ""
  end
  local parsed = parsers.parse_rg(line --[[@as string]])
  return string.format(
    "%s:%d%s",
    vim.fn.fnamemodify(parsed.filename, ":t"),
    parsed.lineno,
    type(parsed.column) == "number" and string.format(":%d", parsed.column)
      or ""
  )
end

--- @param line string?
--- @return string?
M.label_grep = function(line)
  if strs.empty(line) then
    return ""
  end
  local parsed = parsers.parse_grep(line --[[@as string]])
  return string.format(
    "%s:%d",
    vim.fn.fnamemodify(parsed.filename, ":t"),
    parsed.lineno or 1
  )
end

--- @param parser fun(line:string,context:fzfx.VimCommandsPipelineContext|fzfx.VimKeyMapsPipelineContext):table|string
--- @param default_value string
--- @return fun(line:string,context:fzfx.VimCommandsPipelineContext|fzfx.VimKeyMapsPipelineContext):string
M._make_label_vim_command_or_keymap = function(parser, default_value)
  --- @param line string?
  --- @param context fzfx.VimCommandsPipelineContext
  --- @return string
  local function impl(line, context)
    if strs.empty(line) then
      return ""
    end
    local parsed = parser(line --[[@as string]], context)
    if
      tbls.tbl_not_empty(parsed)
      and strs.not_empty(parsed.filename)
      and type(parsed.lineno) == "number"
    then
      return string.format(
        "%s:%d",
        vim.fn.fnamemodify(parsed.filename, ":t"),
        parsed.lineno
      )
    end
    return default_value
  end
  return impl
end

M.label_vim_command =
  M._make_label_vim_command_or_keymap(parsers.parse_vim_command, "Definition")
M.label_vim_keymap =
  M._make_label_vim_command_or_keymap(parsers.parse_vim_keymap, "Definition")

--- @param parser fun(line:string, context:fzfx.FileExplorerPipelineContext):table
--- @return fun(line:string, context:fzfx.FileExplorerPipelineContext):string?
M._make_label_ls = function(parser)
  --- @param line string
  --- @param context fzfx.FileExplorerPipelineContext
  --- @return string?
  local function impl(line, context)
    if strs.empty(line) then
      return ""
    end
    local parsed = parser(line, context) --[[@as table]]
    return parsed.filename
  end
  return impl
end

M.label_ls = M._make_label_ls(parsers.parse_ls)
M.label_lsd = M._make_label_ls(parsers.parse_lsd)
M.label_eza = M._make_label_ls(parsers.parse_eza)

return M
