local path = require("fzfx.path")
local log = require("fzfx.log")
local conf = require("fzfx.config")

--- @class FileWatcher
--- @field fs_event_handle uv_fs_event_t
-- @field fs_poll_handle uv_fs_poll_t
--- @field registries table<string, boolean>
local FileWatcher = {}

--- @return FileWatcher
function FileWatcher:new()
    local fs_event_handle, new_fs_event_err = vim.loop.new_fs_event()
    log.ensure(
        fs_event_handle ~= nil,
        "|fzfx.file_watcher - FileWatcher:new| failed to create fs_event:%s",
        vim.inspect(new_fs_event_err)
    )
    -- local fs_poll_handle, new_fs_poll_err = vim.loop.new_fs_poll()
    -- log.ensure(
    --     fs_poll_handle ~= nil,
    --     "|fzfx.file_watcher - FileWatcher:new| failed to create fs_poll:%s",
    --     vim.inspect(new_fs_poll_err)
    -- )

    local o = {
        fs_event_handle = fs_event_handle,
        -- fs_poll_handle = fs_poll_handle,
        registries = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param filename string
--- @param on_file_change fun(err:string?,filename:string,events:table):nil
function FileWatcher:watch(filename, on_file_change)
    log.ensure(
        self.registries[filename] == nil,
        "|fzfx.file_watcher - FileWatcher:watch| file %s already been watching",
        vim.inspect(filename)
    )
    local p = path.normalize(
        path.join(conf.get_config().cache.dir, filename),
        { expand = true }
    )
    local fs_event_result, fs_event_err =
        self.fs_event_handle:start(p, {}, on_file_change)
    log.ensure(
        fs_event_result ~= nil,
        "|fzfx.file_watcher - FileWatcher:watch| failed to start watch fs_event on path:%s, error:%s",
        vim.inspect(p),
        vim.inspect(fs_event_err)
    )
    self.registries[filename] = true
end

--- @type FileWatcher
local FileWatcherInstance = nil

local function setup()
    FileWatcherInstance = FileWatcher:new()
end

local M = {
    setup = setup,
}

return M
