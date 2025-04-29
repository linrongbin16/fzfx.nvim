local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")

local consts = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers = require("fzfx.helper.parsers")

local M = {}

-- No-operation {

-- Do nothing, no-operation.
M.nop = function() end

-- No-operation }

-- Confirm if discard current editing buffer when it's been modified.
--- @param bufnr integer
--- @param callback fun():any
local function _confirm(bufnr, callback)
  if not vim.o.hidden and vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
    local ok, input = pcall(vim.fn.input, {
      prompt = "[fzfx] buffer has been modified, continue? (y/n) ",
      cancelreturn = "n",
    })
    if ok and str.not_empty(input) and str.startswith(input, "y", { ignorecase = true }) then
      vim.schedule(callback)
    else
      log.echo(LogLevels.INFO, "cancelled.")
    end
  else
    callback()
  end
end

-- Execute either vim commands or lua functions.
--- @param cmds any[]
--- @param opts {scheduled:boolean?}?
local function _execute(cmds, opts)
  assert(type(cmds) == "table")
  opts = opts or {}

  local i = 1
  local n = #cmds

  --- @param f string|function
  local function exe_impl(f)
    assert(type(f) == "string" or type(f) == "function")
    if type(f) == "string" then
      vim.cmd(f)
    else
      f()
    end
  end

  local function scheduled_impl()
    ---@diagnostic disable-next-line: need-check-nil
    local c = cmds[i] --[[@as string|function]]
    vim.schedule(function()
      exe_impl(c)
      i = i + 1
      if i <= n then
        scheduled_impl()
      end
    end)
  end

  local function non_scheduled_impl()
    for _, c in
      ipairs(cmds --[[@as any[] ]])
    do
      exe_impl(c)
    end
  end

  if opts.scheduled then
    scheduled_impl()
  else
    non_scheduled_impl()
  end
end

-- fd/find {

-- Make `:edit!` commands for fd/find results.
--- @param lines string[]
--- @return string[]
M._make_edit_find = function(lines)
  local results = {}
  for i, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_find(line)
      table.insert(results, string.format("edit! %s", parsed.filename))
    end
  end
  return results
end

-- Run `:edit!` commands for fd/find results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_find = function(lines, context)
  local cmds = M._make_edit_find(lines)
  _confirm(context.bufnr, function()
    _execute(cmds)
  end)
end

-- Make `:setqflist` commands for fd/find results.
--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer}[]
M._make_setqflist_find = function(lines)
  local results = {}
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_find(line)
      table.insert(results, { filename = parsed.filename, lnum = 1, col = 1 })
    end
  end
  return results
end

-- Run `:copen` and `:setqflist` commands for fd/find results.
--- @param lines string[]
M.setqflist_find = function(lines)
  local qfs = M._make_setqflist_find(lines)
  _execute({
    "copen",
    function()
      vim.fn.setqflist({}, " ", {
        items = qfs,
      })
    end,
  })
end

-- fd/find }

-- rg {

-- Make `:edit!` and `:call cursor` commands for rg results.
--- @param lines string[]
--- @return string[]
M._make_edit_rg = function(lines)
  local results = {}
  local last_parsed
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_rg(line)
      table.insert(results, string.format("edit! %s", parsed.filename))
      last_parsed = parsed
    end
  end

  -- For the last position, move cursor to it.
  if last_parsed ~= nil and last_parsed.lineno ~= nil then
    table.insert(
      results,
      string.format("call cursor(%d, %d)", last_parsed.lineno, last_parsed.column or 1)
    )
    table.insert(results, 'execute "normal! zz"')
  end

  return results
end

-- Run `:edit!`, `:call cursor` and `:normal! zz` commands for rg results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_rg = function(lines, context)
  local cmds = M._make_edit_rg(lines)
  _confirm(context.bufnr, function()
    _execute(cmds, { scheduled = true })
  end)
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer,text:string}[]
M._make_setqflist_rg = function(lines)
  local qfs = {}
  for _, line in ipairs(lines) do
    local parsed = parsers.parse_rg(line)
    table.insert(qfs, {
      filename = parsed.filename,
      lnum = parsed.lineno,
      col = parsed.column,
      text = parsed.text,
    })
  end
  return qfs
