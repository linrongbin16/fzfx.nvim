local conf = require("fzfx.config")
local log = require("fzfx.log")
local env = require("fzfx.env")
local utils = require("fzfx.utils")
local path = require("fzfx.path")

--- @class Yank
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
--- @return Yank
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

--- @class YankHistory
--- @field ring_buffer RingBuffer
local YankHistory = {}

--- @param maxsize integer
--- @return YankHistory
function YankHistory:new(maxsize)
  local o = {
    ring_buffer = utils.RingBuffer:new(maxsize),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param y Yank
--- @return integer
function YankHistory:push(y)
  return self.ring_buffer:push(y)
end

--- @param pos integer?
--- @return Yank?
function YankHistory:get(pos)
  return self.ring_buffer:get(pos)
end

-- from oldest to newest
--- @return integer?
function YankHistory:begin()
  return self.ring_buffer:begin()
end

-- from oldest to newest
--- @param pos integer
--- @return integer?
function YankHistory:next(pos)
  return self.ring_buffer:next(pos)
end

-- from newest to oldest
--- @return integer?
function YankHistory:rbegin()
  return self.ring_buffer:rbegin()
end

-- from newest to oldest
--- @param pos integer
--- @return integer?
function YankHistory:rnext(pos)
  return self.ring_buffer:rnext(pos)
end

--- @type YankHistory?
local YankHistoryInstance = nil

--- @return table
local function _get_register_info(regname)
  return {
    regname = regname,
    regtext = vim.fn.getreg(regname),
    regtype = vim.fn.getregtype(regname),
  }
end

--- @return integer?
local function save_yank()
  local r = _get_register_info(vim.v.event.regname)
  local y = Yank:new(
    r.regname,
    r.regtext,
    r.regtype,
    utils.is_buf_valid(0)
        and path.normalize(vim.api.nvim_buf_get_name(0), { expand = true })
      or nil,
    vim.bo.filetype
  )
  -- log.debug(
  --     "|fzfx.yank_history - save_yank| r:%s, y:%s",
  --     vim.inspect(r),
  --     vim.inspect(y)
  -- )

  log.ensure(
    YankHistoryInstance ~= nil,
    "|fzfx.yank_history - save_yank| YankHistoryInstance must not be nil!"
  )
  ---@diagnostic disable-next-line: need-check-nil
  return YankHistoryInstance:push(y)
end

--- @return Yank?
local function get_yank()
  log.ensure(
    YankHistoryInstance ~= nil,
    "|fzfx.yank_history - get_yank| YankHistoryInstance must not be nil!"
  )
  ---@diagnostic disable-next-line: need-check-nil
  return YankHistoryInstance:get()
end

--- @return YankHistory?
local function _get_yank_history_instance()
  return YankHistoryInstance
end

local function setup()
  YankHistoryInstance = YankHistory:new(
    env.debug_enable() and 10
      or conf.get_config().yank_history.other_opts.maxsize
  )
  vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = { "*" },
    callback = save_yank,
  })
end

local M = {
  setup = setup,
  get_yank = get_yank,
  save_yank = save_yank,
  Yank = Yank,
  YankHistory = YankHistory,
  _get_register_info = _get_register_info,
  _get_yank_history_instance = _get_yank_history_instance,
}

return M
