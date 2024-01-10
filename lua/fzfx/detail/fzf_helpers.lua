local paths = require("fzfx.commons.paths")
local termcolors = require("fzfx.commons.termcolors")
local strings = require("fzfx.commons.strings")
local jsons = require("fzfx.commons.jsons")
local fileios = require("fzfx.commons.fileios")
local tables = require("fzfx.commons.tables")

local shells = require("fzfx.lib.shells")
local log = require("fzfx.lib.log")
local yanks = require("fzfx.detail.yanks")
local config = require("fzfx.config")

-- visual select {

--- @package
--- @param mode string
--- @return string
local function _get_visual_lines(mode)
  local start_pos = vim.fn.getpos("'<") --[[@as table]]
  local end_pos = vim.fn.getpos("'>") --[[@as table]]
  local line_start = start_pos[2]
  local column_start = start_pos[3]
  local line_end = end_pos[2]
  local column_end = end_pos[3]
  line_start = math.min(line_start, line_end)
  line_end = math.max(line_start, line_end)
  column_start = math.min(column_start, column_end)
  column_end = math.max(column_start, column_end)
  -- log.debug(
  --     "|fzfx.fzf_helpers - _get_visual_lines| mode:%s, start_pos:%s, end_pos:%s",
  --     vim.inspect(mode),
  --     vim.inspect(start_pos),
  --     vim.inspect(end_pos)
  -- )
  -- log.debug(
  --     "|fzfx.fzf_helpers - _get_visual_lines| line_start:%s, line_end:%s, column_start:%s, column_end:%s",
  --     vim.inspect(line_start),
  --     vim.inspect(line_end),
  --     vim.inspect(column_start),
  --     vim.inspect(column_end)
  -- )

  local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
  if #lines == 0 then
    -- log.debug("|fzfx.fzf_helpers - _get_visual_lines| empty lines")
    return ""
  end

  -- local cursor_pos = vim.fn.getpos(".")
  -- local cursor_line = cursor_pos[2]
  -- local cursor_column = cursor_pos[3]
  -- log.debug(
  --     "|fzfx.fzf_helpers - _get_visual_lines| cursor_pos:%s, cursor_line:%s, cursor_column:%s",
  --     vim.inspect(cursor_pos),
  --     vim.inspect(cursor_line),
  --     vim.inspect(cursor_column)
  -- )
  if mode == "v" or mode == "\22" then
    local offset = string.lower(vim.o.selection) == "inclusive" and 1 or 2
    lines[#lines] = string.sub(lines[#lines], 1, column_end - offset + 1)
    lines[1] = string.sub(lines[1], column_start)
    -- log.debug(
    --     "|fzfx.fzf_helpers - _get_visual_lines| v or \\22, lines:%s",
    --     vim.inspect(lines)
    -- )
  elseif mode == "V" then
    if #lines == 1 then
      lines[1] = vim.trim(lines[1])
    end
    -- log.debug(
    --     "|fzfx.fzf_helpers - _get_visual_lines| V, lines:%s",
    --     vim.inspect(lines)
    -- )
  end
  return table.concat(lines, "\n")
end

--- @package
--- @return string
local function _visual_select()
  vim.cmd([[ execute "normal! \<ESC>" ]])
  local mode = vim.fn.visualmode()
  if mode == "v" or mode == "V" or mode == "\22" then
    return _get_visual_lines(mode)
  end
  return ""
end

-- visual select }

-- command feed {

--- @alias fzfx.LastQueryCacheObj {default_provider:string,query:string}
--- @type table<string, fzfx.LastQueryCacheObj>
local LAST_QUERY_CACHES = {}

--- @param name string
local function last_query_cache_name(name)
  return paths.join(
    config.get().cache.dir,
    string.format("_%s_last_query_cache", name)
  )
end

--- @param name string
--- @return fzfx.LastQueryCacheObj?
local function get_last_query_cache(name)
  if LAST_QUERY_CACHES[name] == nil then
    local cache_filename = last_query_cache_name(name)
    local data = fileios.readfile(cache_filename, { trim = true }) --[[@as string]]
    if strings.not_empty(data) then
      --- @type boolean, fzfx.LastQueryCacheObj?
      local ok, data_obj = pcall(jsons.decode, data)
      if
        ok
        and tables.tbl_not_empty(data_obj)
        and strings.not_empty(tables.tbl_get(data_obj, "default_provider"))
      then
        LAST_QUERY_CACHES[name] = {
          ---@diagnostic disable-next-line: need-check-nil
          default_provider = data_obj.default_provider,
          ---@diagnostic disable-next-line: need-check-nil
          query = data_obj.query or "",
        }
      end
    end
  end
  return LAST_QUERY_CACHES[name]
end

--- @param name string
--- @param query string
--- @param default_provider string
local function save_last_query_cache(name, query, default_provider)
  log.ensure(
    strings.not_empty(default_provider),
    "|save_last_query_cache| %s default_provider must not be empty:%s, query:%s",
    vim.inspect(name),
    vim.inspect(default_provider),
    vim.inspect(query)
  )
  LAST_QUERY_CACHES[name] = {
    default_provider = default_provider,
    query = query or "",
  }
end

--- @param feed_type fzfx.CommandFeed
--- @param input_args string?
--- @param pipeline_name string
--- @return {query:string, default_provider:string?}
local function get_command_feed(feed_type, input_args, pipeline_name)
  feed_type = string.lower(feed_type)
  if feed_type == "args" then
    return { query = input_args or "" }
  elseif feed_type == "visual" then
    return { query = _visual_select() }
  elseif feed_type == "cword" then
    ---@diagnostic disable-next-line: return-type-mismatch
    return { query = vim.fn.expand("<cword>") }
  elseif feed_type == "put" then
    local y = yanks.get_yank()
    return {
      query = (y ~= nil and type(y.regtext) == "string") and y.regtext or "",
    }
  elseif feed_type == "resume" then
    local last_cache_obj = get_last_query_cache(pipeline_name) --[[@as fzfx.LastQueryCacheObj]]
    return last_cache_obj or { query = "" }
  else
    log.throw("invalid command feed type: %s", vim.inspect(feed_type))
    return { query = "" }
  end
end

-- command feed }

-- fzf opts {

--- @return fzfx.FzfOpt[]
local function _generate_fzf_color_opts()
  if type(config.get().fzf_color_opts) ~= "table" then
    return {}
  end
  local fzf_colors = config.get().fzf_color_opts
  local builder = {}
  for name, opts in pairs(fzf_colors) do
    for i = 2, #opts do
      local c = termcolors.retrieve(opts[1], opts[i])
      if type(c) == "string" and string.len(c) > 0 then
        table.insert(builder, string.format("%s:%s", name:gsub("_", "%-"), c))
        break
      end
    end
  end
  -- log.debug(
  --     "|fzfx.fzf_helpers - make_fzf_color_opts| builder:%s",
  --     vim.inspect(builder)
  -- )
  return { { "--color", table.concat(builder, ",") } }
end

--- @return fzfx.FzfOpt[]
local function _generate_fzf_icon_opts()
  if type(config.get().icons) ~= "table" then
    return {}
  end
  local opts = {}
  local fzf_icons = config.get().icons
  local pointer = tables.tbl_get(fzf_icons, "fzf_pointer")
  if strings.not_empty(pointer) then
    table.insert(opts, { "--pointer", pointer })
  end
  local marker = tables.tbl_get(fzf_icons, "fzf_marker")
  if strings.not_empty(marker) then
    table.insert(opts, { "--marker", marker })
  end
  return opts
end

--- @param opts fzfx.FzfOpt[]
--- @param o fzfx.FzfOpt?
--- @return fzfx.FzfOpt[]
local function append_fzf_opt(opts, o)
  if type(o) == "string" and string.len(o) > 0 then
    table.insert(opts, o)
  elseif type(o) == "table" and #o == 2 then
    local k = o[1]
    local v = o[2]
    table.insert(opts, string.format("%s %s", k, shells.shellescape(v)))
  else
    log.throw("|append_fzf_opt| invalid fzf opt: %s", vim.inspect(o))
  end
  return opts
end

--- @param opts fzfx.FzfOpt[]
--- @return fzfx.FzfOpt[]
local function preprocess_fzf_opts(opts)
  if opts == nil or #opts == 0 then
    return {}
  end
  local result = {}
  for _, o in ipairs(opts) do
    if type(o) == "function" then
      local result_o = o()
      if result_o ~= nil then
        table.insert(result, result_o)
      end
    elseif o ~= nil then
      table.insert(result, o)
    end
  end
  return result
end

--- @param opts fzfx.FzfOpt[]
--- @return string?
local function make_fzf_opts(opts)
  if opts == nil or #opts == 0 then
    return nil
  end
  local result = {}
  for _, o in ipairs(opts) do
    append_fzf_opt(result, o)
  end
  return table.concat(result, " ")
end

--- @type string?
local CACHED_FZF_DEFAULT_OPTS = nil

--- @return string?
local function make_fzf_default_opts_impl()
  local opts = config.get().fzf_opts
  local result = {}
  if type(opts) == "table" and #opts > 0 then
    for _, o in ipairs(opts) do
      append_fzf_opt(result, o)
    end
  end
  local color_opts = _generate_fzf_color_opts()
  if type(color_opts) == "table" and #color_opts > 0 then
    for _, o in ipairs(color_opts) do
      append_fzf_opt(result, o)
    end
  end
  local icon_opts = _generate_fzf_icon_opts()
  if tables.list_not_empty(icon_opts) then
    for _, o in ipairs(icon_opts) do
      append_fzf_opt(result, o)
    end
  end
  -- log.debug(
  --     "|fzfx.fzf_helpers - make_fzf_default_opts_impl| result:%s",
  --     vim.inspect(result)
  -- )
  return table.concat(result, " ")
end

--- @param ignore_cache boolean?
--- @return string?
local function make_fzf_default_opts(ignore_cache)
  if not ignore_cache and type(CACHED_FZF_DEFAULT_OPTS) == "string" then
    return CACHED_FZF_DEFAULT_OPTS
  end
  local opts = make_fzf_default_opts_impl()
  CACHED_FZF_DEFAULT_OPTS = opts
  return opts
end

-- fzf opts }

--- @return string?
local function nvim_exec()
  local exe_list = {}
  table.insert(exe_list, config.get().env.nvim)
  table.insert(exe_list, vim.v.argv[1])
  table.insert(exe_list, vim.env.VIM)
  table.insert(exe_list, "nvim")
  for _, e in ipairs(exe_list) do
    if e ~= nil and vim.fn.executable(e) > 0 then
      return e
    end
  end
  log.throw("failed to found executable 'nvim' on path!")
  return nil
end

--- @return string?
local function fzf_exec()
  local exe_list = {}
  table.insert(exe_list, config.get().env.fzf)
  if vim.fn.exists("*fzf#exec") > 0 then
    table.insert(exe_list, vim.fn["fzf#exec"]())
  end
  table.insert(exe_list, "fzf")
  for _, e in ipairs(exe_list) do
    if e ~= nil and vim.fn.executable(e) > 0 then
      return e
    end
  end
  log.throw("failed to found executable 'fzf' on path!")
  return nil
end

--- @return string
local function make_lua_command(...)
  local nvim_path = nvim_exec()
  local lua_path =
    paths.join(vim.env._FZFX_NVIM_SELF_PATH --[[@as string]], "bin", ...)
  -- log.debug(
  --     "|fzfx.fzf_helpers - make_lua_command| luascript:%s",
  --     vim.inspect(lua_path)
  -- )
  local result =
    string.format("%s -n -u NONE --clean --headless -l %s", nvim_path, lua_path)
  -- log.debug(
  --     "|fzfx.fzf_helpers - make_lua_command| result:%s",
  --     vim.inspect(result)
  -- )
  return result
end

--- @alias fzfx.FzfOptEvent "focus"|"load"|"zero"|"change"|"start"
--- @class fzfx.FzfOptEventBinder
--- @field event fzfx.FzfOptEvent
--- @field opts string[]
local FzfOptEventBinder = {}

--- @param event fzfx.FzfOptEvent
--- @return fzfx.FzfOptEventBinder
function FzfOptEventBinder:new(event)
  local o = {
    event = event,
    opts = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param opt string
--- @return fzfx.FzfOptEventBinder
function FzfOptEventBinder:append(opt)
  log.ensure(
    strings.not_blank(opt),
    "|FzfOptEventBinder:append| opt must not blank:%s",
    vim.inspect(opt)
  )
  table.insert(self.opts, opt)
  return self
end

--- @return fzfx.FzfOpt?
function FzfOptEventBinder:build()
  if #self.opts == 0 then
    return nil
  end
  return { "--bind", self.event .. ":" .. table.concat(self.opts, "+") }
end

-- see: https://man.archlinux.org/man/fzf.1.en#preview-window=
-- --preview-window=[POSITION][,SIZE[%]][,border-BORDER_OPT][,[no]wrap][,[no]follow][,[no]cycle][,[no]hidden][,+SCROLL[OFFSETS][/DENOM]][,~HEADER_LINES][,default][,<SIZE_THRESHOLD(ALTERNATIVE_LAYOUT)]
--
--- @param opts fzfx.Options?
--- @return fzfx.Options?
local function parse_fzf_preview_window_opts(opts)
  if opts == nil then
    return nil
  end
  log.ensure(
    type(opts) == "table" or type(opts) == "string",
    "invalid fzf opts:%s",
    vim.inspect(opts)
  )
  --- @type string[]
  local split_opts = nil
  if type(opts) == "table" then
    split_opts = strings.split(opts[2], ",")
  else
    local split_opts_value = strings.split(opts, "=")
    log.ensure(
      type(split_opts_value) == "table" and #split_opts_value >= 2,
      "invalid fzf opts:%s",
      vim.inspect(opts)
    )
    local opts_value = split_opts_value[2]
    split_opts = strings.split(opts_value[2], ",")
  end
end

local function setup()
  local recalculating = false
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = { "*" },
    callback = function()
      if recalculating then
        return
      end
      recalculating = true
      make_fzf_default_opts(true)
      vim.schedule(function()
        recalculating = false
      end)
    end,
  })
end

local M = {
  _get_visual_lines = _get_visual_lines,
  _visual_select = _visual_select,
  last_query_cache_name = last_query_cache_name,
  get_last_query_cache = get_last_query_cache,
  save_last_query_cache = save_last_query_cache,
  get_command_feed = get_command_feed,
  preprocess_fzf_opts = preprocess_fzf_opts,
  _generate_fzf_color_opts = _generate_fzf_color_opts,
  _generate_fzf_icon_opts = _generate_fzf_icon_opts,
  make_fzf_opts = make_fzf_opts,
  make_fzf_default_opts = make_fzf_default_opts,
  FzfOptEventBinder = FzfOptEventBinder,
  nvim_exec = nvim_exec,
  fzf_exec = fzf_exec,
  make_lua_command = make_lua_command,
  setup = setup,
}

return M