end

--- @param lines string[]
M.setqflist_rg = function(lines)
  local qfs = M._make_setqflist_rg(lines)
  _execute({
    "copen",
    function()
      vim.fn.setqflist({}, " ", {
        items = qfs,
      })
    end,
  })
end

-- rg }

-- grep {

-- Run `:edit!` commands for grep results.
--- @param lines string[]
--- @return string[]
M._make_edit_grep = function(lines)
  local results = {}
  local last_parsed
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_grep(line)
      table.insert(results, string.format("edit! %s", parsed.filename))
      last_parsed = parsed
    end
  end

  if last_parsed ~= nil and last_parsed.lineno ~= nil then
    table.insert(results, string.format("call cursor(%d, %d)", last_parsed.lineno, 1))
    table.insert(results, 'execute "normal! zz"')
  end

  return results
end

-- Run `:edit!`, `:call cursor` and `:normal! zz` commands for grep results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_grep = function(lines, context)
  local cmds = M._make_edit_grep(lines)
  _confirm(context.bufnr, function()
    _execute(cmds, { scheduled = true })
  end)
end

-- Make `:setqflist` commands for grep results.
--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer,text:string}[]
M._make_setqflist_grep = function(lines)
  local qfs = {}
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_grep(line)
      table.insert(qfs, {
        filename = parsed.filename,
        lnum = parsed.lineno,
        col = 1,
        text = parsed.text,
      })
    end
  end
  return qfs
end

-- Run `:call setqflist` commands for grep results.
--- @param lines string[]
M.setqflist_grep = function(lines)
  local qfs = M._make_setqflist_grep(lines)
  _execute({
    "copen",
    function()
      vim.fn.setqflist({}, " ", {
        items = qfs,
      })
    end,
  })
end

-- grep }

-- rg no filename {

-- Make `:call cursor` and `:normal! zz` commands for rg results (no filename).
--- @param lines string[]
--- @return string[]|nil
M._make_cursor_move_rg_bufnr = function(lines)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local results = {}
  local parsed = parsers.parse_rg_bufnr(line)
  table.insert(results, string.format("call cursor(%d, %d)", parsed.lineno, parsed.column or 1))
  table.insert(results, 'execute "normal! zz"')
  return results
end

-- Run `:call cursor` and `:normal! zz` commands on rg results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.cursor_move_rg_bufnr = function(lines, context)
  local cmds = M._make_cursor_move_rg_bufnr(lines)
  if not cmds then
    return
  end

  _confirm(context.bufnr, function()
    _execute(cmds)
  end)
end

-- Make `:setqflist` commands for rg results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext?
--- @return {filename:string,lnum:integer,col:integer,text:string}[]|nil
M._make_setqflist_rg_bufnr = function(lines, context)
  local bufnr = tbl.tbl_get(context, "bufnr")
  if type(bufnr) ~= "number" or not vim.api.nvim_buf_is_valid(bufnr) then
    log.echo(LogLevels.INFO, string.format("invalid buffer(%s).", vim.inspect(bufnr)))
    return nil
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = path.normalize(filename, { double_backslash = true, expand = true })

  local qfs = {}
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_rg_bufnr(line)
      table.insert(qfs, {
        filename = filename,
        lnum = parsed.lineno,
        col = parsed.column or 1,
        text = parsed.text,
      })
    end
  end

  return qfs
end

-- Run `:setqflist` commands for rg results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext?
M.setqflist_rg_bufnr = function(lines, context)
  local qfs = M._make_setqflist_rg_bufnr(lines, context)
  if not qfs then
    return
  end

  _execute({
    "copen",
    function()
      vim.fn.setqflist({}, " ", {
        items = qfs,
      })
    end,
  })
end

-- rg no file name }

