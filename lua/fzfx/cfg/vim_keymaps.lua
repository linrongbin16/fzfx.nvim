local tbl = require("fzfx.commons.tbl")
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

-- the ':verbose map' output looks like:
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
--- @param line string
--- @return fzfx.VimKeyMap
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
--- @return fzfx.VimKeyMap[]
M._get_vim_keymaps = function()
  local tmpfile = vim.fn.tempname()
  vim.cmd(string.format(
    [[
    redir! > %s
    silent execute 'verbose map'
    redir END
    ]],
    tmpfile
  ))

  local keys_output_map = {}
  local map_output_lines = fileio.readlines(tmpfile --[[@as string]]) --[[@as table]]

  local LAST_SET_FROM = "\tLast set from "
  local LAST_SET_FROM_LUA = "\tLast set from Lua"
  local LINE = " line "
  local last_lhs = nil
  for i = 1, #map_output_lines do
    local line = map_output_lines[i]
    if type(line) == "string" and string.len(vim.trim(line)) > 0 then
      if str.isalpha(line:sub(1, 1)) then
        local parsed = M._parse_map_command_output_line(line)
        keys_output_map[parsed.lhs] = parsed
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
        keys_output_map[last_lhs].filename =
          path.normalize(filename, { double_backslash = true, expand = true })
        keys_output_map[last_lhs].lineno = tonumber(lineno)
      end
    end
  end
  -- log.debug(
  --     "|fzfx.config - _get_vim_keymaps| keys_output_map1:%s",
  --     vim.inspect(keys_output_map)
  -- )
  local api_keys_list = vim.api.nvim_get_keymap("") --[[@as table]]
  -- log.debug(
  --     "|fzfx.config - _get_vim_keymaps| api_keys_list:%s",
  --     vim.inspect(api_keys_list)
  -- )
  local api_keys_map = {}
  for _, km in ipairs(api_keys_list) do
    if type(km) == "table" and km.lhs and not api_keys_map[km.lhs] then
      api_keys_map[km.lhs] = km
    end
  end

  local function get_boolean(v, default_value)
    if type(v) == "number" then
      return v > 0
    elseif type(v) == "boolean" then
      return v
    else
      return default_value
    end
  end
  local function get_string(v, default_value)
    if type(v) == "string" and string.len(v) > 0 then
      return v
    else
      return default_value
    end
  end

  local function get_key_def(keys, left)
    if keys[left] then
      return keys[left]
    end
    if str.startswith(left, "<Space>") or str.startswith(left, "<space>") then
      return keys[" " .. left:sub(string.len("<Space>") + 1)]
    end
    return nil
  end

  for lhs, km in pairs(keys_output_map) do
    local km2 = get_key_def(api_keys_map, lhs)
    if km2 then
      km.rhs = get_string(km2.rhs, "")
      km.mode = get_string(km2.mode, "")
      km.noremap = get_boolean(km2.noremap, false)
      km.nowait = get_boolean(km2.nowait, false)
      km.silent = get_boolean(km2.silent, false)
      km.desc = get_string(km2.desc, "")
    else
      km.rhs = get_string(km.rhs, "")
      km.mode = get_string(km.mode, "")
      km.noremap = get_boolean(km.noremap, false)
      km.nowait = get_boolean(km.nowait, false)
      km.silent = get_boolean(km.silent, false)
      km.desc = get_string(km.desc, "")
    end
  end
  log.debug(string.format("|_get_vim_keymaps| keys_output_map2:%s", vim.inspect(keys_output_map)))
  local results = {}
  for _, r in pairs(keys_output_map) do
    table.insert(results, r)
  end
  table.sort(results, function(a, b)
    return a.lhs < b.lhs
  end)
  log.debug(string.format("|_get_vim_keymaps| results:%s", vim.inspect(results)))
  return results
end

--- @param vk fzfx.VimKeyMap
--- @return string
M._render_vim_keymaps_column_opts = function(vk)
  local mode = vk.mode or ""
  local noremap = vk.noremap and "Y" or "N"
  local nowait = vk.nowait and "Y" or "N"
  local silent = vk.silent and "Y" or "N"
  return string.format("%-4s|%-7s|%-6s|%-6s", mode, noremap, nowait, silent)
