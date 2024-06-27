local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")
local num = require("fzfx.commons.num")

local parsers = require("fzfx.helper.parsers")

local M = {}

-- Make label for fd/find results. It's only the filename without prepending filepath.
--- @param line string?
--- @return string
M.label_find = function(line)
  if str.empty(line) then
    return ""
  end
  local parsed = parsers.parse_find(line --[[@as string]])
  return vim.fn.fnamemodify(parsed.filename, ":t") or ""
end

-- Make label for rg results. It's only the filename without prepending filepath, line number and column number.
--- @param line string?
--- @return string
M.label_rg = function(line)
  if str.empty(line) then
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

-- Make label for rg results with no filename. It looks the same with `label_rg` result.
--- @param line string?
--- @param context fzfx.PipelineContext?
--- @return string
M.label_rg_no_filename = function(line, context)
  if str.empty(line) then
    return ""
  end
  local bufnr = tbl.tbl_get(context, "bufnr")
  if type(bufnr) ~= "number" or not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = path.normalize(filename, { double_backslash = true, expand = true })

  local parsed = parsers.parse_rg_no_filename(line --[[@as string]])
  return string.format(
    "%s:%d%s",
    vim.fn.fnamemodify(filename, ":t"),
    parsed.lineno,
    type(parsed.column) == "number" and string.format(":%d", parsed.column) or ""
  )
end

-- Make label for grep/`git grep` results. It's only the filename without prepending filepath, and line number (there's no column number).
--- @param line string?
--- @return string?
M.label_grep = function(line)
  if str.empty(line) then
    return ""
  end
  local parsed = parsers.parse_grep(line --[[@as string]])
  return string.format("%s:%d", vim.fn.fnamemodify(parsed.filename, ":t"), parsed.lineno or 1)
end

-- Make label for grep/`git grep` results with no filename. It looks same with `label_grep` result.
--- @param line string?
--- @param context fzfx.PipelineContext?
--- @return string?
M.label_grep_no_filename = function(line, context)
  if str.empty(line) then
    return ""
  end
  local bufnr = tbl.tbl_get(context, "bufnr")
  if type(bufnr) ~= "number" or not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = path.normalize(filename, { double_backslash = true, expand = true })

  local parsed = parsers.parse_grep_no_filename(line --[[@as string]])
  return string.format("%s:%d", vim.fn.fnamemodify(filename, ":t"), parsed.lineno or 1)
end

-- Make label for vim command or keymap.
--- @param parser fun(line:string,context:any):table
--- @param default_label string
--- @return fun(line:string,context:fzfx.VimCommandsPipelineContext|fzfx.VimKeyMapsPipelineContext):string
M._make_label_vim_command_or_keymap = function(parser, default_label)
  --- @param line string?
  --- @param context fzfx.VimCommandsPipelineContext
  --- @return string
  local function impl(line, context)
    if str.empty(line) then
      return ""
    end
    local parsed = parser(line --[[@as string]], context)
    if
      tbl.tbl_not_empty(parsed)
      and str.not_empty(parsed.filename)
      and type(parsed.lineno) == "number"
    then
      return string.format("%s:%d", vim.fn.fnamemodify(parsed.filename, ":t"), parsed.lineno)
    end
    return default_label
  end
  return impl
end

M.label_vim_command = M._make_label_vim_command_or_keymap(parsers.parse_vim_command, "Definition")
M.label_vim_keymap = M._make_label_vim_command_or_keymap(parsers.parse_vim_keymap, "Definition")

-- Make label for lsd/eza/exa/ls.
--- @param parser fun(line:string, context:any):table
--- @return fun(line:string, context:fzfx.FileExplorerPipelineContext):string?
M._make_label_ls = function(parser)
  --- @param line string
  --- @param context fzfx.FileExplorerPipelineContext
  --- @return string?
  local function impl(line, context)
    if str.empty(line) then
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

--- @param line string?
--- @param context fzfx.VimMarksPipelineContext
--- @return string
M.label_vim_mark = function(line, context)
  if str.empty(line) then
    return ""
  end
  local parsed = parsers.parse_vim_mark(line --[[@as string]], context)
  local filename = parsed.filename
  if str.empty(filename) then
    filename = vim.api.nvim_buf_get_name(context.bufnr)
  end
  if
    str.not_empty(filename) and path.isfile(filename --[[@as string]])
  then
    return string.format(
      "%s:%d:%d",
      vim.fn.fnamemodify(filename --[[@as string]], ":t"),
      parsed.lineno or 1,
      parsed.col or 1
    )
  else
    return string.format("%d:%d", parsed.lineno or 1, parsed.col or 1)
  end
end

return M