-- grep no filename {

--- @param lines string[]
--- @return string[]|nil
M._make_cursor_move_grep_bufnr = function(lines)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local results = {}
  local parsed = parsers.parse_grep_bufnr(line)
  table.insert(results, string.format("call cursor(%d, %d)", parsed.lineno, 1))
  table.insert(results, 'execute "normal! zz"')
  return results
end

-- Run `:call cursor` commands on grep results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.cursor_move_grep_bufnr = function(lines, context)
  local cmds = M._make_cursor_move_grep_bufnr(lines)
  if not cmds then
    return
  end

  _confirm(context.bufnr, function()
    _execute(cmds)
  end)
end

-- Make `:setqflist` commands for grep results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext?
--- @return {filename:string,lnum:integer,col:integer,text:string}[]|nil
M._make_setqflist_grep_bufnr = function(lines, context)
  local bufnr = tbl.tbl_get(context, "bufnr")
  if type(bufnr) ~= "number" or not vim.api.nvim_buf_is_valid(bufnr) then
    log.echo(LogLevels.INFO, string.format("invalid buffer(%s).", vim.inspect(bufnr)))
    return nil
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = path.normalize(filename, { double_backslash = true, expand = true })

  local qfs = {}
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_grep_bufnr(line)
      table.insert(qfs, {
        filename = filename,
        lnum = parsed.lineno,
        col = 1,
        text = parsed.text,
      })
    end
  end

  return qfs
end

-- Run `:setqflist` commands for grep results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext?
M.setqflist_grep_bufnr = function(lines, context)
  local qfs = M._make_setqflist_grep_bufnr(lines, context)
  if not qfs then
    return
  end

  _execute({
    "copen",
    function()
      vim.fn.setqflist({}, " ", {
        items = qfs,
      })
    end,
  })
end

-- grep no filename }

-- ls {

-- Make `:edit!` commands for lsd/eza/exa/ls results.
--- @param lines string[]
--- @param context fzfx.FileExplorerPipelineContext
--- @return string[]
M._make_edit_ls = function(lines, context)
  local results = {}
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = nil
      if consts.HAS_LSD then
        -- lsd
        parsed = parsers.parse_lsd(line, context)
      elseif consts.HAS_EZA then
        -- eza/exa
        parsed = parsers.parse_eza(line, context)
      else
        -- ls
        parsed = parsers.parse_ls(line, context)
      end
      table.insert(results, string.format("edit! %s", parsed.filename))
    end
  end
  return results
end

-- Run `:edit!` commands for lsd/eza/exa/ls results.
--- @param lines string[]
--- @param context fzfx.FileExplorerPipelineContext
M.edit_ls = function(lines, context)
  local cmds = M._make_edit_ls(lines, context)

  _confirm(context.bufnr, function()
    _execute(cmds)
  end)
end

-- ls }

-- git branch {

-- Make `:!git checkout` commands for git branch results.
--- @param lines string[]
--- @param context fzfx.GitBranchesPipelineContext
--- @return string?
M._make_git_checkout = function(lines, context)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local parsed = parsers.parse_git_branch(line, context)
  return string.format("!git checkout %s", parsed.local_branch)
end

-- Run `:!git checkout` commands for git branch results.
--- @param lines string[]
--- @param context fzfx.GitBranchesPipelineContext
M.git_checkout = function(lines, context)
  local checkout = M._make_git_checkout(lines, context) --[[@as string]]
  if str.not_empty(checkout) then
    vim.cmd(checkout)
  end
end

-- git branch }

-- git commit {

-- Make `:let @+ =` commands (yank text) for git log/commit results.
--- @param lines string[]
--- @return string?
M._make_yank_git_commit = function(lines)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local parsed = parsers.parse_git_commit(line)
  return string.format("let @+ = '%s'", parsed.commit)
end

-- Run `:let @+ =` commands (yank text) for git log/commit results.
--- @param lines string[]
M.yank_git_commit = function(lines)
  local yank = M._make_yank_git_commit(lines)
  if str.not_empty(yank) then
    vim.cmd(yank)
  end
end

-- git commit }

