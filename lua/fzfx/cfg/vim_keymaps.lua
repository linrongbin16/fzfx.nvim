local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local fio = require("fzfx.commons.fio")
local path = require("fzfx.commons.path")
local uv = require("fzfx.commons.uv")

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
  name = "FzfxKeyMaps",
  desc = "Search key mappings",
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

-- Get the ":verbose map" outputs in a temp file.
-- The ':verbose map' outputs look like:
--
--```
--n  K           *@<Cmd>lua vim.lsp.buf.hover()<CR>
--                Show hover
--                Last set from Lua
--n  [w          *@<Lua 1213: ~/.config/nvim/lua/builtin/lsp.lua:60>
--                Previous diagnostic warning
--                Last set from Lua
--n  [e          *@<Lua 1211: ~/.config/nvim/lua/builtin/lsp.lua:60>
--                 Previous diagnostic error
--                 Last set from Lua
--n  [d          *@<Lua 1209: ~/.config/nvim/lua/builtin/lsp.lua:60>
--                 Previous diagnostic item
--                 Last set from Lua
--x  \ca         *@<Cmd>lua vim.lsp.buf.range_code_action()<CR>
--                 Code actions
--n  <CR>        *@<Lua 961: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>
--                 Last set from Lua
--n  <Esc>       *@<Lua 998: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>
--                 Last set from Lua
--n  .           *@<Lua 977: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>
--                 Last set from Lua
--n  <           *@<Lua 987: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>
--                 Last set from Lua
--v  <BS>        * d
--                 Last set from /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/mswin.vim line 24
--x  <Plug>NetrwBrowseXVis * :<C-U>call netrw#BrowseXVis()<CR>
--                 Last set from /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/plugin/netrwPlugin.vim line 90
--n  <Plug>NetrwBrowseX * :call netrw#BrowseX(netrw#GX(),netrw#CheckIfRemote(netrw#GX()))<CR>
--                 Last set from /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/plugin/netrwPlugin.vim line 84
--n  <C-L>       * :nohlsearch<C-R>=has('diff')?'|diffupdate':''<CR><CR><C-L>
--                 Last set from ~/.config/nvim/lua/builtin/options.vim line 50
--```
--
--- @return string[]
M._get_maps_output_in_lines = function()
  local tmpfile = vim.fn.tempname() --[[@as string]]
  vim.cmd(string.format(
    [[
    redir! > %s
    silent execute 'verbose map'
    redir END
    ]],
    tmpfile
  ))

  local lines = fio.readlines(tmpfile) --[[@as string[] ]]

  vim.schedule(function()
    if uv.fs_stat(tmpfile) then
      uv.fs_unlink(tmpfile, function() end)
    end
  end)

  return lines
end

-- Parse the output line, returns a parsed item.
--- @param line string
--- @return fzfx.VimKeyMap
M._parse_output_line = function(line)
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
      string.format(
        "|_parse_map_command_output_line| lhs:%s, filename:%s, lineno:%s",
        vim.inspect(lhs),
        vim.inspect(filename),
        vim.inspect(lineno)
      )
    )
    result.filename = path.normalize(filename, { double_backslash = true, expand = true })
    result.lineno = tonumber(lineno)
  end
  return result
end

--- @alias fzfx.VimKeyMap {lhs:string,rhs:string,mode:string,noremap:boolean,nowait:boolean,silent:boolean,desc:string?,filename:string?,lineno:integer?}

