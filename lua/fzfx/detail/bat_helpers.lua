local paths = require("fzfx.commons.paths")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")

local bat_themes = require("fzfx.lib.bat_themes")
local log = require("fzfx.lib.log")

local M = {}

local building_bat_theme = false
M.build_custom_theme = function()
  if building_bat_theme then
    return
  end
  building_bat_theme = true
  local theme = bat_themes.calculate_custom_theme()
  if theme then
    local theme_dir = bat_themes.get_bat_themes_config_dir()
    if not paths.isdir(theme_dir) then
      spawn
        .run({ "mkdir", "-p", theme_dir }, {
          on_stdout = function() end,
          on_stderr = function() end,
        })
        :wait()
    end
    fileios.writefile(
      bat_themes.get_custom_theme_file() --[[@as string]],
      theme.payload
    )
    spawn
      .run({ "bat", "cache", "--build" }, {
        on_stdout = function(line)
          log.debug("|setup| bat cache on_stderr:%s", vim.inspect(line))
        end,
        on_stderr = function(line)
          log.debug("|setup| bat cache on_stderr:%s", vim.inspect(line))
        end,
      })
      :wait()
    vim.schedule(function()
      building_bat_theme = false
    end)
  end
end

M.setup = function()
  M.build_custom_theme()
  vim.api.nvim_create_autocmd(
    { "ColorScheme" },
    { callback = M.build_custom_theme }
  )
end

return M
