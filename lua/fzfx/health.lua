local consts = require("fzfx.lib.constants")
local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")

local M = {}

local EXEC_CONFIGS = {
  {
    items = {
      { cond = consts.HAS_FZF, name = consts.FZF, version = "--version", line = 1 },
    },
    fail = { "fzf" },
  },
  {
    items = {
      { cond = consts.HAS_ECHO, name = consts.ECHO },
    },
    fail = { "echo" },
  },
  {
    items = {
      { cond = consts.HAS_CURL, name = consts.CURL, version = "--version", line = 1 },
    },
    fail = { "curl" },
  },
  {
    items = {
      { cond = consts.HAS_FD, name = consts.FD, version = "--version", line = 1 },
      { cond = consts.HAS_FIND, name = consts.FIND },
    },
    fail = { "fd", "find", "gfind" },
  },
  {
    items = {
      { cond = consts.HAS_BAT, name = consts.BAT, version = "--version", line = 1 },
      { cond = consts.HAS_CAT, name = consts.CAT },
    },
    fail = { "bat", "batcat", "cat" },
  },
  {
    items = {
      { cond = consts.HAS_RG, name = consts.RG, version = "--version", line = 1 },
      { cond = consts.HAS_GREP, name = consts.GREP },
    },
    fail = { "rg", "grep", "ggrep" },
  },
  {
    items = {
      { cond = consts.HAS_GIT, name = consts.GIT, version = "--version", line = 1 },
    },
    fail = { "git" },
  },
  {
    items = {
      { cond = consts.HAS_DELTA, name = consts.DELTA, version = "--version", line = 1 },
    },
    fail = { "delta" },
  },
  {
    items = {
      { cond = consts.HAS_LSD, name = consts.LSD, version = "--version", line = 1 },
      { cond = consts.HAS_EZA, name = consts.EZA, version = "--version", line = 2 },
      { cond = consts.HAS_LS, name = consts.LS },
    },
    fail = { "lsd", "eza", "exa", "ls" },
  },
}

M.check = function()
  vim.health.start("fzfx")

  for _, config in ipairs(EXEC_CONFIGS) do
    local exec = tbl.List:of()
    for _, item in ipairs(config.items) do
      if item.cond then
        exec:push(item)
      end
    end
    if not exec:empty() then
      local all_exec = exec
        :map(function(item, index)
          return string.format("'%s'", vim.fn.fnamemodify(item.name, ":~:."))
        end)
        :data()
      local msg = string.format("Found %s", table.concat(all_exec, ","))
      local all_version = exec
        :map(function(item, index)
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
        :data()
      for i, version in ipairs(all_version) do
        local preferred = i == 1 and "(Preferred) " or ""
        if
          tbl.tbl_not_empty(version)
          and version.ok
          and tbl.list_not_empty(version.output)
          and #version.output >= version.line
        then
          local target_line = nil
          for j, out_line in ipairs(version.output) do
            if j == version.line then
              target_line = str.trim(out_line)
              break
            end
          end
          msg = msg .. string.format("\n  - %s'%s': %s", preferred, version.name, target_line)
        elseif tbl.tbl_not_empty(version) and not version.unversioned and not version.ok then
          msg = msg
            .. string.format(
              "\n  - (**Warning**) %s'%s': failed to get version info",
              preferred,
              version.name
            )
        end
      end
      vim.health.ok(msg)
    else
      local all_exec = tbl.List
        :copy(config.fail)
        :map(function(item)
          return string.format("'%s'", item)
        end)
        :data()
      vim.health.error(string.format("Missing %s", table.concat(all_exec, ",")))
    end
  end
end

return M
