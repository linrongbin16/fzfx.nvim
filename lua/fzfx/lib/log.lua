local num = require("fzfx.commons.num")

local M = {}

M.LogLevels = require("fzfx.commons.logging").LogLevels

M.LogLevelNames = require("fzfx.commons.logging").LogLevelNames

local LogHighlights = {
  [0] = "Comment",
  [1] = "Comment",
  [2] = "None",
  [3] = "WarningMsg",
  [4] = "ErrorMsg",
  [5] = "ErrorMsg",
}

--- @param level integer
--- @param msg string
M.echo = function(level, msg)
  level = num.bound(level, M.LogLevels.TRACE, M.LogLevels.OFF)

  local msg_lines = vim.split(msg, "\n", { plain = true })

  local prefix = ""
  if level == M.LogLevels.ERROR then
    prefix = "error! "
  elseif level == M.LogLevels.WARN then
    prefix = "warning! "
  end

  for _, line in ipairs(msg_lines) do
    local chunks = {}
    table.insert(chunks, {
      "[fzfx] " .. prefix .. line,
      LogHighlights[level],
    })
    vim.schedule(function()
      vim.api.nvim_echo(chunks, false, {})
    end)
  end
end

--- @type fzfx.Options
local Defaults = {
  level = M.LogLevels.INFO,
  name = "[fzfx]",
  console_log = true,
  file_log = false,
  file_name = "fzfx.log",
  file_dir = vim.fn.stdpath("data"),
  file_path = nil,
}

--- @param opts fzfx.Options?
M.setup = function(opts)
  local configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), opts or {})
  require("fzfx.commons.logging").setup({
    name = "fzfx",
    level = configs.level,
    console_log = configs.console_log,
    file_log = configs.file_log,
    file_log_name = "fzfx.log",
  })
end

--- @param msg string
M.debug = function(msg)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  if require("fzfx.commons.logging").has("fzfx") then
    require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.DEBUG, msg)
  end
end

--- @param msg string
M.info = function(msg)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  if require("fzfx.commons.logging").has("fzfx") then
    require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.INFO, msg)
  end
end

--- @param msg string
M.warn = function(msg)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  if require("fzfx.commons.logging").has("fzfx") then
    require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.WARN, msg)
  end
end

--- @param msg string
M.err = function(msg)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  if require("fzfx.commons.logging").has("fzfx") then
    require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.ERROR, msg)
  end
end

--- @param msg string
M.throw = function(msg)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  if require("fzfx.commons.logging").has("fzfx") then
    require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.ERROR, msg)
  end
  error(msg)
end

--- @param cond boolean
--- @param msg string
M.ensure = function(cond, msg)
  local dbglvl = 2
  local dbg = nil
  while true do
    dbg = debug.getinfo(dbglvl, "nfSl")
    if not dbg or dbg.what ~= "C" then
      break
    end
    dbglvl = dbglvl + 1
  end
  if not cond then
    if require("fzfx.commons.logging").has("fzfx") then
      require("fzfx.commons.logging").get("fzfx"):_log(dbg, M.LogLevels.ERROR, msg)
    end
  end
  assert(cond, msg)
end

return M
