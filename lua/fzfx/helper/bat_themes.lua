local paths = require("fzfx.commons.paths")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")
local strings = require("fzfx.commons.strings")

local env = require("fzfx.lib.env")

local M = {}

--- @return string
M._theme_dir_cache = function()
  return paths.join(env.cache_dir(), "_last_bat_themes_dir_cache")
end

--- @return string?
M._cached_theme_dir = function()
  return fileios.readfile(M._theme_dir_cache(), { trim = true })
end

local dumping_bat_themes_dir = false

--- @param value string
--- @param sync boolean?
M._dump_theme_dir = function(value, sync)
  if sync then
    fileios.writefile(M._theme_dir_cache(), value)
    return
  end

  if dumping_bat_themes_dir then
    return
  end

  dumping_bat_themes_dir = true
  fileios.asyncwritefile(M._theme_dir_cache(), value, function()
    vim.schedule(function()
      dumping_bat_themes_dir = false
    end)
  end)
end

local saving_bat_themes_dir = false

--- @return string?
M.get_bat_themes_dir = function()
  local cached_result = M._cached_theme_dir() --[[@as string]]

  if strings.empty(cached_result) then
    local result = ""
    local ok, sp = pcall(spawn.run, { "bat", "--config-dir" }, {
      on_stdout = function(line)
        result = result .. line
      end,
      on_stderr = function() end,
    }, function() end)
    if not ok then
      return nil
    end

    sp:wait()
    M._dump_theme_dir(paths.join(result, "themes"), true)

    return result
  else
    vim.schedule(function()
      if saving_bat_themes_dir then
        return
      end
      saving_bat_themes_dir = true

      local result = ""
      local ok, err = pcall(spawn.run, { "bat", "--config-dir" }, {
        on_stdout = function(line)
          result = result .. line
        end,
        on_stderr = function() end,
      }, function()
        vim.schedule(function()
          M._dump_theme_dir(paths.join(result, "themes"))
          vim.schedule(function()
            saving_bat_themes_dir = false
          end)
        end)
      end)
    end)

    return cached_result
  end
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
      string.format(
        "|_upper_firsts| invalid name(%d):%s",
        vim.inspect(i),
        vim.inspect(n)
      )
    )
    local new_name = string.sub(n, 1, 1):upper()
      .. (string.len(n) > 1 and string.sub(n, 2) or "")
    table.insert(new_names, new_name)
  end
  return new_names
end

--- @param s string
--- @param delimiter string
--- @return string
M._normalize_by = function(s, delimiter)
  local splits = strings.find(s, delimiter)
      and strings.split(s, delimiter, { trimempty = true })
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
--- @return string?
M.get_theme_config_file = function(colorname)
  local theme_dir = M.get_bat_themes_dir() --[[@as string]]
  if strings.empty(theme_dir) then
    return nil
  end
  local theme_name = M.get_theme_name(colorname)
  assert(type(theme_name) == "string" and string.len(theme_name) > 0)
  return paths.join(theme_dir, theme_name .. ".tmTheme")
end

return M
