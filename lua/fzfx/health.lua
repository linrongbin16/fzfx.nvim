local consts = require("fzfx.lib.constants")

local M = {}

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
  if consts.HAS_FD then
    vim.health.ok(string.format("'%s' found", consts.FD))
  elseif consts.HAS_FIND then
    vim.health.ok(string.format("'%s' found", consts.FIND))
  else
    vim.health.error("'fd'/'find'/'gfind' not found")
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
