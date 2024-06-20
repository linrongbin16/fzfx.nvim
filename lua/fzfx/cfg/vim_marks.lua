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

-- Get the `:marks` output as lines.
-- The ':marks' output looks like:
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
--
--- @return string[]
M._get_marks_output_in_lines = function()
  local tmpfile = vim.fn.tempname() --[[@as string]]
  vim.cmd(string.format(
    [[
    redir! > %s
    silent execute 'marks'
    redir END
    ]],
    tmpfile
  ))
  local lines = fileio.readlines(tmpfile) --[[@as string[] ]]
  return lines
end

-- Parse the header (first) line of `:marks` outputs, returns the "mark", "lineno", "col", "file/text" index positions.
--- @alias fzfx.VimMarksHeaderPosition {mark_pos:integer,lineno_pos:integer,col_pos:integer,file_text_pos:integer}
--- @param header string
--- @return fzfx.VimMarksHeaderPosition
M._parse_output_header = function(header)
  local MARK = "mark"
  local LINE = "line"
  local COL = "col"
  local FILE_TEXT = "file/text"

  log.ensure(
    string.len(header) > 0,
    string.format("invalid 'marks' first line output:%s", vim.inspect(header))
  )
  local mark_pos = str.find(header, MARK) --[[@as integer]]
  log.ensure(
    num.ge(mark_pos, 0),
    string.format("invalid 'marks' first line, failed to find 'mark':%s", vim.inspect(header))
  )
  local lineno_pos = str.find(header, LINE, mark_pos + string.len(MARK)) --[[@as integer]]
  log.ensure(
    num.ge(lineno_pos, 0),
    string.format("invalid 'marks' first line, failed to find 'line':%s", vim.inspect(header))
  )
  local col_pos = str.find(header, COL, lineno_pos + string.len(LINE)) --[[@as integer]]
  log.ensure(
    num.ge(col_pos, 0),
    string.format("invalid 'marks' first line, failed to find 'col':%s", vim.inspect(header))
  )
  local file_text_pos = str.find(header, FILE_TEXT, col_pos + string.len(COL)) --[[@as integer]]
  log.ensure(
    num.ge(file_text_pos, 0),
    string.format("invalid 'marks' first line, failed to find 'file/text':%s", vim.inspect(header))
  )

  return {
    mark_pos = mark_pos,
    lineno_pos = lineno_pos,
    col_pos = col_pos,
    file_text_pos = file_text_pos,
  }
end

--- @param output_lines string[]
--- @return string[]
M._get_marks = function(output_lines)
  local marks = {}
  for _, line in ipairs(output_lines) do
    if str.not_empty(line) then
      table.insert(marks, line)
    end
  end
  return marks
end

--- @param query string
--- @param context fzfx.VimMarksPipelineContext
--- @return string[]
M._provider = function(query, context)
  return context.marks
end

M.providers = {
  key = "default",
  provider = M._provider,
  provider_type = ProviderTypeEnum.LIST,
}

--- @param line string
--- @param context fzfx.VimMarksPipelineContext
--- @return string[]|nil
M._previewer = function(line, context)
  if str.empty(line) then
    return nil
  end
  local parsed = parsers_helper.parse_vim_mark(line, context)
  log.debug(
    string.format(
      "|_vim_marks_previewer| line:%s, context:%s, parsed:%s",
      vim.inspect(line),
      vim.inspect(context),
      vim.inspect(parsed)
    )
  )
  log.debug(
    string.format(
      "|_vim_marks_previewer| tbl_not_empty(parsed):%s, isfile:%s, lineno:%s",
      vim.inspect(tbl.tbl_not_empty(parsed)),
      vim.inspect(path.isfile(parsed.filename or "")),
      vim.inspect(num.ge(parsed.lineno, 0))
    )
  )
  if
    tbl.tbl_not_empty(parsed)
    and path.isfile(parsed.filename or "")
    and num.ge(parsed.lineno, 0)
  then
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
  previewer = M._previewer,
  previewer_type = PreviewerTypeEnum.COMMAND_LIST,
  previewer_label = labels_helper.label_vim_mark,
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_vim_mark,
  ["double-click"] = actions_helper.edit_vim_mark,
  ["ctrl-q"] = actions_helper.setqflist_vim_mark,
}

M.fzf_opts = {
  "--no-multi",
  "--header-lines=1",
  { "--preview-window", "~1" },
  { "--prompt", "Marks > " },
}

--- @alias fzfx.VimMarksPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,marks:string[],mark_pos:integer,lineno_pos:integer,col_pos:integer,file_text_pos:integer}
--- @return fzfx.VimMarksPipelineContext
M._context_maker = function()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }

  local output_lines = M._get_marks_output_in_lines()
  local marks = M._get_marks(output_lines)
  local header = marks[1]
  local positions = M._parse_output_header(header)

  ctx.marks = marks
  ctx.mark_pos = positions.mark_pos
  ctx.lineno_pos = positions.lineno_pos
  ctx.col_pos = positions.col_pos
  ctx.file_text_pos = positions.file_text_pos
  return ctx
end

M.other_opts = {
  context_maker = M._context_maker,
}

return M