-- commands {

-- Make `:feedkeys` commands for vim command results.
--- @param lines string[]
--- @param context fzfx.VimCommandsPipelineContext
--- @return {input:string, mode:string}?
M._make_feed_vim_command = function(lines, context)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local parsed = parsers.parse_vim_command(line, context)
  return { input = string.format(":%s", parsed.command), mode = "n" }
end

-- Run `:feedkeys` commands for vim command results.
--- @param lines string[]
--- @param context fzfx.VimCommandsPipelineContext
M.feed_vim_command = function(lines, context)
  local feed = M._make_feed_vim_command(lines, context) --[[@as table]]
  if tbl.tbl_not_empty(feed) then
    vim.fn.feedkeys(feed.input, feed.mode)
  end
end

-- commands }

-- key mappings {

-- Make `:feedkeys` or `:cmd` commands for vim key mapping results.
--- @param lines string[]
--- @param context fzfx.VimKeyMapsPipelineContext
--- @return {fn:"cmd"|"feedkeys"|nil, input:string?, mode:string?}?
M._make_feed_vim_key = function(lines, context)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local parsed = parsers.parse_vim_keymap(line, context)
  if str.find(parsed.mode, "n") == nil then
    log.echo(
      LogLevels.INFO,
      string.format("%s (%s mode) not support.", vim.inspect(parsed.lhs), vim.inspect(parsed.mode))
    )
    return nil
  end

  if str.startswith(parsed.lhs, "<plug>", { ignorecase = true }) then
    return {
      fn = "cmd",
      input = string.format('execute "normal %s"', parsed.lhs),
      mode = "n",
    }
  elseif str.startswith(parsed.lhs, "<") and str.rfind(parsed.lhs, ">") ~= nil then
    local tcodes = vim.api.nvim_replace_termcodes(parsed.lhs, true, false, true)
    return { fn = "feedkeys", input = tcodes, mode = "n" }
  else
    return { fn = "feedkeys", input = parsed.lhs, mode = "n" }
  end
end

-- Make `:feedkeys` or `:cmd` commands for vim key mapping results.
--- @param lines string[]
--- @param context fzfx.VimKeyMapsPipelineContext
M.feed_vim_key = function(lines, context)
  local feed = M._make_feed_vim_key(lines, context) --[[@as table]]
  if tbl.tbl_empty(feed) then
    return
  end

  if feed.fn == "cmd" and str.not_empty(feed.input) then
    vim.cmd(feed.input)
  elseif feed.fn == "feedkeys" and str.not_empty(feed.input) and str.not_empty(feed.mode) then
    vim.fn.feedkeys(feed.input, feed.mode)
  end
end

-- key mappings }

-- git status {

-- Make `:edit!` commands for git status results.
--- @param lines string[]
--- @return string[]
M._make_edit_git_status = function(lines)
  local results = {}
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_git_status(line)
      table.insert(results, string.format("edit! %s", parsed.filename))
    end
  end
  return results
end

-- Run `:edit!` commands for gits status results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_git_status = function(lines, context)
  local cmds = M._make_edit_git_status(lines)
  _confirm(context.bufnr, function()
    _execute(cmds)
  end)
end

-- Make `:setqflist` commands for git status results.
--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer}[]
M._make_setqflist_git_status = function(lines)
  local qfs = {}
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_git_status(line)
      table.insert(qfs, { filename = parsed.filename, lnum = 1, col = 1 })
    end
  end
  return qfs
end

-- Run `:setqflist` commands for git status results.
--- @param lines string[]
M.setqflist_git_status = function(lines)
  local qfs = M._make_setqflist_git_status(lines)
  _execute({
    "copen",
    function()
      vim.fn.setqflist({}, " ", {
        items = qfs,
      })
    end,
  })
