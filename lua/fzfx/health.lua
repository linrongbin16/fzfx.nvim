---@diagnostic disable: redundant-parameter

local consts = require("fzfx.lib.constants")
local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")

local M = {}

--- @alias fzfx.HealthCheckItem {cond:boolean,name:string,version:string?,line:integer?}
--- @alias fzfx.HealthCheck {items:fzfx.HealthCheckItem[],missed:string[]}
--- @type fzfx.HealthCheck[]
local HEALTH_CHECKS = {
  {
    items = {
      { cond = consts.HAS_FZF, name = consts.FZF, version = "--version", line = 1 },
    },
    missed = { "fzf" },
  },
  {
    items = {
      { cond = consts.HAS_ECHO, name = consts.ECHO },
    },
    missed = { "echo" },
  },
  {
    items = {
      { cond = consts.HAS_CURL, name = consts.CURL, version = "--version", line = 1 },
    },
    missed = { "curl" },
  },
  {
    items = {
      { cond = consts.HAS_FD, name = consts.FD, version = "--version", line = 1 },
      { cond = consts.HAS_FIND, name = consts.FIND },
    },
    missed = { "fd", "find", "gfind" },
  },
  {
    items = {
      { cond = consts.HAS_BAT, name = consts.BAT, version = "--version", line = 1 },
      { cond = consts.HAS_CAT, name = consts.CAT },
    },
    missed = { "bat", "batcat", "cat" },
  },
  {
    items = {
      { cond = consts.HAS_RG, name = consts.RG, version = "--version", line = 1 },
      { cond = consts.HAS_GREP, name = consts.GREP },
    },
    missed = { "rg", "grep", "ggrep" },
  },
  {
    items = {
      { cond = consts.HAS_GIT, name = consts.GIT, version = "--version", line = 1 },
    },
    missed = { "git" },
  },
  {
    items = {
      { cond = consts.HAS_DELTA, name = consts.DELTA, version = "--version", line = 1 },
    },
    missed = { "delta" },
    missed_level = "warn",
  },
  {
    items = {
      { cond = consts.HAS_LSD, name = consts.LSD, version = "--version", line = 1 },
      { cond = consts.HAS_EZA, name = consts.EZA, version = "--version", line = 2 },
      { cond = consts.HAS_LS, name = consts.LS },
    },
    missed = { "lsd", "eza", "exa", "ls" },
  },
}

--- @param items commons.List
--- @return string
M._summary = function(items)
  local n = items:length()
  local founded_items = items
    :map(function(
      item --[[@as fzfx.HealthCheckItem]],
      index
    )
      return string.format(
        "'%s'%s",
        vim.fn.fnamemodify(item.name, ":~:."),
        (index == 1 and n > 1) and " (preferred)" or ""
      )
    end)
    :join(", ")
  return "Found " .. founded_items
end

--- @param items commons.List
--- @return string
M._versions = function(items)
  local result = ""
  items
    :map(function(
      item --[[@as fzfx.HealthCheckItem]]
    )
      if str.not_empty(item.version) then
        local ok, output = pcall(vim.fn.systemlist, { item.name, item.version })
        return {
          ok = ok,
          unversioned = false,
          output = output,
          line = item.line,
          name = vim.fn.fnamemodify(item.name, ":~:."),
        }
      else
        return {
          ok = false,
          unversioned = true,
          output = nil,
          line = item.line,
          name = vim.fn.fnamemodify(item.name, ":~:."),
        }
      end
    end)
    :forEach(function(
      ver --[[@as {ok:boolean,unversioned:boolean,output:string[]|nil,line:integer?,name:string}]]
    )
      if
        tbl.tbl_not_empty(ver)
        and ver.ok
        and tbl.list_not_empty(ver.output)
        and #ver.output >= ver.line
      then
        local target_line = nil
        for i, out_line in ipairs(ver.output) do
          if i == ver.line then
            target_line = str.trim(out_line)
            break
          end
        end
        result = result .. string.format("\n  - '%s': %s", ver.name, target_line)
      elseif tbl.tbl_not_empty(ver) and not ver.unversioned and not ver.ok then
        result = result
          .. string.format("\n  - (**Warning**) '%s': failed to get version info", ver.name)
      end
    end)
  return result
end

--- @param misses string[]
--- @return string
M._misses = function(misses)
  local result = tbl.List
    :copy(misses)
    :map(function(item)
      return string.format("'%s'", item)
    end)
    :join(", ")
  return "Missing " .. result
end

M.check = function()
  vim.health.start("fzfx")

  for _, config in ipairs(HEALTH_CHECKS) do
    local configured_items = tbl.List:copy(config.items)
    local items = configured_items:filter(function(
      item --[[@as fzfx.HealthCheckItem]]
    )
      return item.cond
    end)

    if not items:empty() then
      local msg = M._summary(items)
      msg = msg .. M._versions(items)
      vim.health.ok(msg)
    else
      local msg = M._misses(config.missed)
      vim.health.error(msg)
    end
  end
end

return M
