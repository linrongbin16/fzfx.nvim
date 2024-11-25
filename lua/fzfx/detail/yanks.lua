local path = require("fzfx.commons.path")

local env = require("fzfx.lib.env")
local log = require("fzfx.lib.log")
local bufs = require("fzfx.lib.bufs")
local config = require("fzfx.config")

local M = {}

--- @class fzfx.Yank
--- @field regname string
--- @field regtext string
--- @field regtype string
--- @field filename string
--- @field filetype string?
--- @field timestamp integer?
local Yank = {}

--- @param regname string
--- @param regtext string
--- @param regtype string
--- @param filename string?
--- @param filetype string?
--- @return fzfx.Yank
function Yank:new(regname, regtext, regtype, filename, filetype)
  local o = {
    regname = regname,
    regtext = vim.trim(regtext),
    regtype = regtype,
    filename = filename,
    filetype = filetype,
    timestamp = os.time(),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

M.Yank = Yank

--- @class fzfx.YankHistory
--- @field ring_buffer vim.Ringbuf
local YankHistory = {}

--- @param maxsize integer
--- @return fzfx.YankHistory
function YankHistory:new(maxsize)
  local o = {
    ring_buffer = vim.ringbuf(maxsize),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param y fzfx.Yank
--- @return integer
function YankHistory:push(y)
  return self.ring_buffer:push(y)
end

--- @return fzfx.Yank?
function YankHistory:peek()
  return self.ring_buffer:peek()
end

--- @return fzfx.Yank?
function YankHistory:pop()
  return self.ring_buffer:pop()
end

M.YankHistory = YankHistory

--- @type fzfx.YankHistory?
M._YankHistoryInstance = nil

--- @return table
M._get_register_info = function(regname)
  return {
    regname = regname,
    regtext = vim.fn.getreg(regname),
    regtype = vim.fn.getregtype(regname),
  }
end

--- @return integer?
M.save_yank = function()
  local r = M._get_register_info(vim.v.event.regname)
  local y = Yank:new(
    r.regname,
    r.regtext,
    r.regtype,
    bufs.buf_is_valid(0)
        and path.normalize(vim.api.nvim_buf_get_name(0), { double_backslash = true, expand = true })
      or nil,
    vim.bo.filetype
  )
  -- log.debug(
  --     "|fzfx.helper.yanks - save_yank| r:%s, y:%s",
  --     vim.inspect(r),
  --     vim.inspect(y)
  -- )

  log.ensure(M._YankHistoryInstance ~= nil, "|save_yank| YankHistoryInstance must not be nil!")
  ---@diagnostic disable-next-line: need-check-nil
  return M._YankHistoryInstance:push(y)
end

--- @return fzfx.Yank?
M.get_yank = function()
  log.ensure(M._YankHistoryInstance ~= nil, "|get_yank| YankHistoryInstance must not be nil!")
  ---@diagnostic disable-next-line: need-check-nil
  return M._YankHistoryInstance:pop()
end

--- @return fzfx.YankHistory?
M._get_yank_history_instance = function()
  return M._YankHistoryInstance
end

M.setup = function()
  M._YankHistoryInstance =
    YankHistory:new(env.debug_enabled() and 10 or config.get().yank_history.other_opts.maxsize)
  vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = { "*" },
    callback = M.save_yank,
  })
end

return M