--- @param output_lines string[]
--- @return fzfx.VimKeyMap[]
M._get_keymaps = function(output_lines)
  local LAST_SET_FROM = "\tLast set from "
  local LAST_SET_FROM_LUA = "\tLast set from Lua"
  local LINE = " line "

  -- A `lhs` => parsed item map.
  local output_maps = {}
  local last_lhs = nil
  for _, line in ipairs(output_lines) do
    if str.not_blank(line) then
      if str.isalpha(line:sub(1, 1)) then
        local parsed = M._parse_output_line(line)
        output_maps[parsed.lhs] = parsed
        last_lhs = parsed.lhs
      elseif
        str.startswith(line, LAST_SET_FROM)
        and str.rfind(line, LINE)
        and not str.startswith(line, LAST_SET_FROM_LUA)
        and last_lhs
      then
        local line_pos = str.rfind(line, LINE)
        local filename = vim.trim(line:sub(string.len(LAST_SET_FROM) + 1, line_pos - 1))
        local lineno = vim.trim(line:sub(line_pos + string.len(LINE)))
        output_maps[last_lhs].filename =
          path.normalize(filename, { double_backslash = true, expand = true })
        output_maps[last_lhs].lineno = tonumber(lineno)
      end
    end
  end

  -- log.debug(
  --     "|_get_keymaps| keys_output_map1:%s",
  --     vim.inspect(keys_output_map)
  -- )
  local api_keymaps = vim.api.nvim_get_keymap("") --[[@as table]]
  -- log.debug(
  --     "|_get_keymaps| api_keys_list:%s",
  --     vim.inspect(api_keys_list)
  -- )
  local api_maps = {}
  for _, km in ipairs(api_keymaps) do
    if tbl.tbl_get(km, "lhs") ~= nil and not api_maps[km.lhs] then
      api_maps[km.lhs] = km
    end
  end

  -- Retrieve a number/boolean value (note: positive number will be treated as `true`, otherwise treated as `false`) from lua table.
  -- Or fallback to default value.
  local function get_boolean_or(t, default_value, ...)
    local v = tbl.tbl_get(t, ...)
    if type(v) == "number" then
      return v > 0
    elseif type(v) == "boolean" then
      return v
    else
      return default_value
    end
  end

  -- Retrieve a non-empty string value from lua table.
  -- Or fallback to default value.
  local function get_string_or(t, default_value, ...)
    local v = tbl.tbl_get(t, ...)
    if str.not_empty(v) then
      return v
    else
      return default_value
    end
  end

  -- Retrieve key mapping's definition
  local function get_key_def(keys, left)
    if keys[left] then
      return keys[left]
    end
    if str.startswith(left, "<Space>") or str.startswith(left, "<space>") then
      return keys[" " .. left:sub(string.len("<Space>") + 1)]
    end
    return nil
  end

  -- Enrich info of `:verbose map` outputs with api key mapping's data.
  for lhs, km in pairs(output_maps) do
    local km2 = get_key_def(api_maps, lhs)
    if km2 then
      km.rhs = get_string_or(km2, "", "rhs")
      km.mode = get_string_or(km2, "", "mode")
      km.noremap = get_boolean_or(km2, false, "noremap")
      km.nowait = get_boolean_or(km2, false, "nowait")
      km.silent = get_boolean_or(km2, false, "silent")
      km.desc = get_string_or(km2, "", "desc")
    else
      km.rhs = get_string_or(km, "", "rhs")
      km.mode = get_string_or(km, "", "mode")
      km.noremap = get_boolean_or(km.noremap, false)
      km.nowait = get_boolean_or(km.nowait, false)
      km.silent = get_boolean_or(km.silent, false)
      km.desc = get_string_or(km, "", "desc")
    end
  end

  log.debug(string.format("|_get_keymaps| keys_output_map2:%s", vim.inspect(output_maps)))
  local sorted_results = {}
  for _, o in pairs(output_maps) do
    table.insert(sorted_results, o)
  end
  table.sort(sorted_results, function(a, b)
    return a.lhs < b.lhs
  end)
  log.debug(string.format("|_get_keymaps| results:%s", vim.inspect(sorted_results)))
  return sorted_results
end

--- @param vk fzfx.VimKeyMap
--- @return string
M._render_header = function(vk)
  local mode = vk.mode or ""
  local noremap = vk.noremap and "Y" or "N"
  local nowait = vk.nowait and "Y" or "N"
  local silent = vk.silent and "Y" or "N"
  return string.format("%-4s|%-7s|%-6s|%-6s", mode, noremap, nowait, silent)
end

--- @param km fzfx.VimKeyMap
--- @return boolean
M._is_location = function(km)
  return str.not_empty(tbl.tbl_get(km, "filename")) and type(tbl.tbl_get(km, "lineno")) == "number"
end

--- @param km fzfx.VimKeyMap
--- @return boolean
M._is_description = function(km)
  return str.not_empty(tbl.tbl_get(km, "desc"))
end

--- @param km fzfx.VimKeyMap
--- @return boolean
M._is_rhs = function(km)
  return str.not_empty(tbl.tbl_get(km, "rhs"))
end

--- @param km fzfx.VimKeyMap
--- @return string?
M._render_definition_or_location = function(km)
  if M._is_location(km) then
    return string.format("%s:%d", path.reduce(km.filename), km.lineno)
  elseif M._is_rhs(km) then
    return string.format('"%s"', km.rhs)
  elseif M._is_description(km) then
    return string.format('"%s"', km.desc)
  else
    return ""
  end
end

--- @param keymaps fzfx.VimKeyMap[]
--- @param key_column_width integer
--- @param opts_column_width integer
--- @return string[]
M._render_lines = function(keymaps, key_column_width, opts_column_width)
  local KEY = "Key"
  local OPTS = "Mode|Noremap|Nowait|Silent"
  local DEF_OR_LOC = "Definition/Location"

  local results = {}
  local formatter = "%-"
    .. tostring(key_column_width)
    .. "s"
    .. " %-"
    .. tostring(opts_column_width)
    .. "s %s"
  local header = string.format(formatter, KEY, OPTS, DEF_OR_LOC)
  table.insert(results, header)
  log.debug(
    string.format(
      "|_render_vim_keymaps| formatter:%s, header:%s",
      vim.inspect(formatter),
      vim.inspect(header)
    )
  )
  for i, km in ipairs(keymaps) do
    local rendered_line =
      string.format(formatter, km.lhs, M._render_header(km), M._render_definition_or_location(km))
    log.debug(string.format("|_render_lines| line-%d:%s", i, vim.inspect(rendered_line)))
    table.insert(results, rendered_line)
  end
  return results
end

--- @param km fzfx.VimKeyMap
--- @return boolean
M._is_normal_mode = function(km)
  if str.empty(km.mode) then
    return true
  end
  return str.find(string.lower(km.mode), "n") ~= nil
