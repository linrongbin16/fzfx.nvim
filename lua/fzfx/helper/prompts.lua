local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")

local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels

local M = {}

local CANCELLED_MESSAGE = "cancelled."

--- @param bufnr integer
--- @param callback fun():any
M.confirm_discard_modified = function(bufnr, callback)
  if not vim.o.hidden and nvims.get_buf_option(bufnr, "modified") then
    local ok, input = pcall(vim.fn.input, {
      prompt = "[fzfx] buffer has been modified, continue? (y/n) ",
      cancelreturn = "n",
    })
    if ok and strs.not_empty(input) and strs.startswith(input:lower(), "y") then
      callback()
    else
      log.echo(LogLevels.INFO, CANCELLED_MESSAGE)
    end
  else
    callback()
  end
end

return M
