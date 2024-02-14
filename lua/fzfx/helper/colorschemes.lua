local strings = require("fzfx.commons.strings")
local tables = require("fzfx.commons.tables")

local log = require("fzfx.lib.log")

local M = {}

local COLOR_NAME = vim.g.colors_name

--- @return string?
M.get_color_name = function()
  return COLOR_NAME
end

M.setup = function()
  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      -- log.debug("|setup| ColorScheme event:%s", vim.inspect(event))
      vim.schedule(function()
        COLOR_NAME = vim.g.colors_name
        -- log.debug("|setup| new colorscheme:%s", vim.inspect(COLOR_NAME))
      end)
    end,
  })
end

return M
