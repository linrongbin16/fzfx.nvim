local paths = require("fzfx.commons.paths")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")
local strings = require("fzfx.commons.strings")
local tables = require("fzfx.commons.tables")

local bat_themes = require("fzfx.lib.bat_themes")
local log = require("fzfx.lib.log")

local M = {}

local building_bat_theme = false

--- @param colorname string
M.build_custom_theme = function(colorname)
  local theme_template = bat_themes.get_custom_theme_template_file(colorname) --[[@as string]]
  log.debug(
    "|build_custom_theme| colorname:%s, theme_template:%s",
    vim.inspect(colorname),
    vim.inspect(theme_template)
  )
  if strings.empty(theme_template) then
    return
  end
  local theme_dir = bat_themes.get_bat_themes_config_dir() --[[@as string]]
  log.debug("|build_custom_theme| theme_dir:%s", vim.inspect(theme_dir))
  if strings.empty(theme_dir) then
    return
  end
  local theme = bat_themes.calculate_custom_theme(colorname) --[[@as string]]
  log.debug("|build_custom_theme| theme:%s", vim.inspect(theme))
  if tables.tbl_empty(theme) then
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
  log.debug(
    "|build_custom_theme| dump theme payload, theme_template:%s",
    vim.inspect(theme_template)
  )

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
  local colorname = vim.g.colors_name
  if strings.not_empty(colorname) then
    M.build_custom_theme(colorname)
  end
  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      -- log.debug("|setup| event:%s", vim.inspect(event))
      if strings.not_empty(tables.tbl_get(event, "match")) then
        -- vim.g.colors_name = event.match
        M.build_custom_theme(event.match)
      end
    end,
  })
end

return M