end

--- @param km fzfx.VimKeyMap
--- @return boolean
M._is_visual_mode = function(km)
  if str.empty(km.mode) then
    return false
  end
  local m = string.lower(km.mode)
  return str.find(m, "v") ~= nil or str.find(m, "s") ~= nil or str.find(m, "x") ~= nil
end

--- @param km fzfx.VimKeyMap
--- @return boolean
M._is_insert_mode = function(km)
  return str.not_empty(km.mode) and str.find(string.lower(km.mode), "i") ~= nil
end

-- Normal mode, insert mode, visual mode, all modes
--- @param mode "n"|"i"|"v"|"a"
--- @return fun(query:string,context:fzfx.VimKeyMapsPipelineContext):string[]|nil
M._make_provider = function(mode)
  --- @param query string
  --- @param context fzfx.VimKeyMapsPipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local keymaps = M._get_keymaps(context.output_lines)
    local target_keymaps = {}
    if mode == "a" then
      target_keymaps = keymaps
    else
      for _, km in ipairs(keymaps) do
        if mode == "n" and M._is_normal_mode(km) then
          table.insert(target_keymaps, km)
        elseif mode == "i" and M._is_insert_mode(km) then
          table.insert(target_keymaps, km)
        elseif mode == "v" and M._is_visual_mode(km) then
          table.insert(target_keymaps, km)
        end
      end
    end
    return M._render_lines(target_keymaps, context.key_column_width, context.opts_column_width)
  end
  return impl
end

M.providers = {
  all_mode = {
    key = "ctrl-a",
    provider = M._make_provider("a"),
    provider_type = ProviderTypeEnum.DIRECT,
  },
  n_mode = {
    key = "ctrl-o",
    provider = M._make_provider("n"),
    provider_type = ProviderTypeEnum.DIRECT,
  },
  i_mode = {
    key = "ctrl-i",
    provider = M._make_provider("i"),
    provider_type = ProviderTypeEnum.DIRECT,
  },
  v_mode = {
    key = "ctrl-v",
    provider = M._make_provider("v"),
    provider_type = ProviderTypeEnum.DIRECT,
  },
}

--- @param line string
--- @param context fzfx.VimKeyMapsPipelineContext
--- @return string[]|nil
M._previewer = function(line, context)
  local parsed = parsers_helper.parse_vim_keymap(line, context)
  -- log.debug(
  --   "|fzfx.config - vim_keymaps_previewer| line:%s, context:%s, desc_or_loc:%s",
  --   vim.inspect(line),
  --   vim.inspect(context),
  --   vim.inspect(parsed)
  -- )
  if
    tbl.tbl_not_empty(parsed)
    and str.not_empty(parsed.filename)
    and type(parsed.lineno) == "number"
  then
    -- log.debug(
    --   "|fzfx.config - vim_keymaps_previewer| loc:%s",
    --   vim.inspect(parsed)
    -- )
    return previewers_helper._preview_grep_line_range(parsed.filename, parsed.lineno)
  elseif constants.HAS_ECHO and tbl.tbl_not_empty(parsed) then
    -- log.debug(
    --   "|fzfx.config - vim_keymaps_previewer| desc:%s",
    --   vim.inspect(parsed)
    -- )
    return { "echo", parsed.definition or "" }
  else
    log.echo(LogLevels.INFO, "no echo command found.")
    return nil
  end
end

M.previewers = {
  all_mode = {
    previewer = M._previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_ARRAY,
    previewer_label = labels_helper.label_vim_keymap,
  },
  n_mode = {
    previewer = M._previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_ARRAY,
    previewer_label = labels_helper.label_vim_keymap,
  },
  i_mode = {
    previewer = M._previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_ARRAY,
    previewer_label = labels_helper.label_vim_keymap,
  },
  v_mode = {
    previewer = M._previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_ARRAY,
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

-- Calculate `key` column and `opts` column width.
--- @param keys fzfx.VimKeyMap[]
--- @return integer,integer
M._calculate_columns_widths = function(keys)
  local KEY = "Key"
  local OPTS = "Mode|Noremap|Nowait|Silent"

  local max_key_width = string.len(KEY)
  local max_opts_width = string.len(OPTS)
  for _, k in ipairs(keys) do
    max_key_width = math.max(max_key_width, string.len(k.lhs))
    max_opts_width = math.max(max_opts_width, string.len(M._render_header(k)))
  end
  return max_key_width, max_opts_width
end

--- @alias fzfx.VimKeyMapsPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,output_lines:string[],key_column_width:integer,opts_column_width:integer}
--- @return fzfx.VimKeyMapsPipelineContext
M._context_maker = function()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  ctx.output_lines = M._get_maps_output_in_lines()

  local keymaps = M._get_keymaps(ctx.output_lines)
  local key_column_width, opts_column_width = M._calculate_columns_widths(keymaps)
  ctx.key_column_width = key_column_width
  ctx.opts_column_width = opts_column_width
  return ctx
end

M.other_opts = {
  context_maker = M._context_maker,
}

return M
