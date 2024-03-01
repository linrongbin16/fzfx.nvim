local tables = require("fzfx.commons.tables")
local strings = require("fzfx.commons.strings")
local numbers = require("fzfx.commons.numbers")

local consts = require("fzfx.lib.constants")

local parsers = require("fzfx.helper.parsers")
local prompts = require("fzfx.helper.prompts")

local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local M = {}

M.nop = function() end

--- @package
--- @param lines string[]
--- @return string[]
M._make_edit_find = function(lines)
  local results = {}
  for i, line in ipairs(lines) do
    local parsed = parsers.parse_find(line)
    local edit = string.format("edit! %s", parsed.filename)
    table.insert(results, edit)
  end
  return results
end

-- Run 'edit' commands on fd/find results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_find = function(lines, context)
  local edits = M._make_edit_find(lines)
  prompts.confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.helper.actions - edit_find| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer}[]
M._make_setqflist_find = function(lines)
  local qfs = {}
  for _, line in ipairs(lines) do
    local parsed = parsers.parse_find(line)
    table.insert(qfs, { filename = parsed.filename, lnum = 1, col = 1 })
  end
  return qfs
end

--- @param lines string[]
M.setqflist_find = function(lines)
  local qfs = M._make_setqflist_find(lines --[[@as table]])
  local ok, result = pcall(vim.cmd --[[@as function]], ":copen")
  assert(ok, vim.inspect(result))
  ok, result = pcall(vim.fn.setqflist, {}, " ", {
    nr = "$",
    items = qfs,
  })
  assert(ok, vim.inspect(result))
end

--- @package
--- @param lines string[]
--- @return string[]
M._make_edit_rg = function(lines)
  local results = {}
  for i, line in ipairs(lines) do
    local parsed = parsers.parse_rg(line)
    local edit = string.format("edit! %s", parsed.filename)
    table.insert(results, edit)
    if i == #lines and parsed.lineno ~= nil then
      local column = parsed.column or 1
      local setpos = string.format("call setpos('.', [0, %d, %d])", parsed.lineno, column)
      table.insert(results, setpos)
      local center_cursor = string.format('execute "normal! zz"')
      table.insert(results, center_cursor)
    end
  end
  return results
end

-- Run 'edit' command on rg results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_rg = function(lines, context)
  local edits = M._make_edit_rg(lines)
  prompts.confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.helper.actions - edit_rg| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
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
  local ok, result = pcall(vim.cmd --[[@as function]], ":copen")
  assert(ok, vim.inspect(result))
  ok, result = pcall(vim.fn.setqflist, {}, " ", {
    nr = "$",
    items = qfs,
  })
  assert(ok, vim.inspect(result))
end

--- @package
--- @param lines string[]
--- @return string[]
M._make_edit_grep = function(lines)
  local results = {}
  for i, line in ipairs(lines) do
    local parsed = parsers.parse_grep(line)
    local edit = string.format("edit! %s", parsed.filename)
    table.insert(results, edit)
    if i == #lines and parsed.lineno ~= nil then
      local column = 1
      local setpos = string.format("call setpos('.', [0, %d, %d])", parsed.lineno, column)
      table.insert(results, setpos)
      local center_cursor = string.format('execute "normal! zz"')
      table.insert(results, center_cursor)
    end
  end
  return results
end

-- Run 'edit' command on grep results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_grep = function(lines, context)
  local edits = M._make_edit_grep(lines)
  prompts.confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.helper.actions - edit_grep| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @package
