local consts = require("fzfx.lib.constants")
local tbl = require("fzfx.commons.tbl")

local M = {}

--- @param name string
--- @return string
local function stringize(name)
  return string.format("'%s'", name)
end

M._common = function()
  if consts.HAS_ECHO then
    vim.health.ok(string.format("'%s' found", consts.ECHO))
  else
    vim.health.error("'echo' not found")
  end
  if consts.HAS_CURL then
    vim.health.ok(string.format("'%s' found", consts.CURL))
  else
    vim.health.error("'curl' not found")
  end
end

M._find = function()
  local exec = tbl.List:of()

  if consts.HAS_FD then
    exec:push(consts.FD)
  end
  if consts.HAS_FIND then
    exec:push(consts.FIND)
  end

  if exec:empty() then
    vim.health.error("Missing 'fd'/'find'/'gfind'")
  else
    exec = exec
      :map(function(value)
        return stringize(value)
      end)
      :data()
    vim.health.ok(string.format("Found %s", table.concat(exec, ",")))
  end
end

M._cat = function()
  if consts.HAS_BAT then
    vim.health.ok(string.format("'%s' found", consts.BAT))
  elseif consts.HAS_CAT then
    vim.health.ok(string.format("'%s' found", consts.CAT))
  else
    vim.health.error("'bat'/'batcat'/'cat' not found")
  end
end

M._grep = function()
  if consts.HAS_RG then
    vim.health.ok(string.format("'%s' found", consts.RG))
  elseif consts.HAS_GREP then
    vim.health.ok(string.format("'%s' found", consts.GREP))
  else
    vim.health.error("'rg'/'grep'/'ggrep' not found")
  end
end

M._git = function()
  if consts.HAS_GIT then
    vim.health.ok(string.format("'%s' found", consts.GIT))
  else
    vim.health.error("'git' not found")
  end
  if consts.HAS_DELTA then
    vim.health.ok(string.format("'%s' found", consts.DELTA))
  end
end

M._ls = function()
  if consts.HAS_LSD then
    vim.health.ok(string.format("'%s' found", consts.LSD))
  elseif consts.HAS_EZA then
    vim.health.ok(string.format("'%s' found", consts.EZA))
  elseif consts.HAS_LS then
    vim.health.ok(string.format("'%s' found", consts.LS))
  else
    vim.health.error("'lsd'/'eza'/'exa'/'ls' not found")
  end
  if consts.HAS_DELTA then
    vim.health.ok(string.format("'%s' found", consts.DELTA))
  end
end

M.check = function()
  vim.health.start("fzfx")

  M._common()
  M._find()
  M._cat()
  M._grep()
  M._git()
  M._ls()
end

return M
