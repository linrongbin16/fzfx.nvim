local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local num = require("fzfx.commons.num")
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
M._confirm_discard_modified = function(bufnr, callback)
  if not vim.o.hidden and vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
    local ok, input = pcall(vim.fn.input, {
      prompt = "[fzfx] buffer has been modified, continue? (y/n) ",
      cancelreturn = "n",
    })
    if ok and str.not_empty(input) and str.startswith(input, "y", { ignorecase = true }) then
      callback()
    else
      log.echo(LogLevels.INFO, "cancelled.")
    end
  else
    callback()
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
  local edits = M._make_edit_find(lines)
  M._confirm_discard_modified(context.bufnr, function()
    for _, e in ipairs(edits) do
      vim.cmd(e)
    end
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
  vim.cmd(":copen")
  vim.fn.setqflist({}, " ", {
    nr = "$",
    items = qfs,
  })
end

-- fd/find }

-- rg {

-- Make `:edit!` and `:call setpos` commands for rg results.
--- @param lines string[]
--- @return {edits:string[],setpos:{lineno:integer,column:integer}?}
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
      string.format("call setpos('.', [0, %d, %d])", last_parsed.lineno, column)
    )
    table.insert(results, 'execute "normal! zz"')
  end

  return results
end

-- Run `:edit!`, `:call setpos` and `:normal! zz` commands for rg results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_rg = function(lines, context)
  local edits = M._make_edit_rg(lines)
  M._confirm_discard_modified(context.bufnr, function()
    for _, e in ipairs(edits) do
      vim.cmd(e)
    end
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
  vim.cmd(":copen")
  vim.fn.setqflist({}, " ", {
    nr = "$",
    items = qfs,
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
    table.insert(results, string.format("call setpos('.', [0, %d, %d])", last_parsed.lineno, 1))
    table.insert(results, 'execute "normal! zz"')
  end

  return results
end

-- Run `:edit!`, `:call setpos` and `:normal! zz` commands for grep results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_grep = function(lines, context)
  local edits = M._make_edit_grep(lines)
  M._confirm_discard_modified(context.bufnr, function()
    for _, e in ipairs(edits) do
      vim.cmd(e)
    end
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
  vim.cmd(":copen")
  vim.fn.setqflist({}, " ", {
    nr = "$",
    items = qfs,
  })
end

-- grep }

-- rg no filename {

-- Make `:call setpos` and `:normal! zz` commands for rg results (no filename).
--- @param lines string[]
--- @return string[]|nil
M._make_set_cursor_rg_no_filename = function(lines)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local results = {}
  local parsed = parsers.parse_rg_no_filename(line)
  table.insert(
    results,
    string.format("call setpos('.', [0, %d, %d])", parsed.lineno, parsed.column or 1)
  )
  table.insert(results, 'execute "normal! zz"')
  return results
end

-- Run `:call setpos` and `:normal! zz` commands on rg results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.set_cursor_rg_no_filename = function(lines, context)
  local moves = M._make_set_cursor_rg_no_filename(lines)
  if not moves then
    return
  end

  M._confirm_discard_modified(context.bufnr, function()
    for _, m in ipairs(moves) do
      vim.cmd(m)
    end
  end)
end

-- Make `:setqflist` commands for rg results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext?
--- @return {filename:string,lnum:integer,col:integer,text:string}[]|nil
M._make_setqflist_rg_no_filename = function(lines, context)
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
      local parsed = parsers.parse_rg_no_filename(line)
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
M.setqflist_rg_no_filename = function(lines, context)
  local qfs = M._make_setqflist_rg_no_filename(lines, context)
  if not qfs then
    return
  end

  vim.cmd(":copen")
  vim.fn.setqflist({}, " ", {
    nr = "$",
    items = qfs,
  })
end

-- rg no file name }

-- grep no filename {

--- @param lines string[]
--- @return string[]|nil
M._make_set_cursor_grep_no_filename = function(lines)
  if tbl.list_empty(lines) then
    return nil
  end
  local line = lines[#lines]
  if str.empty(line) then
    return nil
  end

  local results = {}
  local parsed = parsers.parse_grep_no_filename(line)
  table.insert(results, string.format("call setpos('.', [0, %d, %d])", parsed.lineno, 1))
  table.insert(results, 'execute "normal! zz"')
  return results
end

-- Run `:call setpos` commands on grep results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.set_cursor_grep_no_filename = function(lines, context)
  local moves = M._make_set_cursor_grep_no_filename(lines)
  if not moves then
    return
  end

  M._confirm_discard_modified(context.bufnr, function()
    for _, m in ipairs(moves) do
      vim.cmd(m)
    end
  end)
end

-- Make `:setqflist` commands for grep results (no filename).
--- @param lines string[]
--- @param context fzfx.PipelineContext?
--- @return {filename:string,lnum:integer,col:integer,text:string}[]|nil
M._make_setqflist_grep_no_filename = function(lines, context)
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
      local parsed = parsers.parse_grep_no_filename(line)
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
M.setqflist_grep_no_filename = function(lines, context)
  local qfs = M._make_setqflist_grep_no_filename(lines, context)
  if not qfs then
    return
  end

  vim.cmd(":copen")
  vim.fn.setqflist({}, " ", {
    nr = "$",
    items = qfs,
  })
end

-- grep no filename }

--- @param lines string[]
--- @param context fzfx.FileExplorerPipelineContext
--- @return string[]
M._make_edit_ls = function(lines, context)
  local results = {}
  for _, line in ipairs(lines) do
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
    local edit = string.format("edit! %s", parsed.filename)
    table.insert(results, edit)
  end
  return results
end

-- Run `:edit!` commands for eza/exa/ls results.
--- @param lines string[]
--- @param context fzfx.FileExplorerPipelineContext
M.edit_ls = function(lines, context)
  local edits = M._make_edit_ls(lines, context)
  M._confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.helper.actions - edit_ls| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @param lines string[]
--- @param context fzfx.GitBranchesPipelineContext
--- @return string?
M._make_git_checkout = function(lines, context)
  log.debug(string.format("|_make_git_checkout| lines:%s", vim.inspect(lines)))

  if tbl.list_not_empty(lines) then
    local line = lines[#lines]
    if str.not_empty(line) then
      local parsed = parsers.parse_git_branch(line, context)
      return string.format("!git checkout %s", parsed.local_branch)
    end
  end

  return nil
end

--- @param lines string[]
--- @param context fzfx.GitBranchesPipelineContext
M.git_checkout = function(lines, context)
  local checkout = M._make_git_checkout(lines, context) --[[@as string]]
  if str.not_empty(checkout) then
    local ok, result = pcall(vim.cmd --[[@as function]], checkout)
    assert(ok, vim.inspect(result))
  end
end

--- @param lines string[]
--- @return string?
M._make_yank_git_commit = function(lines)
  if tbl.list_not_empty(lines) then
    local line = lines[#lines]
    local parsed = parsers.parse_git_commit(line)
    return string.format("let @+ = '%s'", parsed.commit)
  end
  return nil
end

--- @param lines string[]
M.yank_git_commit = function(lines)
  local yank = M._make_yank_git_commit(lines)
  if yank then
    local ok, result = pcall(vim.cmd --[[@as function]], yank)
    assert(ok, vim.inspect(result))
  end
end

--- @param lines string[]
--- @param context fzfx.VimCommandsPipelineContext
--- @return {input:string, mode:string}?
M._make_feed_vim_command = function(lines, context)
  if tbl.list_not_empty(lines) then
    local line = lines[#lines]
    local parsed = parsers.parse_vim_command(line, context)
    return { input = string.format(":%s", parsed.command), mode = "n" }
  end
  return nil
end

--- @param lines string[]
--- @param context fzfx.VimCommandsPipelineContext
M.feed_vim_command = function(lines, context)
  local feed = M._make_feed_vim_command(lines, context) --[[@as table]]
  if tbl.tbl_not_empty(feed) then
    local ok, result = pcall(vim.fn.feedkeys, feed.input, feed.mode)
    assert(ok, vim.inspect(result))
  end
end

--- @param lines string[]
--- @param context fzfx.VimKeyMapsPipelineContext
--- @return {fn:"cmd"|"feedkeys"|nil, input:string?, mode:string?}?
M._make_feed_vim_key = function(lines, context)
  if tbl.list_not_empty(lines) then
    local line = lines[#lines]
    local parsed = parsers.parse_vim_keymap(line, context)
    if str.find(parsed.mode, "n") ~= nil then
      if str.startswith(parsed.lhs, "<plug>", { ignorecase = true }) then
        return {
          fn = "cmd",
          input = string.format('execute "normal %s"', parsed.lhs),
          mode = "n",
        }
      elseif str.startswith(parsed.lhs, "<") and num.gt(str.rfind(parsed.lhs, ">"), 0) then
        local tcodes = vim.api.nvim_replace_termcodes(parsed.lhs, true, false, true)
        return { fn = "feedkeys", input = tcodes, mode = "n" }
      else
        return { fn = "feedkeys", input = parsed.lhs, mode = "n" }
      end
    else
      log.echo(
        LogLevels.INFO,
        string.format("%s mode %s not support.", vim.inspect(parsed.mode), vim.inspect(parsed.lhs))
      )
      return nil
    end
  end
  return nil
end

--- @param lines string[]
--- @param context fzfx.VimKeyMapsPipelineContext
M.feed_vim_key = function(lines, context)
  local parsed = M._make_feed_vim_key(lines, context) --[[@as table]]
  if tbl.tbl_not_empty(parsed) and parsed.fn == "cmd" and str.not_empty(parsed.input) then
    local ok, result = pcall(vim.cmd --[[@as function]], parsed.input)
    assert(ok, vim.inspect(result))
  elseif
    tbl.tbl_not_empty(parsed)
    and parsed.fn == "feedkeys"
    and str.not_empty(parsed.input)
    and str.not_empty(parsed.mode)
  then
    local ok, result = pcall(vim.fn.feedkeys, parsed.input, parsed.mode)
    assert(ok, vim.inspect(result))
  end
end

--- @package
--- @param lines string[]
--- @return string[]
M._make_edit_git_status = function(lines)
  local edits = {}
  for i, line in ipairs(lines) do
    local parsed = parsers.parse_git_status(line)
    local edit = string.format("edit! %s", parsed.filename)
    table.insert(edits, edit)
  end
  return edits
end

-- Run 'edit' command on gits status results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_git_status = function(lines, context)
  local edits = M._make_edit_git_status(lines)
  M._confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.helper.actions - edit_git_status| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer}[]
M._make_setqflist_git_status = function(lines)
  local qfs = {}
  for _, line in ipairs(lines) do
    local parsed = parsers.parse_git_status(line)
    table.insert(qfs, { filename = parsed.filename, lnum = 1, col = 1 })
  end
  return qfs
end

--- @param lines string[]
M.setqflist_git_status = function(lines)
  local qfs = M._make_setqflist_git_status(lines --[[@as table]])
  local ok, result = pcall(vim.cmd --[[@as function]], ":copen")
  assert(ok, vim.inspect(result))
  ok, result = pcall(vim.fn.setqflist, {}, " ", {
    nr = "$",
    items = qfs,
  })
  assert(ok, vim.inspect(result))
end

--- @param lines string[]
--- @param context fzfx.VimMarksPipelineContext
--- @return string[]
M._make_edit_vim_mark = function(lines, context)
  local results = {}
  local last_parsed = nil
  for i, line in ipairs(lines) do
    if str.not_empty(line) then
      local parsed = parsers.parse_vim_mark(line, context)
      last_parsed = parsed
      if str.not_empty(parsed.filename) then
        table.insert(results, string.format("edit! %s", parsed.filename))
      end
    end
  end

  if last_parsed then
    table.insert(
      results,
      string.format(
        "call setpos('.', [%d, %d, %d])",
        context.bufnr,
        last_parsed.lineno or 1,
        (last_parsed.col or 0) + 1
      )
    )
    table.insert(results, 'execute "normal! zz"')
  end
  return results
end

--- @param lines string[]
--- @param context fzfx.VimMarksPipelineContext
M.edit_vim_mark = function(lines, context)
  local edits = M._make_edit_vim_mark(lines, context)
  M._confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|edit_vim_mark| [%d]:%s", i, vim.inspect(edit))
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @param lines string[]
--- @param context fzfx.VimMarksPipelineContext
--- @return {filename:string,lnum:integer,col:integer,text:string}[]
M._make_setqflist_vim_mark = function(lines, context)
  local qfs = {}
  for _, line in ipairs(lines) do
    local parsed = parsers.parse_vim_mark(line, context)
    local filename = parsed.filename
    if str.empty(filename) then
      local bufnr = tbl.tbl_get(context, "bufnr")
      if num.ge(bufnr, 0) and vim.api.nvim_buf_is_valid(bufnr) then
        filename = vim.api.nvim_buf_get_name(bufnr)
        filename = path.normalize(filename, { double_backslash = true, expand = true })
      end
    end
    table.insert(qfs, {
      filename = filename or "",
      lnum = parsed.lineno or 1,
      col = (parsed.col or 0) + 1,
      text = parsed.text or "",
    })
  end
  return qfs
end

--- @param lines string[]
--- @param context fzfx.VimMarksPipelineContext
M.setqflist_vim_mark = function(lines, context)
  local qfs = M._make_setqflist_vim_mark(lines, context)
  local ok, result = pcall(vim.cmd --[[@as function]], ":copen")
  assert(ok, vim.inspect(result))
  ok, result = pcall(vim.fn.setqflist, {}, " ", {
    nr = "$",
    items = qfs,
  })
  assert(ok, vim.inspect(result))
end

return M
