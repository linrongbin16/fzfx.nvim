local consts = require("fzfx.lib.constants")
local tbl = require("fzfx.commons.tbl")

local M = {}

M._files = function()
  local execs = tbl.List:of()
  if consts.HAS_FD then
    execs:push(consts.FD)
  elseif consts.HAS_FIND then
    execs:push(consts.FIND)
  end

  execs = execs
    :map(function(value, index)
      return string.format("'%s'", value)
    end)
    :data()

  vim.health.ok(string.format("'FzfxFiles' uses %s", table.concat(execs, ",")))
end

M.check = function()
  vim.health.start("fzfx")

  M._files()
end

return M
