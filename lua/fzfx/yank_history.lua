local conf = require("fzfx.config")
local log = require("fzfx.log")
local env = require("fzfx.env")

--- @class Yank
--- @field regname string|nil
--- @field regtext string|nil
--- @field regtype string|nil
--- @field filetype string|nil
--- @field filename string|nil
--- @field timestamp integer|nil
local Yank = {
    regname = nil,
    regtext = nil,
    regtype = nil,
    filetype = nil,
    filename = nil,
    timestamp = nil,
}

--- @param regname string
--- @param regtext string
--- @param regtype string
--- @param filename string|nil
--- @param filetype string|nil
--- @return Yank
function Yank:new(regname, regtext, regtype, filename, filetype)
    local yank = vim.tbl_deep_extend("force", vim.deepcopy(Yank), {
        regname = regname,
        regtext = vim.fn.trim(regtext),
        regtype = regtype,
        filename = filename,
        filetype = filetype,
        timestamp = os.time(),
    })
    return yank
end

--- @class YankHistory
--- @field pos integer
--- @field queue Yank[]
--- @field maxsize integer?
local YankHistory = {
    pos = 0,
    queue = {},
    maxsize = nil,
}

--- @param maxsize integer
--- @return YankHistory
function YankHistory:new(maxsize)
    local yhm = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(YankHistory),
        { pos = 0, queue = {}, maxsize = maxsize }
    )
    return yhm
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

-- from oldest to newest
-- usage:
-- ```lua
--  local p = yank_history:start_pos()
--  while p ~= nil then
--    local yank = yank_history:get(p)
--    p = yank_history:next_pos()
--  end
-- ```
--- @return integer?
function YankHistory:start_pos()
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
function YankHistory:next_pos(pos)
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

-- from newest to oldest
-- usage:
-- ```lua
--  local p = yank_history:rstart_pos()
--  while p ~= nil then
--    local yank = yank_history:get(p)
--    p = yank_history:rnext_pos()
--  end
-- ```
--- @return integer?
function YankHistory:rstart_pos()
    if #self.queue == 0 or self.pos == 0 then
        return nil
    end
    return self.pos
end

-- from newest to oldest
--- @param pos integer
--- @return integer?
function YankHistory:rnext_pos(pos)
    if #self.queue == 0 or pos == 0 then
        return nil
    end
    if self.pos == 1 and pos == #self.queue then
        return nil
    elseif pos == self.pos + 1 then
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
local GlobalYankHistory = nil

--- @return table
local function get_register_info(regname)
    return {
        regname = regname,
        regtext = vim.fn.getreg(regname),
        regtype = vim.fn.getregtype(regname),
    }
end

--- @return integer?
local function save_yank()
    local r = get_register_info(vim.v.event.regname)
    local y = Yank:new(
        r.regname,
        r.regtext,
        r.regtype,
        vim.api.nvim_buf_get_name(0),
        vim.bo.filetype
    )
    log.debug(
        "|fzfx.yank_history - save_yank| r:%s, y:%s",
        vim.inspect(r),
        vim.inspect(y)
    )

    log.ensure(
        GlobalYankHistory ~= nil,
        "|fzfx.yank_history - save_yank| error! GlobalYankHistoryManager must not be nil!"
    )
    ---@diagnostic disable-next-line: need-check-nil
    return GlobalYankHistory:push(y)
end

--- @return Yank?
local function get_yank()
    log.ensure(
        GlobalYankHistory ~= nil,
        "|fzfx.yank_history - get_yank| error! GlobalYankHistoryManager must not be nil!"
    )
    ---@diagnostic disable-next-line: need-check-nil
    return GlobalYankHistory:get()
end

--- @return YankHistory?
local function get_global_yank_history()
    return GlobalYankHistory
end

local function setup()
    GlobalYankHistory = YankHistory:new(
        env.debug_enable() and 5
            or conf.get_config().yank_history.other_opts.history_size
    )
    vim.api.nvim_create_autocmd("TextYankPost", {
        pattern = { "*" },
        callback = function()
            -- local ok, result = pcall(save_yank)
            -- log.debug(
            --     "|fzfx.yank_history - setup| ok:%s, result:%s",
            --     vim.inspect(ok),
            --     vim.inspect(result)
            -- )
            save_yank()
        end,
    })
end

local M = {
    setup = setup,
    get_yank = get_yank,
}

return M
