local paths = require("fzfx.commons.paths")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")
local strings = require("fzfx.commons.strings")

local bat_themes = require("fzfx.lib.bat_themes")
local log = require("fzfx.lib.log")

local M = {}

local building_bat_theme = false

M.build_custom_theme = function()
  local theme_template = bat_themes.get_custom_theme_template_file() --[[@as string]]
  if strings.empty(theme_template) then
    return
  end
  local theme_dir = bat_themes.get_bat_themes_config_dir() --[[@as string]]
  if strings.empty(theme_dir) then
    return
  end
  local theme = bat_themes.calculate_custom_theme() --[[@as string]]
  if strings.empty(theme) then
    return
  end

  if building_bat_theme then
    return
  end
  building_bat_theme = true

  if not paths.isdir(theme_dir) then
    spawn
      .run({ "mkdir", "-p", theme_dir }, {
        on_stdout = function() end,
        on_stderr = function() end,
      })
      :wait()
  end

  fileios.writefile(theme_template, theme.payload)

  spawn.run({ "bat", "cache", "--build" }, {
    on_stdout = function(line)
      log.debug("|setup| bat cache on_stderr:%s", vim.inspect(line))
    end,
    on_stderr = function(line)
      log.debug("|setup| bat cache on_stderr:%s", vim.inspect(line))
    end,
  }, function()
    vim.schedule(function()
      building_bat_theme = false
    end)
  end)
end

M.setup = function()
  M.build_custom_theme()
  vim.api.nvim_create_autocmd(
    { "ColorScheme" },
    { callback = M.build_custom_theme }
  )
end

return M
