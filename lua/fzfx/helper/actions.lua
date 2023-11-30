local consts = require("fzfx.lib.constants")
local paths = require("fzfx.lib.paths")
local strs = require("fzfx.lib.strings")
local tbls = require("fzfx.lib.tables")

local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels
local parsers_helper = require("fzfx.helper.parsers")
local prompts_helper = require("fzfx.helper.prompts")

local M = {}

--- @param lines string[]
--- @return nil
M.nop = function(lines)
  -- log.debug("|fzfx.helper.actions - nop| lines:%s", vim.inspect(lines))
end

--- @package
--- @param lines string[]
--- @return string[]
M._make_edit_find = function(lines)
  local results = {}
  for i, line in ipairs(lines) do
    local parsed = parsers_helper.parse_find(line)
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
  prompts_helper.confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.helper.actions - edit_find| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @package
--- @param lines string[]
--- @return string[]
M._make_edit_rg = function(lines)
  local results = {}
  for i, line in ipairs(lines) do
    local parsed = parsers_helper.parse_rg(line)
    local edit = string.format("edit! %s", parsed.filename)
    table.insert(results, edit)
    if i == #lines and parsed.lineno ~= nil then
      local column = parsed.column or 1
      local setpos =
        string.format("call setpos('.', [0, %d, %d])", parsed.lineno, column)
      table.insert(results, setpos)
    end
  end
  return results
end

-- Run 'edit' command on rg results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_rg = function(lines, context)
  local edits = M._make_edit_rg(lines)
  prompts_helper.confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.actions - edit_rg| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @package
--- @param lines string[]
--- @return string[]
M._make_edit_grep = function(lines)
  local results = {}
  for i, line in ipairs(lines) do
    local parsed = parsers_helper.parse_grep(line)
    local edit = string.format("edit! %s", parsed.filename)
    table.insert(results, edit)
    if i == #lines and parsed.lineno ~= nil then
      local column = 1
      local setpos =
        string.format("call setpos('.', [0, %d, %d])", parsed.lineno, column)
      table.insert(results, setpos)
    end
  end
  return results
end

-- Run 'edit' command on grep results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
M.edit_grep = function(lines, context)
  local edits = M._make_edit_grep(lines)
  prompts_helper.confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.actions - edit_grep| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
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
      parsed = parsers_helper.parse_lsd(line, context)
    elseif consts.HAS_EZA then
      -- eza/exa
      parsed = parsers_helper.parse_eza(line, context)
    else
      -- ls
      parsed = parsers_helper.parse_ls(line, context)
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
  prompts_helper.confirm_discard_modified(context.bufnr, function()
    for i, edit in ipairs(edits) do
      -- log.debug("|fzfx.actions - edit_ls| [%d]:[%s]", i, edit)
      local ok, result = pcall(vim.cmd --[[@as function]], edit)
      assert(ok, vim.inspect(result))
    end
  end)
end

