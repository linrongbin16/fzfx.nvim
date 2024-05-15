local consts = require("fzfx.lib.constants")
local tbl = require("fzfx.commons.tbl")

local M = {}

local EXEC_CONFIGS = {
  {
    items = {
      { cond = consts.HAS_ECHO, name = consts.ECHO },
    },
    fail = { "echo" },
  },
  {
    items = {
      { cond = consts.HAS_CURL, name = consts.CURL },
    },
    fail = { "curl" },
  },
  {
    items = {
      { cond = consts.HAS_FD, name = consts.FD },
      { cond = consts.HAS_FIND, name = consts.FIND },
    },
    fail = { "fd", "find", "gfind" },
  },
  {
    items = {
      { cond = consts.HAS_BAT, name = consts.BAT },
      { cond = consts.HAS_CAT, name = consts.CAT },
    },
    fail = { "bat", "batcat", "cat" },
  },
  {
    items = {
      { cond = consts.HAS_RG, name = consts.RG },
      { cond = consts.HAS_GREP, name = consts.GREP },
    },
    fail = { "rg", "grep", "ggrep" },
  },
  {
    items = {
      { cond = consts.HAS_GIT, name = consts.GIT },
    },
    fail = { "git" },
  },
  {
    items = {
      { cond = consts.HAS_DELTA, name = consts.DELTA },
    },
    fail = { "delta" },
  },
  {
    items = {
      { cond = consts.HAS_LSD, name = consts.LSD },
      { cond = consts.HAS_EZA, name = consts.EZA },
      { cond = consts.HAS_LS, name = consts.LS },
    },
    fail = { "lsd", "eza", "exa", "ls" },
  },
}

--- @param name string
--- @return string
local function stringize(name)
  return string.format("'%s'", name)
end

M.check = function()
  vim.health.start("fzfx")

  for _, config in ipairs(EXEC_CONFIGS) do
    local exec = tbl.List:of()
    for _, item in ipairs(config.items) do
      if item.cond then
        exec:push(item.name)
      end
    end
    if not exec:empty() then
      local all_exec = exec
        :map(function(value, index)
          local result = stringize(value)
          return (index == 1 and exec:length() > 1) and result .. " (preferred)" or result
        end)
        :data()
      vim.health.ok(string.format("Found %s", table.concat(all_exec, ",")))
    else
      local all_exec = tbl.List
        :copy(config.fail)
        :map(function(value)
          return stringize(value)
        end)
        :data()
      vim.health.error(string.format("Missing %s", table.concat(all_exec, ",")))
    end
  end
end

return M
