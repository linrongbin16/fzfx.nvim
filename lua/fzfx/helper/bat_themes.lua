local path = require("fzfx.commons.path")
local spawn = require("fzfx.commons.spawn")
local str = require("fzfx.commons.str")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")

local M = {}

--- @param theme_dir string
M._create_theme_dir = function(theme_dir)
  if path.isdir(theme_dir) then
    return
  end
  vim.fn.mkdir(theme_dir, "p")
end

--- @type string?
local cached_theme_dir = nil

--- @param cb (fun(theme_dir:string?):nil)|nil
--- @return string?
M.get_theme_dir = function(cb)
  if str.empty(cached_theme_dir) then
    log.ensure(constants.HAS_BAT, "|get_theme_dir| cannot find 'bat' executable")

    local config_dir = ""
    spawn.run({ constants.BAT, "--config-dir" }, {
      on_stdout = function(line)
        config_dir = config_dir .. line
      end,
      on_stderr = function() end,
    }, function(completed)
      -- log.debug("|get_theme_dir| config_dir:%s", vim.inspect(config_dir))
      cached_theme_dir = path.join(config_dir, "themes")
      vim.schedule(function()
        M._create_theme_dir(cached_theme_dir)
        if vim.is_callable(cb) then
          cb(cached_theme_dir)
        end
      end)
    end)

    return nil
  end

  M._create_theme_dir(cached_theme_dir --[[@as string]])
  return cached_theme_dir
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
  local splits = str.find(s, delimiter) and str.split(s, delimiter, { trimempty = true }) or { s }
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
--- @return string?
M.get_theme_config_file = function(colorname)
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

return M
