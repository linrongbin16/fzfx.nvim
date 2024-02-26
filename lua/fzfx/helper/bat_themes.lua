local paths = require("fzfx.commons.paths")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")
local strings = require("fzfx.commons.strings")

local constants = require("fzfx.lib.constants")
local env = require("fzfx.lib.env")
local log = require("fzfx.lib.log")

local M = {}

--- @return string
M._theme_dir_cache = function()
  return paths.join(env.cache_dir(), "_last_bat_themes_dir_cache")
end

--- @type string?
local CACHED_THEME_DIR = nil
local theme_dir_cached_reader = nil

--- @return string?
M._cached_theme_dir = function()
  if theme_dir_cached_reader == nil then
    theme_dir_cached_reader = fileios.CachedFileReader:open(M._theme_dir_cache())
  end
  return theme_dir_cached_reader:read({ trim = true })
end

--- @param theme_dir string
M._create_theme_dir = function(theme_dir)
  if paths.isdir(theme_dir) then
    return
  end
  spawn
    .run({ "mkdir", "-p", theme_dir }, {
      on_stdout = function() end,
      on_stderr = function() end,
    })
    :wait()
end

--- @return string
M.get_theme_dir = function()
  local cached_result = M._cached_theme_dir() --[[@as string]]
  -- log.debug("|get_theme_dir| cached_result:%s", vim.inspect(cached_result))

  if strings.empty(cached_result) then
    log.ensure(constants.HAS_BAT, "|get_theme_dir| cannot find 'bat' executable")

    local config_dir = ""
    spawn
      .run({ constants.BAT, "--config-dir" }, {
        on_stdout = function(line)
          config_dir = config_dir .. line
        end,
        on_stderr = function() end,
      })
      :wait()
    -- log.debug("|get_theme_dir| config_dir:%s", vim.inspect(config_dir))
    local theme_dir = paths.join(config_dir, "themes")
    M._create_theme_dir(theme_dir)
    fileios.writefile(M._theme_dir_cache(), theme_dir)

    return theme_dir
  end

  M._create_theme_dir(cached_result)
  return cached_result
end

-- Vim colorscheme name => bat theme name
--- @type table<string, string>
local THEME_NAMES_MAP = {}

--- @param names string[]
--- @return string[]
M._upper_first = function(names)
  assert(
    type(names) == "table" and #names > 0,
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
  local splits = strings.find(s, delimiter) and strings.split(s, delimiter, { trimempty = true })
    or { s }
  splits = M._upper_first(splits)
  return table.concat(splits, "")
end

--- @param name string
--- @return string
M.get_theme_name = function(name)
  assert(type(name) == "string" and string.len(name) > 0)
  if THEME_NAMES_MAP[name] == nil then
    local result = name
    result = M._normalize_by(result, "-")
    result = M._normalize_by(result, "+")
    result = M._normalize_by(result, "_")
    result = M._normalize_by(result, ".")
    result = M._normalize_by(result, " ")
    THEME_NAMES_MAP[name] = "FzfxNvim" .. result
  end

  return THEME_NAMES_MAP[name]
end

--- @param colorname string
--- @return string
M.get_theme_config_file = function(colorname)
  local theme_dir = M.get_theme_dir()
  log.ensure(
    strings.not_empty(theme_dir),
    "|get_theme_config_file| failed to get bat config theme dir"
  )
  local theme_name = M.get_theme_name(colorname)
  log.ensure(
    strings.not_empty(theme_name),
    "|get_theme_config_file| failed to get bat theme name from nvim colorscheme name:%s",
    vim.inspect(colorname)
  )
  -- log.debug(
  --   "|get_theme_config_file| theme_dir:%s, theme_name:%s",
  --   vim.inspect(theme_dir),
  --   vim.inspect(theme_name)
  -- )
  return paths.join(theme_dir, theme_name .. ".tmTheme")
end

return M