end

--- @param keymaps fzfx.VimKeyMap[]
--- @param key_width integer
--- @param opts_width integer
--- @return string[]
M._render_vim_keymaps = function(keymaps, key_width, opts_width)
  --- @param r fzfx.VimKeyMap
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
    string.format(
      "|_render_vim_keymaps| formatter:%s, header:%s",
      vim.inspect(formatter),
      vim.inspect(header)
    )
  )
  for i, c in ipairs(keymaps) do
    local rendered =
      string.format(formatter, c.lhs, M._render_vim_keymaps_column_opts(c), rendered_def_or_loc(c))
    log.debug(string.format("|_render_vim_keymaps| rendered[%d]:%s", i, vim.inspect(rendered)))
    table.insert(results, rendered)
  end
  return results
end

--- @param mode "n"|"i"|"v"|"all"
--- @return fun(query:string,context:fzfx.VimKeyMapsPipelineContext):string[]|nil
M._make_vim_keymaps_provider = function(mode)
  --- @param query string
  --- @param context fzfx.VimKeyMapsPipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local keys = M._get_vim_keymaps()
    local filtered_keys = {}
    if mode == "all" then
      filtered_keys = keys
    else
      for _, k in ipairs(keys) do
        if k.mode == mode then
          table.insert(filtered_keys, k)
        elseif
          mode == "v"
          and (str.find(k.mode, "v") or str.find(k.mode, "s") or str.find(k.mode, "x"))
        then
          table.insert(filtered_keys, k)
        elseif mode == "n" and str.find(k.mode, "n") then
          table.insert(filtered_keys, k)
        elseif mode == "i" and str.find(k.mode, "i") then
          table.insert(filtered_keys, k)
        elseif mode == "n" and string.len(k.mode) == 0 then
          table.insert(filtered_keys, k)
        end
      end
    end
    return M._render_vim_keymaps(filtered_keys, context.key_width, context.opts_width)
  end
  return impl
end

M.providers = {
  all_mode = {
    key = "ctrl-a",
    provider = M._make_vim_keymaps_provider("all"),
    provider_type = ProviderTypeEnum.LIST,
  },
  n_mode = {
    key = "ctrl-o",
    provider = M._make_vim_keymaps_provider("n"),
    provider_type = ProviderTypeEnum.LIST,
  },
  i_mode = {
    key = "ctrl-i",
    provider = M._make_vim_keymaps_provider("i"),
    provider_type = ProviderTypeEnum.LIST,
  },
  v_mode = {
    key = "ctrl-v",
    provider = M._make_vim_keymaps_provider("v"),
    provider_type = ProviderTypeEnum.LIST,
  },
}

--- @param line string
--- @param context fzfx.VimKeyMapsPipelineContext
--- @return string[]|nil
M._vim_keymaps_previewer = function(line, context)
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
    return previewers_helper.preview_files_with_line_range(parsed.filename, parsed.lineno)
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
    previewer = M._vim_keymaps_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_keymap,
  },
  n_mode = {
    previewer = M._vim_keymaps_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_keymap,
  },
  i_mode = {
    previewer = M._vim_keymaps_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_keymap,
  },
  v_mode = {
    previewer = M._vim_keymaps_previewer,
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

--- @param keys fzfx.VimKeyMap[]
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
    string.format(
      "|_render_vim_keymaps_columns_status| lhs:%s, opts:%s",
      vim.inspect(max_key),
      vim.inspect(max_opts)
    )
  )
  return max_key, max_opts
end

--- @alias fzfx.VimKeyMapsPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,key_width:integer,opts_width:integer}
--- @return fzfx.VimKeyMapsPipelineContext
M._vim_keymaps_context_maker = function()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  local keys = M._get_vim_keymaps()
  local key_width, opts_width = M._render_vim_keymaps_columns_status(keys)
  ctx.key_width = key_width
  ctx.opts_width = opts_width
  return ctx
end

M.other_opts = {
  context_maker = M._vim_keymaps_context_maker,
}

return M