--- @param lines string[]
--- @param context fzfx.PipelineContext
--- @return string[]|nil
M._make_set_cursor_rg_no_filename = function(lines, context)
  local results = {}
  if #lines == 0 then
    return nil
  end
  local winnr = tables.tbl_get(context, "winnr")
  if not numbers.ge(winnr, 0) or not vim.api.nvim_win_is_valid(winnr) then
    log.echo(LogLevels.INFO, "invalid window(%s).", vim.inspect(winnr))
    return nil
  end
  local line = lines[#lines]
  local parsed = parsers.parse_rg(line)
  tables.insert(results, string.format("lua vim.api.nvim_set_current_win(%d)", winnr))
  if numbers.ge(parsed.lineno, 0) then
    tables.insert(
      results,
      string.format(
        "lua vim.api.nvim_win_set_cursor(%d, {%d, %d})",
        winnr,
        parsers.lineno,
        parsed.column or 1
      )
    )
    table.insert(results, 'execute "normal! zz"')
  end
  return results
end

-- Run 'set_cursor' command on rg results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.set_cursor_rg_no_filename = function(lines, context)
  local moves = M._make_set_cursor_rg_no_filename(lines, context)
  if not moves then
    return
  end
  prompts.confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(moves) do
      -- log.debug("|fzfx.helper.actions - edit_rg_no_filename| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @package
--- @param lines string[]
--- @return string[]
M._make_edit_grep_no_filename = function(lines)
  local results = {}
  for i, line in ipairs(lines) do
    local parsed = parsers.parse_grep(line)
    local edit = string.format("edit! %s", parsed.filename)
    table.insert(results, edit)
    if i == #lines and parsed.lineno ~= nil then
      local column = 1
      local setpos = string.format("call setpos('.', [0, %d, %d])", parsed.lineno, column)
      table.insert(results, setpos)
      local center_cursor = string.format('execute "normal! zz"')
      table.insert(results, center_cursor)
    end
  end
  return results
end

-- Run 'edit' command on grep results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_grep_no_filename = function(lines, context)
  local edits = M._make_edit_grep_no_filename(lines)
  prompts.confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.helper.actions - edit_grep_no_filename| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer,text:string}[]
M._make_setqflist_grep = function(lines)
  local qfs = {}
  for _, line in ipairs(lines) do
    local parsed = parsers.parse_grep(line)
    table.insert(qfs, {
      filename = parsed.filename,
      lnum = parsed.lineno,
      col = 1,
      text = parsed.text,
    })
  end
  return qfs
end

--- @param lines string[]
M.setqflist_grep = function(lines)
  local qfs = M._make_setqflist_grep(lines)
  local ok, result = pcall(vim.cmd --[[@as function]], ":copen")
  assert(ok, vim.inspect(result))
  ok, result = pcall(vim.fn.setqflist, {}, " ", {
    nr = "$",
    items = qfs,
  })
  assert(ok, vim.inspect(result))
end

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

-- Run 'edit' command on eza/exa/ls results.
--- @param lines string[]
--- @param context fzfx.FileExplorerPipelineContext
M.edit_ls = function(lines, context)
  local edits = M._make_edit_ls(lines, context)
  prompts.confirm_discard_modified(context.bufnr, function()
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
  log.debug("|_make_git_checkout| lines:%s", vim.inspect(lines))

  if tables.list_not_empty(lines) then
    local line = lines[#lines]
    if strings.not_empty(line) then
      local parsed = parsers.parse_git_branch(line, context)
      return string.format([[!git checkout %s]], parsed.local_branch)
    end
  end

  return nil
end

--- @param lines string[]
--- @param context fzfx.GitBranchesPipelineContext
M.git_checkout = function(lines, context)
  local checkout = M._make_git_checkout(lines, context) --[[@as string]]
  if strings.not_empty(checkout) then
    local ok, result = pcall(vim.cmd --[[@as function]], checkout)
    assert(ok, vim.inspect(result))
  end
end

--- @param lines string[]
--- @return string?
M._make_yank_git_commit = function(lines)
  if tables.list_not_empty(lines) then
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
    local ok, result = pcall(vim.api.nvim_command, yank)
    assert(ok, vim.inspect(result))
  end
end

--- @package
--- @param lines string[]
--- @param context fzfx.VimCommandsPipelineContext
--- @return {input:string, mode:string}?
M._make_feed_vim_command = function(lines, context)
  if tables.list_not_empty(lines) then
    local line = lines[#lines]
    local parsed = parsers.parse_vim_command(line, context)
    return { input = string.format([[:%s]], parsed.command), mode = "n" }
  end
  return nil
end

--- @param lines string[]
--- @param context fzfx.VimCommandsPipelineContext
M.feed_vim_command = function(lines, context)
  local feed = M._make_feed_vim_command(lines, context) --[[@as table]]
  if tables.tbl_not_empty(feed) then
    local ok, result = pcall(vim.fn.feedkeys, feed.input, feed.mode)
    assert(ok, vim.inspect(result))
  end
end

--- @package
--- @param lines string[]
--- @param context fzfx.VimKeyMapsPipelineContext
--- @return {fn:"cmd"|"feedkeys"|nil, input:string?, mode:string?}?
M._make_feed_vim_key = function(lines, context)
  if tables.list_not_empty(lines) then
    local line = lines[#lines]
    local parsed = parsers.parse_vim_keymap(line, context)
    if strings.find(parsed.mode, "n") ~= nil then
      if strings.startswith(parsed.lhs, "<plug>", { ignorecase = true }) then
        return {
          fn = "cmd",
          input = string.format([[execute "normal \%s"]], parsed.lhs),
          mode = "n",
        }
      elseif
        strings.startswith(parsed.lhs, "<")
        and numbers.gt(strings.rfind(parsed.lhs, ">"), 0)
      then
        local tcodes = vim.api.nvim_replace_termcodes(parsed.lhs, true, false, true)
        return { fn = "feedkeys", input = tcodes, mode = "n" }
      else
        return { fn = "feedkeys", input = parsed.lhs, mode = "n" }
      end
    else
      log.echo(
        LogLevels.INFO,
        "%s mode %s not support.",
        vim.inspect(parsed.mode),
        vim.inspect(parsed.lhs)
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
  if tables.tbl_not_empty(parsed) and parsed.fn == "cmd" and strings.not_empty(parsed.input) then
    local ok, result = pcall(vim.cmd --[[@as function]], parsed.input)
    assert(ok, vim.inspect(result))
  elseif
    tables.tbl_not_empty(parsed)
    and parsed.fn == "feedkeys"
    and strings.not_empty(parsed.input)
    and strings.not_empty(parsed.mode)
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
  prompts.confirm_discard_modified(context.bufnr, function()
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

return M
