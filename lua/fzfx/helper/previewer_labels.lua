local tables = require("fzfx.commons.tables")
local strings = require("fzfx.commons.strings")
local paths = require("fzfx.commons.paths")
local numbers = require("fzfx.commons.numbers")

local parsers = require("fzfx.helper.parsers")

local M = {}

--- @param line string?
--- @return string
M.label_find = function(line)
  if strings.empty(line) then
    return ""
  end
  local parsed = parsers.parse_find(line --[[@as string]])
  return vim.fn.fnamemodify(parsed.filename, ":t") or ""
end

--- @param line string?
--- @return string
M.label_rg = function(line)
  if strings.empty(line) then
    return ""
  end
  local parsed = parsers.parse_rg(line --[[@as string]])
  return string.format(
    "%s:%d%s",
    vim.fn.fnamemodify(parsed.filename, ":t"),
    parsed.lineno,
    type(parsed.column) == "number" and string.format(":%d", parsed.column) or ""
  )
end

--- @param line string?
--- @return string?
M.label_grep = function(line)
  if strings.empty(line) then
    return ""
  end
  local parsed = parsers.parse_grep(line --[[@as string]])
  return string.format("%s:%d", vim.fn.fnamemodify(parsed.filename, ":t"), parsed.lineno or 1)
end

--- @param line string?
--- @param context fzfx.PipelineContext?
--- @return string
M.label_rg_no_filename = function(line, context)
  if strings.empty(line) then
    return ""
  end
  local bufnr = tables.tbl_get(context, "bufnr")
  if not numbers.ge(bufnr, 0) or not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end
  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = paths.normalize(filename, { double_backslash = true, expand = true })
  local parsed = parsers.parse_rg_no_filename(line --[[@as string]])
  return string.format(
    "%s:%d%s",
    vim.fn.fnamemodify(filename, ":t"),
    parsed.lineno,
    type(parsed.column) == "number" and string.format(":%d", parsed.column) or ""
  )
end

--- @param line string?
--- @param context fzfx.PipelineContext?
--- @return string?
M.label_grep_no_filename = function(line, context)
  if strings.empty(line) then
    return ""
  end
  local bufnr = tables.tbl_get(context, "bufnr")
  if not numbers.ge(bufnr, 0) or not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end
  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = paths.normalize(filename, { double_backslash = true, expand = true })
  local parsed = parsers.parse_grep_no_filename(line --[[@as string]])
  return string.format("%s:%d", vim.fn.fnamemodify(filename, ":t"), parsed.lineno or 1)
end

--- @param parser fun(line:string,context:fzfx.VimCommandsPipelineContext|fzfx.VimKeyMapsPipelineContext):table|string
--- @param default_value string
--- @return fun(line:string,context:fzfx.VimCommandsPipelineContext|fzfx.VimKeyMapsPipelineContext):string
M._make_label_vim_command_or_keymap = function(parser, default_value)
  --- @param line string?
  --- @param context fzfx.VimCommandsPipelineContext
  --- @return string
  local function impl(line, context)
    if strings.empty(line) then
      return ""
    end
    local parsed = parser(line --[[@as string]], context)
    if
      tables.tbl_not_empty(parsed)
      and strings.not_empty(parsed.filename)
      and type(parsed.lineno) == "number"
    then
      return string.format("%s:%d", vim.fn.fnamemodify(parsed.filename, ":t"), parsed.lineno)
    end
    return default_value
  end
  return impl
end

M.label_vim_command = M._make_label_vim_command_or_keymap(parsers.parse_vim_command, "Definition")
M.label_vim_keymap = M._make_label_vim_command_or_keymap(parsers.parse_vim_keymap, "Definition")

--- @param parser fun(line:string, context:fzfx.FileExplorerPipelineContext):table
--- @return fun(line:string, context:fzfx.FileExplorerPipelineContext):string?
M._make_label_ls = function(parser)
  --- @param line string
  --- @param context fzfx.FileExplorerPipelineContext
  --- @return string?
  local function impl(line, context)
    if strings.empty(line) then
      return ""
    end
    local parsed = parser(line, context) --[[@as table]]
    return vim.fn.fnamemodify(parsed.filename, ":t")
  end
  return impl
end

M.label_ls = M._make_label_ls(parsers.parse_ls)
M.label_lsd = M._make_label_ls(parsers.parse_lsd)
M.label_eza = M._make_label_ls(parsers.parse_eza)

return M
