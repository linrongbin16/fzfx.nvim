local consts = require("fzfx.lib.constants")
local paths = require("fzfx.lib.paths")
local env = require("fzfx.lib.env")
local strs = require("fzfx.lib.strings")
local nums = require("fzfx.lib.numbers")

local M = {}

-- parse lines from fd/find, also support buffers, git files. looks like:
-- ```
-- 󰢱 bin/general/provider.lua
-- 󰢱 bin/general/previewer.lua
-- ```
--
-- remove the prepend icon and returns **full** file path. looks like:
-- ```
-- /Users/linrongbin/github/linrongbin16/fzfx.nvim/bin/general/provider.lua
-- /Users/linrongbin/github/linrongbin16/fzfx.nvim/bin/general/previewer.lua
-- ```
--
--- @param line string
--- @return {filename:string}
M.parse_find = function(line)
  local filename = nil
  if env.icon_enabled() then
    local first_icon_pos = strs.find(line, " ")
    assert(type(first_icon_pos) == "number")
    filename = line:sub(first_icon_pos + 1)
  else
    filename = line
  end
  return { filename = paths.normalize(filename, { expand = true }) }
end

-- parse lines from grep. looks like:
-- ```
-- 󰢱 bin/general/provider.lua:31:  local conf = require("fzfx.config")
-- 󰢱 bin/general/previewer.lua:57:  local colors = require("fzfx.lib.colors")
-- ```
--
-- remove the prepend icon and returns **full** file path, line number and text.
--
--- @param line string
--- @return {filename:string,lineno:integer?,text:string}
M.parse_grep = function(line)
  local filename = nil
  local lineno = nil
  local text = nil

  local first_colon_pos = strs.find(line, ":")
  assert(
    type(first_colon_pos) == "number",
    string.format("failed to parse grep lines:%s", vim.inspect(line))
  )
  filename = line:sub(1, first_colon_pos - 1)

  local second_colon_pos = strs.find(line, ":", first_colon_pos + 1)
  if nums.positive(second_colon_pos) then
    lineno = line:sub(first_colon_pos + 1, second_colon_pos - 1)
    text = line:sub(second_colon_pos + 1)
  else
    -- if failed to found the second ':', then 'lineno' is nil
    -- (it's very rare to happen, but I truly have seem such case)
    text = line:sub(first_colon_pos + 1)
  end

  filename = M.parse_find(filename)
  lineno = tonumber(lineno)
  text = text or ""

  return { filename = filename, lineno = lineno, text = text }
end

-- parse lines from rg. looks like:
-- ```
-- 󰢱 bin/general/provider.lua:31:2:  local conf = require("fzfx.config")
-- 󰢱 bin/general/previewer.lua:57:13:  local colors = require("fzfx.lib.colors")
-- ```
--
-- remove the prepend icon and returns **full** file path, line number, column number and text.
--
--- @param line string
--- @return {filename:string,lineno:integer,column:integer?,text:string}
M.parse_rg = function(line)
  local filename = nil
  local lineno = nil
  local column = nil
  local text = nil

  local first_colon_pos = strs.find(line, ":")
  assert(
    type(first_colon_pos) == "number",
    string.format("failed to parse rg lines:%s", vim.inspect(line))
  )
  filename = line:sub(1, first_colon_pos - 1)

  local second_colon_pos = strs.find(line, ":", first_colon_pos + 1)
  assert(
    type(second_colon_pos) == "number",
    string.format("failed to parse rg lines:%s", vim.inspect(line))
  )
  lineno = line:sub(first_colon_pos + 1, second_colon_pos - 1)

  local third_colon_pos = strs.find(line, ":", second_colon_pos + 1)
  if nums.positive(third_colon_pos) then
    column = line:sub(second_colon_pos + 1, third_colon_pos - 1)
    text = line:sub(third_colon_pos + 1)
  else
    -- if failed to found the third ':', then 'column' is nil
    -- (it's very rare to happen, but I truly have seem such case)
    text = line:sub(second_colon_pos + 1)
  end

  filename = M.parse_find(filename)
  lineno = tonumber(lineno)
  column = tonumber(column)
  text = text or ""

  return { filename = filename, lineno = lineno, column = column, text = text }
end

-- parse lines from `git status --short`. looks like:
-- ```
--  M lua/fzfx/helper/parsers.lua
-- ?? test.txt
-- ```
--
-- remove the prepend symbol and returns file path. looks like:
-- ```
-- lua/fzfx/helper/parsers.lua
-- test.txt
-- ```
--
--- @param line string
--- @return {filename:string}
M.parse_git_status = function(line)
  line = vim.trim(line)
  local i = 1
  while i <= #line and not strs.isspace(line:sub(i, i)) do
    i = i + 1
  end
  return { filename = paths.normalize(line:sub(i)) }
end

-- parse lines from ls/lsd/eza/exa.
--
-- The `ls -lh` looks like (file name starts from the 8th space):
--
-- (windows)
-- ```
-- total 31K
-- -rwxrwxrwx 1 somebody somegroup  150 Aug  3 21:29 .editorconfig
-- drwxrwxrwx 1 somebody somegroup    0 Oct  8 12:02 .github
-- -rwxrwxrwx 1 somebody somegroup  363 Aug 30 15:51 .gitignore
-- -rwxrwxrwx 1 somebody somegroup  124 Sep 18 23:56 .luacheckrc
-- -rwxrwxrwx 1 somebody somegroup   68 Sep 11 21:58 .luacov
-- ```
--
-- (macOS)
-- ```
-- total 184
-- -rw-r--r--   1 linrongbin  staff   1.0K Aug 28 12:39 LICENSE
-- -rw-r--r--   1 linrongbin  staff    27K Oct  8 11:37 README.md
-- drwxr-xr-x   3 linrongbin  staff    96B Aug 28 12:39 autoload
-- drwxr-xr-x   4 linrongbin  staff   128B Sep 22 10:11 bin
-- -rw-r--r--   1 linrongbin  staff   120B Sep  5 14:14 codecov.yml
-- ```
--
-- The `eza -lh` (`exa -lh`) looks like:
--
-- (windows, file name starts from the 5th space)
-- ```
-- Mode  Size Date Modified Name
-- d----    - 30 Sep 21:55  deps
-- -a---  585 22 Jul 14:26  init.vim
-- -a--- 6.4k 30 Sep 21:55  install.ps1
-- -a--- 5.3k 23 Sep 13:43  install.sh
-- ```
--
-- (macOS/linux, file name starts from the 6th space)
-- ```
-- Permissions Size User Date Modified Name
-- drwxr-xr-x     - linrongbin 28 Aug 12:39  autoload
-- drwxr-xr-x     - linrongbin 22 Sep 10:11  bin
-- .rw-r--r--   120 linrongbin  5 Sep 14:14  codecov.yml
-- .rw-r--r--  1.1k linrongbin 28 Aug 12:39  LICENSE
-- drwxr-xr-x     - linrongbin  8 Oct 09:14  lua
-- .rw-r--r--   28k linrongbin  8 Oct 11:37  README.md
-- drwxr-xr-x     - linrongbin  8 Oct 11:44  test
-- .rw-r--r--   28k linrongbin  8 Oct 12:10  test1-README.md
-- .rw-r--r--   28k linrongbin  8 Oct 12:10  test2-README.md
-- ```
--
-- The `lsd -lh --header --icon=never` looks like (file name starts from the 10th space):
--
-- ```
-- Permissions User Group  Size       Date Modified            Name
-- drwxr-xr-x  rlin staff 160 B  Wed Oct 25 16:59:44 2023 bin
-- .rw-r--r--  rlin staff  54 KB Tue Oct 31 22:29:35 2023 CHANGELOG.md
-- .rw-r--r--  rlin staff 120 B  Tue Oct 10 14:47:43 2023 codecov.yml
-- .rw-r--r--  rlin staff 1.0 KB Mon Aug 28 12:39:24 2023 LICENSE
-- drwxr-xr-x  rlin staff 128 B  Tue Oct 31 21:55:28 2023 lua
-- .rw-r--r--  rlin staff  38 KB Wed Nov  1 10:29:19 2023 README.md
-- drwxr-xr-x  rlin staff 992 B  Wed Nov  1 11:16:13 2023 test
-- ```
--
-- remove the prepend extra info and returns file path. looks like:
-- ```
-- bin
-- CHANGELOG.md
-- codecov.yml
-- LICENSE
-- lua
-- README.md
-- test
-- ```
--
--- @param start_pos integer
--- @return fun(line:string):{filename:string}
local function _make_parse_ls(start_pos)
  --- @param line string
  --- @return {filename:string}
  local function impl(line)
    local pos = 1
    for i = 1, start_pos do
      pos = strs.find(line, " ", pos) --[[@as integer]]
      assert(
        nums.positive(pos),
        string.format("failed to parse ls/eza/lsd lines:%s", vim.inspect(line))
      )
      while
        pos + 1 <= #line
        and string.byte(line, pos + 1) == string.byte(" ")
      do
        pos = pos + 1
      end
      pos = pos + 1
    end
    local result = paths.normalize(vim.trim(line:sub(pos)))

    -- remove extra single/double quotes
    if
      (strs.startswith(result, "'") and strs.endswith(result, "'"))
      or (strs.startswith(result, '"') and strs.endswith(result, '"'))
    then
      result = result:sub(2, #result - 1)
    end

    return { filename = result }
  end
  return impl
end

M.parse_ls = _make_parse_ls(8)
M.parse_eza = consts.IS_WINDOWS and _make_parse_ls(5) or _make_parse_ls(6)
M.parse_lsd = _make_parse_ls(10)

-- parse vim commands. looks like:
-- ```
-- Name              Bang|Bar|Nargs|Range|Complete         Desc/Location
-- #                 N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1121
-- !                 N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1122
-- Next              N   |Y  |N/A  |N/A  |N/A              /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/doc/index.txt:1124
-- bdelete           N   |Y  |N/A  |N/A  |N/A              "delete buffer"
-- ```
--
-- removes extra command attributes and returns the command name and **full** file path with line number, or command description.
--
--- @param line string
--- @param context fzfx.VimCommandsPipelineContext
--- @return {command:string,filename:string,lineno:integer}|{command:string,desc:string}
M.parse_vim_command = function(line, context)
  -- local log = require("fzfx.log")

  local desc_or_loc =
    vim.trim(line:sub(context.name_width + 1 + context.opts_width + 1 + 1))
  -- log.debug(
  --     "|fzfx.line_helpers - parse_vim_commands| desc_or_loc:%s",
  --     vim.inspect(desc_or_loc)
  -- )
  if
    string.len(desc_or_loc) > 0
    and not strs.startswith(desc_or_loc, '"')
    and not strs.endswith(desc_or_loc, '"')
  then
    local split_pos = strs.rfind(desc_or_loc, ":")
    local splits = {
      desc_or_loc:sub(1, split_pos - 1),
      desc_or_loc:sub(split_pos + 1),
    }
    -- log.debug(
    --     "|fzfx.line_helpers - parse_vim_commands| splits:%s",
    --     vim.inspect(splits)
    -- )
    local filename = paths.normalize(splits[1], { expand = true })
    local lineno = tonumber(splits[2])
    -- log.debug(
    --     "|fzfx.line_helpers - parse_vim_commands| filename:%s, lineno:%s",
    --     vim.inspect(filename),
    --     vim.inspect(lineno)
    -- )
    return { filename = filename, lineno = lineno }
  else
    return { desc = desc_or_loc:sub(2, #desc_or_loc - 1) }
  end
end

--- @param line string
--- @param context fzfx.VimKeyMapsPipelineContext
--- @return {filename:string?,lineno:integer?}|string
local function parse_vim_keymap(line, context)
  -- local log = require("fzfx.log")
  local rhs_or_loc =
    vim.trim(line:sub(context.key_width + 1 + context.opts_width + 1 + 1))
  -- log.debug(
  --     "|fzfx.line_helpers - parse_vim_commands| desc_or_loc:%s",
  --     vim.inspect(desc_or_loc)
  -- )
  if
    string.len(rhs_or_loc) > 0
    and not strs.startswith(rhs_or_loc, '"')
    and not strs.endswith(rhs_or_loc, '"')
  then
    local split_pos = strs.rfind(rhs_or_loc, ":")
    local splits = {
      rhs_or_loc:sub(1, split_pos - 1),
      rhs_or_loc:sub(split_pos + 1),
    }
    -- log.debug(
    --     "|fzfx.line_helpers - parse_vim_commands| splits:%s",
    --     vim.inspect(splits)
    -- )
    local filename = paths.normalize(splits[1], { expand = true })
    local lineno = tonumber(splits[2])
    -- log.debug(
    --     "|fzfx.line_helpers - parse_vim_commands| filename:%s, lineno:%s",
    --     vim.inspect(filename),
    --     vim.inspect(lineno)
    -- )
    return { filename = filename, lineno = lineno }
  else
    return rhs_or_loc:sub(2, #rhs_or_loc - 1)
  end
end

local M = {
  parse_find = parse_find,
  parse_grep = parse_grep,
  parse_rg = parse_rg,
  parse_git_status = parse_git_status,
  _make_parse_ls = _make_parse_ls,
  parse_ls = parse_ls,
  parse_eza = parse_eza,
  parse_lsd = parse_lsd,
  parse_vim_command = parse_vim_command,
  parse_vim_keymap = parse_vim_keymap,
}

return M