--- @param lines string[]
--- @param context fzfx.GitBranchesPipelineContext
--- @return string?
local function _make_git_checkout(lines, context)
  log.debug(
    "|fzfx.helper.actions - _make_git_checkout_command| lines:%s",
    vim.inspect(lines)
  )

  if tbls.list_not_empty(lines) then
    local line = vim.trim(lines[#lines])
    if strs.not_empty(line) then
      local parsed = parsers_helper.parse_git_branch(line, context)
      return string.format([[!git checkout %s]], parsed.branch)
    end
  end

  return nil
end

--- @param lines string[]
--- @param context fzfx.GitBranchesPipelineContext
local function git_checkout(lines, context)
  local checkout = _make_git_checkout(lines, context) --[[@as string]]
  if strs.not_empty(checkout) then
    local ok, result = pcall(vim.cmd --[[@as function]], checkout)
    assert(ok, vim.inspect(result))
  end
end

--- @param lines string[]
--- @return string?
local function _make_yank_git_commit(lines)
  if type(lines) == "table" and #lines > 0 then
    local line = lines[#lines]
    local space_pos = strs.find(line, " ")
    if not space_pos then
      return nil
    end
    local git_commit = line:sub(1, space_pos - 1)
    return string.format("let @+ = '%s'", git_commit)
  end
  return nil
end

--- @param lines string[]
local function yank_git_commit(lines)
  local yank_command = _make_yank_git_commit(lines)
  if yank_command then
    local ok, result = pcall(vim.api.nvim_command, yank_command)
    assert(ok, vim.inspect(result))
  end
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer}[]
local function _make_setqflist_find_items(lines)
  local qflist = {}
  for _, line in ipairs(lines) do
    local filename = parsers_helper.parse_find(line)
    table.insert(qflist, { filename = filename, lnum = 1, col = 1 })
  end
  return qflist
end

--- @param lines string[]
local function setqflist_find(lines)
  local qflist = _make_setqflist_find_items(lines --[[@as table]])
  local ok, result = pcall(vim.cmd --[[@as function]], ":copen")
  assert(ok, vim.inspect(result))
  ok, result = pcall(vim.fn.setqflist, {}, " ", {
    nr = "$",
    items = qflist,
  })
  assert(ok, vim.inspect(result))
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer,text:string}[]
local function _make_setqflist_rg_items(lines)
  local qflist = {}
  for _, line in ipairs(lines) do
    local parsed = parsers_helper.parse_rg(line)
    table.insert(qflist, {
      filename = parsed.filename,
      lnum = parsed.lineno,
      col = parsed.column,
      text = parsed.text,
    })
  end
  return qflist
end

--- @param lines string[]
local function setqflist_rg(lines)
  local qflist = _make_setqflist_rg_items(lines)
  local ok, result = pcall(vim.cmd --[[@as function]], ":copen")
  assert(ok, vim.inspect(result))
  ok, result = pcall(vim.fn.setqflist, {}, " ", {
    nr = "$",
    items = qflist,
  })
  assert(ok, vim.inspect(result))
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer,text:string}[]
local function _make_setqflist_grep_items(lines)
  local qflist = {}
  for _, line in ipairs(lines) do
    local parsed = parsers_helper.parse_grep(line)
    table.insert(qflist, {
      filename = parsed.filename,
      lnum = parsed.lineno,
      col = 1,
      text = parsed.text,
    })
  end
  return qflist
end

--- @param lines string[]
local function setqflist_grep(lines)
  local qflist = _make_setqflist_grep_items(lines)
  local ok, result = pcall(vim.cmd --[[@as function]], ":copen")
  assert(ok, vim.inspect(result))
  ok, result = pcall(vim.fn.setqflist, {}, " ", {
    nr = "$",
    items = qflist,
  })
  assert(ok, vim.inspect(result))
end

--- @param lines string[]
--- @return {filename:string,lnum:integer,col:integer}[]
local function _make_setqflist_git_status_items(lines)
  local qflist = {}
  for _, line in ipairs(lines) do
    local filename = parsers_helper.parse_git_status(line)
    table.insert(qflist, { filename = filename, lnum = 1, col = 1 })
  end
  return qflist
end

--- @param lines string[]
local function setqflist_git_status(lines)
  local qflist = _make_setqflist_git_status_items(lines --[[@as table]])
  local ok, result = pcall(vim.cmd --[[@as function]], ":copen")
  assert(ok, vim.inspect(result))
  ok, result = pcall(vim.fn.setqflist, {}, " ", {
    nr = "$",
    items = qflist,
  })
  assert(ok, vim.inspect(result))
end

