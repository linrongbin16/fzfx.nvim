local paths = require("fzfx.commons.paths")
local strings = require("fzfx.commons.strings")
local fileios = require("fzfx.commons.fileios")
local config = require("fzfx.config")

local M = {}

local COLORS_NAME_CACHE =
  paths.join(config.get().cache.dir, "nvim", "colors", "name")

--- @return string?
M.get_colors_name = function()
  return fileios.readfile(COLORS_NAME_CACHE, { trim = true })
end

--- @param colorname string?
M.dump_colors_name = function(colorname)
  if strings.not_empty(colorname) then
    fileios.asyncwritefile(
      COLORS_NAME_CACHE,
      colorname --[[@as string]],
      function() end
    )
  end
end

return M
