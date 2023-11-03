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
--- @field pos integer
--- @field queue Yank[]
--- @field maxsize integer
local YankHistory = {}

--- @param maxsize integer
--- @return YankHistory
function YankHistory:new(maxsize)
    local o = {
        pos = 0,
        queue = {},
        maxsize = maxsize,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param y Yank
--- @return integer
function YankHistory:push(y)
    if #self.queue < self.maxsize then
        self.pos = self.pos + 1
        table.insert(self.queue, y)
    else
        if self.pos == #self.queue then
            self.pos = 1
        else
            self.pos = self.pos + 1
        end
        self.queue[self.pos] = y
    end
    return self.pos
end

-- from oldest to newest, usage:
--
-- ```lua
--  local p = yank_history:begin()
--  while p ~= nil then
--    local yank = yank_history:get(p)
--    p = yank_history:next(p)
--  end
-- ```
--
--- @return integer?
function YankHistory:begin()
    if #self.queue == 0 or self.pos == 0 then
        return nil
    end
    if self.pos == #self.queue then
        return 1
    else
        return self.pos + 1
    end
end

-- from oldest to newest
--- @param pos integer
--- @return integer?
function YankHistory:next(pos)
    if #self.queue == 0 or pos == 0 then
        return nil
    end
    if pos == self.pos then
        return nil
    end
    if pos == #self.queue then
        return 1
    else
        return pos + 1
    end
end

-- from newest to oldest, usage:
--
-- ```lua
--  local p = yank_history:rbegin()
--  while p ~= nil then
--    local yank = yank_history:get(p)
--    p = yank_history:rnext()
--  end
-- ```
--
--- @return integer?
function YankHistory:rbegin()
    if #self.queue == 0 or self.pos == 0 then
        return nil
    end
    return self.pos
end

-- from newest to oldest
--- @param pos integer
--- @return integer?
function YankHistory:rnext(pos)
    if #self.queue == 0 or pos == 0 then
        return nil
    end
    if self.pos == 1 and pos == #self.queue then
        return nil
    elseif pos == self.pos then
        return nil
    end
    if pos == 1 then
        return #self.queue
    else
        return pos - 1
    end
end

--- @param pos integer?
--- @return Yank?
function YankHistory:get(pos)
    pos = pos or self.pos
    if #self.queue == 0 or pos == 0 then
        return nil
    else
        return self.queue[pos]
    end
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
                and path.normalize(
                    vim.api.nvim_buf_get_name(0),
                    { expand = true }
                )
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
        "|fzfx.yank_history - save_yank| error! YankHistoryInstance must not be nil!"
    )
    ---@diagnostic disable-next-line: need-check-nil
    return YankHistoryInstance:push(y)
end

--- @return Yank?
local function get_yank()
    log.ensure(
        YankHistoryInstance ~= nil,
        "|fzfx.yank_history - get_yank| error! YankHistoryInstance must not be nil!"
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
