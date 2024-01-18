local paths = require("fzfx.commons.paths")
local termcolors = require("fzfx.commons.termcolors")
local strings = require("fzfx.commons.strings")
local jsons = require("fzfx.commons.jsons")
local fileios = require("fzfx.commons.fileios")
local tables = require("fzfx.commons.tables")
local spawn = require("fzfx.commons.spawn")

local constants = require("fzfx.lib.constants")
local shells = require("fzfx.lib.shells")
local log = require("fzfx.lib.log")
local yanks = require("fzfx.detail.yanks")
local config = require("fzfx.config")

local M = {}

--- @return string
M.get_bat_themes_config_dir = function()
  local bat_themes_config_dir = ""
  local sp = spawn.run({ "bat", "--config-dir" }, {
    on_stdout = function(line)
      bat_themes_config_dir = bat_themes_config_dir .. line
    end,
    on_stderr = function(line)
      log.debug("|get_bat_themes_config_dir| on_stderr:%s", vim.inspect(line))
    end,
  })
  sp:wait()
  bat_themes_config_dir = bat_themes_config_dir
    .. (constants.IS_WINDOWS and "\\themes" or "/themes")
  log.debug(
    "|get_bat_themes_config_dir| config dir:%s",
    vim.inspect(bat_themes_config_dir)
  )
  return bat_themes_config_dir
end

--- @param name string
--- @return string
M._normalize_theme_name = function(name)
  log.ensure(
    type(name) == "string" and string.len(name) > 0,
    "|_normalize_theme_name| invalid name:%s",
    vim.inspect(name)
  )

  --- @param names string[]
  --- @return string[]
  local function upper_firsts(names)
    log.ensure(
      type(names) == "table" and #names > 0,
      "|_normalize_theme_name.upper_firsts| invalid names:%s",
      vim.inspect(names)
    )
    local new_names = {}
    for i, n in ipairs(names) do
      log.ensure(
        type(n) == "string" and string.len(n) > 0,
        "|_normalize_theme_name.upper_firsts| invalid name(%d):%s",
        vim.inspect(i),
        vim.inspect(n)
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
  local function normalize_by(s, delimiter)
    if strings.find(s, delimiter) then
      local splits = strings.split(s, delimiter, { trimempty = true })
      splits = upper_firsts(splits)
      return table.concat(splits, "")
    else
      return s
    end
  end

  local result = name
  result = normalize_by(result, "-")
  result = normalize_by(result, "+")
  result = normalize_by(result, "_")
  result = normalize_by(result, ".")
  result = normalize_by(result, " ")
  return "FzfxNvim" .. result
end

--- @return {name:string,payload:string}
M.get_custom_theme = function()
  local name = M._normalize_theme_name(vim.g.colors_name)
  local payload = string.format([[

]])
  return {
    name = name,
    payload = payload,
  }
end

local calculating_bat_colors = false
M.setup = function()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      if calculating_bat_colors then
        return
      end
      calculating_bat_colors = true
      vim.schedule(function()
        calculating_bat_colors = false
      end)
    end,
  })
end

return M
