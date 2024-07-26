local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")
local spawn = require("fzfx.commons.spawn")

local consts = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")

local M = {}

--- @return string
M.get_color_name = function()
  return vim.g.colors_name or "default"
end

-- theme dir {

-- Create directory if it doesn't exist.
-- Returns false if it's already existed, returns true if it's created.
--- @param dir string
--- @return boolean
M._create_dir_if_not_exist = function(dir)
  if path.isdir(dir) then
    return false
  end
  vim.fn.mkdir(dir, "p")
  return true
end

-- The cached `bat --config-dir` result.
--- @type string?
local CACHED_THEME_DIR = nil

-- Returns cached theme dir.
-- Returns `nil` if the `async_get_theme_dir` is not been initialized.
--- @return string?
M.get_theme_dir = function()
  if str.not_empty(CACHED_THEME_DIR) then
    M._create_dir_if_not_exist(CACHED_THEME_DIR --[[@as string]])
  end
  return CACHED_THEME_DIR
end

-- Async get bat theme directory, and invoke `callback` function to consume the value.
-- This function will only be called when setup this plugin. Then you can just use `get_theme_dir` to get the cached result.
--- @param callback fun(theme_dir:string?):nil
M.async_get_theme_dir = function(callback)
  log.ensure(consts.HAS_BAT, string.format("|async_get_theme_dir| cannot find %s", consts.BAT))
  log.ensure(
    type(callback) == "function",
    string.format("|async_get_theme_dir| callback(%s) is not a function", vim.inspect(callback))
  )

  local theme_dir = ""
  spawn.run({ consts.BAT, "--config-dir" }, {
    on_stdout = function(line)
      theme_dir = theme_dir .. line
    end,
    on_stderr = function() end,
  }, function()
    CACHED_THEME_DIR = path.join(theme_dir, "themes")
    vim.schedule(function()
      M._create_dir_if_not_exist(CACHED_THEME_DIR)
      callback(CACHED_THEME_DIR)
    end)
  end)
end

-- theme dir }

-- theme name {

-- Vim colorscheme name => bat theme name
--- @type table<string, string>
local THEME_NAMES_MAP = {}

-- Set first character to upper case for all the strings in `names`.
--- @param names string[]
--- @return string[]
M._upper_first = function(names)
  assert(
    type(names) == "table",
    string.format("|_upper_firsts| invalid names:%s", vim.inspect(names))
  )
  local new_names = {}
  for i, n in ipairs(names) do
    assert(
      type(n) == "string" and string.len(n) > 0,
      string.format("|_upper_firsts| invalid name(%d):%s", vim.inspect(i), vim.inspect(n))
    )
    local new_name = string.sub(n, 1, 1):upper() .. (string.len(n) > 1 and string.sub(n, 2) or "")
    table.insert(new_names, new_name)
  end
  return new_names
end

--- @param s string
--- @param delimiter string
--- @return string
M._normalize_by = function(s, delimiter)
  local splits
  if str.find(s, delimiter) then
    splits = str.split(s, delimiter, { plain = true, trimempty = true })
  else
    splits = { s }
  end
  splits = M._upper_first(splits)
  return table.concat(splits, "")
end

-- Convert vim colorscheme name to bat theme (TextMate) name.
--- @param colorname string
--- @return string
M.get_theme_name = function(colorname)
  assert(type(colorname) == "string" and string.len(colorname) > 0)
  if THEME_NAMES_MAP[colorname] == nil then
    local result = colorname
    result = M._normalize_by(result, "-")
    result = M._normalize_by(result, "+")
    result = M._normalize_by(result, "_")
    result = M._normalize_by(result, ".")
    result = M._normalize_by(result, " ")
    THEME_NAMES_MAP[colorname] = "FzfxNvim" .. result
  end

  return THEME_NAMES_MAP[colorname]
end

-- Convert vim colorscheme name to bat theme's config file name.
--- @param colorname string
--- @return string?
M.get_theme_config_filename = function(colorname)
  local theme_dir = M.get_theme_dir()
  if str.empty(theme_dir) then
    return nil
  end

  local theme_name = M.get_theme_name(colorname)
  log.ensure(
    str.not_empty(theme_name),
    "|get_theme_config_file| failed to get bat theme name from nvim colorscheme name:"
      .. vim.inspect(colorname)
  )
  -- log.debug(
  --   "|get_theme_config_file| theme_dir:%s, theme_name:%s",
  --   vim.inspect(theme_dir),
  --   vim.inspect(theme_name)
  -- )
  return path.join(theme_dir, theme_name .. ".tmTheme")
end

-- theme name }

return M
