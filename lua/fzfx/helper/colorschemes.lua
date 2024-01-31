local paths = require("fzfx.commons.paths")
local fileios = require("fzfx.commons.fileios")
local strings = require("fzfx.commons.strings")
local tables = require("fzfx.commons.tables")

local env = require("fzfx.lib.env")
local log = require("fzfx.lib.log")

local M = {}

local CACHED_COLOR_NAME = nil

--- @return string
M._color_name_cache = function()
  return paths.join(env.cache_dir(), "_last_color_name_cache")
end

--- @return string?
M.get_color_name = function()
  if CACHED_COLOR_NAME == nil then
    CACHED_COLOR_NAME = fileios.readfile(M._color_name_cache(), { trim = true })
  end
  return CACHED_COLOR_NAME
end

local dumping_color_name = false

--- @param colorname string?
M._dump_color_name = function(colorname)
  if strings.empty(colorname) then
    return
  end
  if dumping_color_name then
    return
  end
  dumping_color_name = true
  pcall(
    fileios.asyncwritefile,
    M._color_name_cache(),
    colorname --[[@as string]],
    function()
      dumping_color_name = false
    end
  )
end

M.setup = function()
  local color = vim.g.colors_name
  if strings.not_empty(color) then
    M._dump_color_name(color)
  end

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      log.debug("|setup| ColorScheme event:%s", vim.inspect(event))
      if strings.not_empty(tables.tbl_get(event, "match")) then
        M._dump_color_name(event.match)
      end
    end,
  })
end

return M
