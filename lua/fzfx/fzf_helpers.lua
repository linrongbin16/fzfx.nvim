local paths = require("fzfx.lib.paths")
local colors = require("fzfx.lib.colors")
local jsons = require("fzfx.lib.jsons")
local fs = require("fzfx.lib.filesystems")
local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")

local log = require("fzfx.log")
local conf = require("fzfx.config")
local yank_history = require("fzfx.yank_history")

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

--- @param name string
local function make_last_query_cache(name)
  return paths.join(
    conf.get_config().cache.dir,
    string.format("_%s_last_query_cache", name)
  )
end

--- @param feed_type CommandFeed
--- @param input_args string?
--- @param pipeline_name string
--- @return string, string?
local function get_command_feed(feed_type, input_args, pipeline_name)
  feed_type = string.lower(feed_type)
  if feed_type == "args" then
    return input_args or "", nil
  elseif feed_type == "visual" then
    return _visual_select()
  elseif feed_type == "cword" then
    ---@diagnostic disable-next-line: return-type-mismatch
    return vim.fn.expand("<cword>"), nil
  elseif feed_type == "put" then
    local y = yank_history.get_yank()
    return (y ~= nil and type(y.regtext) == "string") and y.regtext or "", nil
  elseif feed_type == "resume" then
    local cache = make_last_query_cache(pipeline_name)
    local data = fs.readfile(cache)
    -- log.debug(
    --     "|fzfx.fzf_helpers - get_command_feed| pipeline %s cache:%s",
    --     vim.inspect(pipeline_name),
    --     vim.inspect(data)
    -- )
    if
      type(data) ~= "string"
      or string.len(data) == 0
      or not strs.startswith(data, "{")
      or not strs.endswith(data, "}")
    then
      return "", nil
    end
    --- @alias LastQueryCacheObj {default_provider:string,query:string}
    local ok, obj = pcall(jsons.decode, data) --[[@as LastQueryCacheObj]]
    if ok and type(obj) == "table" then
      return obj.query or "", obj.default_provider
    else
      return "", nil
    end
  else
    log.throw(
      "|fzfx.fzf_helpers - get_command_feed| invalid command feed type! %s",
      vim.inspect(feed_type)
    )
    return ""
  end
end

-- fzf opts {

--- @return FzfOpt[]
local function _generate_fzf_color_opts()
  if type(conf.get_config().fzf_color_opts) ~= "table" then
    return {}
  end
  local fzf_colors = conf.get_config().fzf_color_opts
  local builder = {}
  for name, opts in pairs(fzf_colors) do
    for i = 2, #opts do
      local c = colors.hlcode(opts[1], opts[i])
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

--- @return FzfOpt[]
local function _generate_fzf_icon_opts()
  if type(conf.get_config().icons) ~= "table" then
    return {}
  end
  local icon_configs = conf.get_config().icons
  return {
    { "--pointer", icon_configs.fzf_pointer },
    { "--marker", icon_configs.fzf_marker },
  }
end

--- @param opts FzfOpt[]
--- @param o FzfOpt?
--- @return FzfOpt[]
local function append_fzf_opt(opts, o)
  if type(o) == "string" and string.len(o) > 0 then
    table.insert(opts, o)
  elseif type(o) == "table" and #o == 2 then
    local k = o[1]
    local v = o[2]
    table.insert(opts, string.format("%s %s", k, nvims.shellescape(v)))
  else
    log.throw(
      "|fzfx.fzf_helpers - append_fzf_opt| invalid fzf opt: %s",
      vim.inspect(o)
    )
  end
  return opts
end

--- @param opts FzfOpt[]
--- @return FzfOpt[]
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

--- @param opts FzfOpt[]
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
  local opts = conf.get_config().fzf_opts
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
  if type(icon_opts) == "table" and #icon_opts > 0 then
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
  table.insert(exe_list, conf.get_config().env.nvim)
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
  table.insert(exe_list, conf.get_config().env.fzf)
  table.insert(exe_list, vim.fn["fzf#exec"]())
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
    strs.not_blank(opt),
    "|fzfx.fzf_helpers - FzfOptEventBinder:append| opt must not blank:%s",
    vim.inspect(opt)
  )
  table.insert(self.opts, opt)
  return self
end

--- @return FzfOpt?
function FzfOptEventBinder:build()
  if #self.opts == 0 then
    return nil
  end
  return { "--bind", self.event .. ":" .. table.concat(self.opts, "+") }
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
  make_last_query_cache = make_last_query_cache,
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