--- @package
--- @param lines string[]
--- @return string, string
local function _make_feed_vim_command_params(lines)
  local line = lines[#lines]
  local space_pos = strs.find(line, " ")
  local input = vim.trim(line:sub(1, space_pos - 1))
  return string.format([[:%s]], input), "n"
end

--- @param lines string[]
local function feed_vim_command(lines)
  local input, mode = _make_feed_vim_command_params(lines)
  local ok, result = pcall(vim.fn.feedkeys, input, mode)
  assert(ok, vim.inspect(result))
end

--- @package
--- @param lines string[]
--- @return "cmd"|"feedkeys"|nil, string?, string?
local function _make_feed_vim_key_params(lines)
  local line = lines[#lines]
  local space_pos = strs.find(line, " ") --[[@as integer]]
  local input = vim.trim(line:sub(1, space_pos - 1))
  local bar_pos = strs.find(line, "|", space_pos)
  local mode = vim.trim(line:sub(space_pos, bar_pos - 1))
  if strs.find(mode, "n") then
    mode = "n"
    if strs.startswith(input:lower(), "<plug>") then
      return "cmd", string.format([[execute "normal \%s"]], input), nil
    elseif
      strs.startswith(input, "<")
      and type(strs.rfind(input, ">")) == "number"
      and strs.rfind(input, ">") > 1
    then
      local tcodes = vim.api.nvim_replace_termcodes(input, true, false, true)
      return "feedkeys", tcodes, "n"
    else
      return "feedkeys", input, "n"
    end
  else
    log.echo(LogLevels.INFO, "%s mode %s not support.", mode, input)
    return nil, nil, nil
  end
end

--- @param lines string[]
local function feed_vim_key(lines)
  local feedtype, input, mode = _make_feed_vim_key_params(lines)
  if feedtype == "cmd" and type(input) == "string" then
    local ok, result = pcall(vim.cmd --[[@as function]], input)
    assert(ok, vim.inspect(result))
  elseif
    feedtype == "feedkeys"
    and type(input) == "string"
    and type(mode) == "string"
  then
    local ok, result = pcall(vim.fn.feedkeys, input, mode)
    assert(ok, vim.inspect(result))
  end
end

--- @package
--- @param lines string[]
--- @return string[]
local function _make_edit_git_status_commands(lines)
  local results = {}
  for i, line in ipairs(lines) do
    local filename = parsers_helper.parse_git_status(line)
    local edit_command = string.format("edit! %s", filename)
    table.insert(results, edit_command)
  end
  return results
end

-- Run 'edit' vim command on gits status results.
--- @param lines string[]
--- @param context fzfx.PipelineContext
local function edit_git_status(lines, context)
  local edit_commands = _make_edit_git_status_commands(lines)
  prompts_helper.confirm_discard_modified(context.bufnr, function()
    for i, edit_command in ipairs(edit_commands) do
      log.debug("|fzfx.actions - edit_git_status| [%d]:[%s]", i, edit_command)
      local ok, result = pcall(vim.cmd --[[@as function]], edit_command)
      assert(ok, vim.inspect(result))
    end
  end)
end

local M = {
  nop = nop,

  -- find/buffers/git files
  _make_edit_find_commands = _make_edit_find,
  edit = edit,
  edit_find = edit_find,
  edit_buffers = edit_buffers,
  edit_git_files = edit_git_files,
  -- deprecated
  buffer = buffer,
  bdelete = bdelete,

  -- ls/eza/lsd
  edit_ls = edit_ls,

  -- rg/grep
  _make_edit_rg_commands = _make_edit_rg,
  edit_rg = edit_rg,
  _make_edit_grep_commands = _make_edit_grep,
  edit_grep = edit_grep,

  -- git branch
  _make_git_checkout_command = _make_git_checkout,
  git_checkout = git_checkout,

  -- git commit
  _make_yank_git_commit_command = _make_yank_git_commit,
  yank_git_commit = yank_git_commit,

  -- git status
  _make_edit_git_status_commands = _make_edit_git_status_commands,
  edit_git_status = edit_git_status,

  _make_feed_vim_command_params = _make_feed_vim_command_params,
  _make_feed_vim_key_params = _make_feed_vim_key_params,
  feed_vim_command = feed_vim_command,
  feed_vim_key = feed_vim_key,

  _make_setqflist_find_items = _make_setqflist_find_items,
  _make_setqflist_rg_items = _make_setqflist_rg_items,
  _make_setqflist_grep_items = _make_setqflist_grep_items,
  _make_setqflist_git_status_items = _make_setqflist_git_status_items,
  setqflist_find = setqflist_find,
  setqflist_rg = setqflist_rg,
  setqflist_grep = setqflist_grep,
  setqflist_git_status = setqflist_git_status,
}

return M
