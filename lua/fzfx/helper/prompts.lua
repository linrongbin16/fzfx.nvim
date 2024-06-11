local str = require("fzfx.commons.str")

local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local M = {}

local CANCELLED_MESSAGE = "cancelled."

--- @param bufnr integer
--- @param callback fun():any
M.confirm_discard_modified = function(bufnr, callback)
  if not vim.o.hidden and vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
    local ok, input = pcall(vim.fn.input, {
      prompt = "[fzfx] buffer has been modified, continue? (y/n) ",
      cancelreturn = "n",
    })
    if ok and str.not_empty(input) and str.startswith(input, "y", { ignorecase = true }) then
      callback()
    else
      log.echo(LogLevels.INFO, CANCELLED_MESSAGE)
    end
  else
    callback()
  end
end

return M
