local tbl = require("fzfx.commons.tbl")
local num = require("fzfx.commons.num")
local str = require("fzfx.commons.str")
local fileio = require("fzfx.commons.fileio")
local path = require("fzfx.commons.path")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.command = {
  name = "FzfxMarks",
  desc = "Search marks",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "all_mode",
  },
  {
    name = "n_mode_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "n_mode",
  },
  {
    name = "i_mode_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "i_mode",
  },
  {
    name = "v_mode_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "v_mode",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "all_mode",
  },
  {
    name = "n_mode_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "n_mode",
  },
  {
    name = "i_mode_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "i_mode",
  },
  {
    name = "v_mode_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "v_mode",
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "all_mode",
  },
  {
    name = "n_mode_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "n_mode",
  },
  {
    name = "i_mode_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "i_mode",
  },
  {
    name = "v_mode_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "v_mode",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "all_mode",
  },
  {
    name = "n_mode_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "n_mode",
  },
  {
    name = "i_mode_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "i_mode",
  },
  {
    name = "v_mode_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "v_mode",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "all_mode",
  },
  {
    name = "n_mode_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "n_mode",
  },
  {
    name = "i_mode_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "i_mode",
  },
  {
    name = "v_mode_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "v_mode",
  },
}

-- the ':marks' output looks like:
--
--```
--mark line  col file/text
-- '    543    7 return M
-- 0     18    4 ~/.gitconfig
-- 1      7   41 README.md
-- 2      1    0 spec/contents/hello world.txt
-- 3      2    0 lua/fzfx/detail/general.lua
-- 4    315    0 lua/fzfx/config.lua
-- 5   1225   43 lua/fzfx/detail/general.lua
-- 6      2    0 lua/fzfx/detail/general.lua
-- 7      2    1 lua/fzfx/detail/general.lua
-- 8    569    9 /Users/rlin/github/linrongbin16/fzfx.nvim/lua/fzfx/detail/popup/buffer_popup_window.lua
-- 9   1164   72 lua/fzfx/detail/general.lua
-- "      6    6 local constants = require("fzfx.lib.constants")
-- [      1    0 local tbl = require("fzfx.commons.tbl")
-- ]    543    0 return M
-- ^    134   14 -- the ':marks' output looks like:
-- .    134   13 -- the ':marks' output looks like:
--```
--- @param line string
--- @return fzfx.VimMark
M._parse_map_command_output_line = function(line)
  local first_space_pos = 1
  while first_space_pos <= #line and not str.isspace(line:sub(first_space_pos, first_space_pos)) do
    first_space_pos = first_space_pos + 1
  end
  -- local mode = vim.trim(line:sub(1, first_space_pos - 1))
  while first_space_pos <= #line and str.isspace(line:sub(first_space_pos, first_space_pos)) do
    first_space_pos = first_space_pos + 1
  end
  local second_space_pos = first_space_pos
  while
    second_space_pos <= #line and not str.isspace(line:sub(second_space_pos, second_space_pos))
  do
    second_space_pos = second_space_pos + 1
  end
  local lhs = vim.trim(line:sub(first_space_pos, second_space_pos - 1))
  local result = { lhs = lhs }
  local rhs_or_location = vim.trim(line:sub(second_space_pos))
  local lua_definition_pos = str.find(rhs_or_location, "<Lua ")

  if lua_definition_pos and str.endswith(rhs_or_location, ">") then
    local first_colon_pos = str.find(rhs_or_location, ":", lua_definition_pos + string.len("<Lua ")) --[[@as integer]]
    local last_colon_pos = str.rfind(rhs_or_location, ":") --[[@as integer]]
    local filename = rhs_or_location:sub(first_colon_pos + 1, last_colon_pos - 1)
    local lineno = rhs_or_location:sub(last_colon_pos + 1, #rhs_or_location - 1)
    log.debug(
      "|_parse_map_command_output_line| lhs:%s, filename:%s, lineno:%s",
      vim.inspect(lhs),
      vim.inspect(filename),
      vim.inspect(lineno)
    )
    result.filename = path.normalize(filename, { double_backslash = true, expand = true })
    result.lineno = tonumber(lineno)
  end
  return result
end

--- @return string[], {mark_pos:integer,lineno_pos:integer,col_pos:integer,file_text_pos:integer}
M._get_vim_marks = function()
  local tmpfile = vim.fn.tempname()
  vim.cmd(string.format(
    [[
    redir! > %s
    silent execute 'marks'
    redir END
    ]],
    tmpfile
  ))

  local marks = fileio.readlines(tmpfile --[[@as string]]) --[[@as table]]

  local MARK = "mark"
  local LINE = "line"
  local COL = "col"
  local FILE_TEXT = "file/text"

  local first_line = marks[1]
  log.ensure(
    string.len(first_line) > 0,
    "invalid 'marks' first line output:%s",
    vim.inspect(first_line)
  )
  local mark_pos = str.find(first_line, MARK) --[[@as integer]]
  log.ensure(
    num.ge(mark_pos, 0),
    "invalid 'marks' first line, failed to find 'mark':%s",
    vim.inspect(first_line)
  )
  local lineno_pos = str.find(first_line, LINE, mark_pos + string.len(MARK)) --[[@as integer]]
  log.ensure(
    num.ge(lineno_pos, 0),
    "invalid 'marks' first line, failed to find 'line':%s",
    vim.inspect(first_line)
  )
  local col_pos = str.find(first_line, COL, lineno_pos + string.len(LINE)) --[[@as integer]]
  log.ensure(
    num.ge(col_pos, 0),
    "invalid 'marks' first line, failed to find 'col':%s",
    vim.inspect(first_line)
  )
  local file_text_pos = str.find(first_line, FILE_TEXT, col_pos + string.len(COL)) --[[@as integer]]
  log.ensure(
    num.ge(file_text_pos, 0),
    "invalid 'marks' first line, failed to find 'file/text':%s",
    vim.inspect(first_line)
  )

  local pos = {
    mark_pos = mark_pos,
    lineno_pos = lineno_pos,
    col_pos = col_pos,
    file_text_pos = file_text_pos,
  }

  log.debug("|_get_vim_marks| results:%s", vim.inspect(marks))
  return marks, pos
end

--- @param vk fzfx.VimMark
--- @return string
M._render_vim_keymaps_column_opts = function(vk)
  local mode = vk.mode or ""
  local noremap = vk.noremap and "Y" or "N"
  local nowait = vk.nowait and "Y" or "N"
  local silent = vk.silent and "Y" or "N"
  return string.format("%-4s|%-7s|%-6s|%-6s", mode, noremap, nowait, silent)
end

--- @param keymaps fzfx.VimMark[]
--- @param key_width integer
--- @param opts_width integer
--- @return string[]
M._render_vim_keymaps = function(keymaps, key_width, opts_width)
  --- @param r fzfx.VimMark
  --- @return string?
  local function rendered_def_or_loc(r)
    if
      type(r) == "table"
      and type(r.filename) == "string"
      and string.len(r.filename) > 0
      and type(r.lineno) == "number"
      and r.lineno >= 0
    then
      return string.format("%s:%d", path.reduce(r.filename), r.lineno)
    elseif type(r.rhs) == "string" and string.len(r.rhs) > 0 then
      return string.format('"%s"', r.rhs)
    elseif type(r.desc) == "string" and string.len(r.desc) > 0 then
      return string.format('"%s"', r.desc)
    else
      return ""
    end
  end

  local KEY = "Key"
  local OPTS = "Mode|Noremap|Nowait|Silent"
  local DEF_OR_LOC = "Definition/Location"

  local results = {}
  local formatter = "%-" .. tostring(key_width) .. "s" .. " %-" .. tostring(opts_width) .. "s %s"
  local header = string.format(formatter, KEY, OPTS, DEF_OR_LOC)
  table.insert(results, header)
  log.debug(
    "|_render_vim_keymaps| formatter:%s, header:%s",
    vim.inspect(formatter),
    vim.inspect(header)
  )
  for i, c in ipairs(keymaps) do
    local rendered =
      string.format(formatter, c.lhs, M._render_vim_keymaps_column_opts(c), rendered_def_or_loc(c))
    log.debug("|_render_vim_keymaps| rendered[%d]:%s", i, vim.inspect(rendered))
    table.insert(results, rendered)
  end
  return results
end

--- @param query string
--- @param context fzfx.VimMarksPipelineContext
--- @return string[]|nil
M._vim_marks_provider = function(query, context)
  local marks, _ = M._get_vim_marks()
  return marks
end

M.providers = {
  all_marks = {
    key = "default",
    provider = M._vim_marks_provider,
    provider_type = ProviderTypeEnum.LIST,
  },
}

--- @param line string
--- @param context fzfx.VimMarksPipelineContext
--- @return string[]|nil
M._vim_marks_previewer = function(line, context)
  local parsed = parsers_helper.parse_vim_mark(line, context)
  -- log.debug(
  --   "|fzfx.config - _vim_marks_previewer| line:%s, context:%s, desc_or_loc:%s",
  --   vim.inspect(line),
  --   vim.inspect(context),
  --   vim.inspect(parsed)
  -- )
  if tbl.tbl_not_empty(parsed) and str.not_empty(parsed.filename) and num.ge(parsed.lineno, 0) then
    -- log.debug(
    --   "|fzfx.config - _vim_marks_previewer| loc:%s",
    --   vim.inspect(parsed)
    -- )
    return previewers_helper.preview_files_with_line_range(parsed.filename, parsed.lineno)
  elseif constants.HAS_ECHO and tbl.tbl_not_empty(parsed) then
    -- log.debug(
    --   "|fzfx.config - _vim_marks_previewer| desc:%s",
    --   vim.inspect(parsed)
    -- )
    return { "echo", parsed.text or "" }
  else
    log.echo(LogLevels.INFO, "no echo command found.")
    return nil
  end
end

M.previewers = {
  all_marks = {
    previewer = M._vim_marks_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_keymap,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.feed_vim_key,
  ["double-click"] = actions_helper.feed_vim_key,
}

M.fzf_opts = {
  "--no-multi",
  "--header-lines=1",
  { "--preview-window", "~1" },
  { "--prompt", "Key Maps > " },
}

--- @param keys fzfx.VimMark[]
--- @return integer,integer
M._render_vim_keymaps_columns_status = function(keys)
  local KEY = "Key"
  local OPTS = "Mode|Noremap|Nowait|Silent"
  local max_key = string.len(KEY)
  local max_opts = string.len(OPTS)
  for _, k in ipairs(keys) do
    max_key = math.max(max_key, string.len(k.lhs))
    max_opts = math.max(max_opts, string.len(M._render_vim_keymaps_column_opts(k)))
  end
  log.debug(
    "|_render_vim_keymaps_columns_status| lhs:%s, opts:%s",
    vim.inspect(max_key),
    vim.inspect(max_opts)
  )
  return max_key, max_opts
end

--- @alias fzfx.VimMarksPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,mark_pos:integer,lineno_pos:integer,col_pos:integer,file_text_pos:integer}
--- @return fzfx.VimMarksPipelineContext
M._vim_marks_context_maker = function()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  local _, marks_pos = M._get_vim_marks()
  ctx.mark_pos = marks_pos.mark_pos
  ctx.lineno_pos = marks_pos.lineno_pos
  ctx.col_pos = marks_pos.col_pos
  ctx.file_text_pos = marks_pos.file_text_pos
  return ctx
end

M.other_opts = {
  context_maker = M._vim_marks_context_maker,
}

return M
