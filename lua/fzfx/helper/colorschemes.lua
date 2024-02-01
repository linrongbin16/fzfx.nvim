local strings = require("fzfx.commons.strings")
local tables = require("fzfx.commons.tables")

local log = require("fzfx.lib.log")

local M = {}

local COLOR_NAME = vim.g.colors_name

--- @return string?
M.get_color_name = function()
  log.debug("|get_color_name| COLOR_NAME:%s", vim.inspect(COLOR_NAME))
  return COLOR_NAME
end

M.setup = function()
  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      log.debug("|setup| ColorScheme event:%s", vim.inspect(event))
      if strings.not_empty(tables.tbl_get(event, "match")) then
        COLOR_NAME = event.match
      end
    end,
  })
end

return M
