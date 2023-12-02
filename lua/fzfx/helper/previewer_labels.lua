local parsers = require("fzfx.helper.parsers")
local strs = require("fzfx.lib.strings")
local nums = require("fzfx.lib.numbers")
local tbls = require("'fzfx.lib.tables")

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

--- @param parser fun(line:string):table|string
--- @return fun(line:string):string?
local function _make_ls_previewer_label(parser)
  --- @param line string
  --- @return string?
  local function impl(line)
    if type(line) ~= "string" or string.len(line) == 0 then
      return ""
    end
    return parser(line) --[[@as string]]
  end
  return impl
end

local ls_previewer_label = _make_ls_previewer_label(line_helpers.parse_ls)
local lsd_previewer_label = _make_ls_previewer_label(line_helpers.parse_lsd)
local eza_previewer_label = _make_ls_previewer_label(line_helpers.parse_eza)

local M = {
  -- find/buffers/git files
  _make_find_previewer_label = _make_find_previewer_label,
  find_previewer_label = label_find,

  -- rg/grep
  _make_rg_previewer_label = _make_rg_previewer_label,
  rg_previewer_label = rg_previewer_label,
  _make_grep_previewer_label = _make_grep_previewer_label,
  grep_previewer_label = grep_previewer_label,

  -- command/keymap
  _make_vim_command_previewer_label = _make_label_vim_command,
  vim_command_previewer_label = vim_command_previewer_label,
  vim_keymap_previewer_label = vim_keymap_previewer_label,

  -- file explorer
  _make_ls_previewer_label = _make_ls_previewer_label,
  ls_previewer_label = ls_previewer_label,
  lsd_previewer_label = lsd_previewer_label,
  eza_previewer_label = eza_previewer_label,
}

return M
