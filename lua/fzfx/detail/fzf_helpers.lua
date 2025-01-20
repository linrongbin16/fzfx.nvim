local str = require("fzfx.commons.str")
local tbl = require("fzfx.commons.tbl")
local path = require("fzfx.commons.path")
local fio = require("fzfx.commons.fio")
local color_hl = require("fzfx.commons.color.hl")

local shells = require("fzfx.lib.shells")
local constants = require("fzfx.lib.constants")
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
  return path.join(config.get().cache.dir, string.format("_%s_last_query_cache", name))
end

--- @param name string
--- @return fzfx.LastQueryCacheObj?
local function get_last_query_cache(name)
  if LAST_QUERY_CACHES[name] == nil then
    local cache_filename = last_query_cache_name(name)
    local data = fio.readfile(cache_filename, { trim = true }) --[[@as string]]
    if str.not_empty(data) then
      --- @type boolean, fzfx.LastQueryCacheObj?
      local ok, data_obj = pcall(vim.json.decode, data)
      if
        ok
        and tbl.tbl_not_empty(data_obj)
        and str.not_empty(tbl.tbl_get(data_obj, "default_provider"))
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
    str.not_empty(default_provider),
    string.format(
      "|save_last_query_cache| %s default_provider must not be empty:%s, query:%s",
      vim.inspect(name),
      vim.inspect(default_provider),
      vim.inspect(query)
    )
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
    log.throw("invalid command feed type: " .. vim.inspect(feed_type))
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
    local attr = opts[1]
    for i = 2, #opts do
      local o = opts[i]
      if str.startswith(o, "#") then
        log.ensure(
          string.len(o) == 7,
          string.format(
            "invalid fzf_color_opts: RGB color codes must have 6 digits after '#': %s = %s",
            vim.inspect(name),
            vim.inspect(opts)
          )
        )
        table.insert(builder, string.format("%s:%s", name:gsub("_", "%-"), opts[i]))
        break
      else
        local codes = color_hl.get_hl(opts[i])
        if type(tbl.tbl_get(codes, attr)) == "number" then
          table.insert(builder, string.format("%s:#%06x", name:gsub("_", "%-"), codes[attr]))
          break
        end
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
  local pointer = tbl.tbl_get(fzf_icons, "fzf_pointer")
  if str.not_empty(pointer) then
    table.insert(opts, { "--pointer", pointer })
  end
  local marker = tbl.tbl_get(fzf_icons, "fzf_marker")
  if str.not_empty(marker) then
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
    table.insert(opts, string.format("%s %s", k, shells.escape(v)))
  else
    log.throw(string.format("|append_fzf_opt| invalid fzf opt: %s", vim.inspect(o)))
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

local function make_fzf_color_and_icon_opts()
  local result = {}
  local color_opts = _generate_fzf_color_opts()
  if type(color_opts) == "table" and #color_opts > 0 then
    for _, o in ipairs(color_opts) do
      append_fzf_opt(result, o)
    end
  end
  local icon_opts = _generate_fzf_icon_opts()
  if tbl.list_not_empty(icon_opts) then
    for _, o in ipairs(icon_opts) do
      append_fzf_opt(result, o)
    end
  end
  return table.concat(result, " ")
end

local cached_fzf_default_opts = nil

--- @return string?
local function make_fzf_default_opts()
  if str.empty(cached_fzf_default_opts) then
    cached_fzf_default_opts = make_fzf_color_and_icon_opts()
  end
  return cached_fzf_default_opts
end

--- @return string?
local function update_fzf_default_opts()
  cached_fzf_default_opts = make_fzf_color_and_icon_opts()
end

-- fzf opts }

--- @return string?
local function nvim_exec()
  local exe_list = {}
  table.insert(exe_list, "nvim")
  table.insert(exe_list, vim.v.argv[1])
  table.insert(exe_list, vim.env.VIM)
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
  table.insert(exe_list, "fzf")
  if vim.fn.exists("*fzf#exec") > 0 then
    table.insert(exe_list, vim.fn["fzf#exec"]())
  end
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
  local lua_path = path.join(vim.env._FZFX_NVIM_SELF_PATH --[[@as string]], "bin", ...)
  -- log.debug(
  --     "|fzfx.fzf_helpers - make_lua_command| luascript:%s",
  --     vim.inspect(lua_path)
  -- )
  local result = string.format("%s -n -u NONE -i NONE --headless -l %s", nvim_path, lua_path)
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
    str.not_blank(opt),
    string.format("|FzfOptEventBinder:append| opt must not blank:%s", vim.inspect(opt))
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

local function setup()
  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      -- log.debug("|setup| ColorScheme event:%s", vim.inspect(event))
      vim.schedule(function()
        update_fzf_default_opts()
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
  update_fzf_default_opts = update_fzf_default_opts,
  FzfOptEventBinder = FzfOptEventBinder,
  nvim_exec = nvim_exec,
  fzf_exec = fzf_exec,
  make_lua_command = make_lua_command,
  setup = setup,
}

return M