end

-- git status }

-- marks {

-- Make `:edit!` commands for vim marks results.
--- @param lines string[]
--- @param context fzfx.VimMarksPipelineContext
--- @return string[]
M._make_edit_vim_mark = function(lines, context)
  local results = {}
  local last_parsed
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_vim_mark(line, context)
      if str.not_empty(parsed.filename) then
        table.insert(results, string.format("edit! %s", parsed.filename))
      end
      last_parsed = parsed
    end
  end

  if last_parsed then
    local column = (last_parsed.col or 0) + 1
    table.insert(results, string.format("call cursor(%d, %d)", last_parsed.lineno or 1, column))
    table.insert(results, 'execute "normal! zz"')
  end
  return results
end

-- Run `:edit!` commands for vim marks results.
--- @param lines string[]
--- @param context fzfx.VimMarksPipelineContext
M.edit_vim_mark = function(lines, context)
  local cmds = M._make_edit_vim_mark(lines, context)
  _confirm(context.bufnr, function()
    _execute(cmds, { scheduled = true })
  end)
end

-- Make `:setqflist` commands for vim marks results.
--- @param lines string[]
--- @param context fzfx.VimMarksPipelineContext
--- @return {filename:string,lnum:integer,col:integer,text:string}[]
M._make_setqflist_vim_mark = function(lines, context)
  local qfs = {}
  for _, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_vim_mark(line, context)
      local filename = parsed.filename
      if str.empty(filename) then
        local bufnr = tbl.tbl_get(context, "bufnr")
        if type(bufnr) == "number" and vim.api.nvim_buf_is_valid(bufnr) then
          filename = vim.api.nvim_buf_get_name(bufnr)
          filename = path.normalize(filename, { double_backslash = true, expand = true })
        end
      end
      local column = (parsed.col or 0) + 1
      table.insert(qfs, {
        filename = filename or "",
        lnum = parsed.lineno or 1,
        col = column,
        text = parsed.text or "",
      })
    end
  end
  return qfs
end

-- Run `:setqflist` commands for vim marks results.
--- @param lines string[]
--- @param context fzfx.VimMarksPipelineContext
M.setqflist_vim_mark = function(lines, context)
  local qfs = M._make_setqflist_vim_mark(lines, context)
  _execute({
    "copen",
    function()
      vim.fn.setqflist({}, " ", {
        items = qfs,
      })
    end,
  })
end

-- marks }

-- command history {

-- Make `:feedkeys` commands for vim command history results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
--- @return {input:string, mode:string}?
M._make_feed_vim_historical_command = function(lines, context)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local parsed = parsers.parse_vim_historical_command(line, context)
  return { input = string.format(":%s", parsed.command), mode = "n" }
end

-- Run `:feedkeys` commands for vim command results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.feed_vim_historical_command = function(lines, context)
  local feed = M._make_feed_vim_historical_command(lines, context) --[[@as table]]
  if tbl.tbl_not_empty(feed) then
    vim.fn.feedkeys(feed.input, feed.mode)
  end
end

-- command history }

-- colors {

-- Make `:feedkeys` commands for vim colors results.
--- @param lines string[]
--- @param context fzfx.VimColorsPipelineContext
--- @return {input:string, mode:string}?
M._make_feed_vim_color = function(lines, context)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local parsed = parsers.parse_vim_color(line, context)
  return { input = string.format(":color %s", parsed.colorname), mode = "n" }
end

-- Run `:feedkeys` commands for vim colors results.
--- @param lines string[]
--- @param context fzfx.VimColorsPipelineContext
M.feed_vim_color = function(lines, context)
  local feed = M._make_feed_vim_color(lines, context) --[[@as table]]
  if tbl.tbl_not_empty(feed) then
    vim.fn.feedkeys(feed.input, feed.mode)
  end
end

-- colors }

return M
