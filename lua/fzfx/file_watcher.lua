local constants = require("fzfx.constants")
local path = require("fzfx.path")
local log = require("fzfx.log")
local conf = require("fzfx.config")
local utils = require("fzfx.utils")

--- @alias FileWatcherCallback fun(filename:string,events:table):nil
--- @class FileWatcher
--- @field fs_event_handle uv_fs_event_t
--- @field registries table<string, FileWatcherCallback>
local FileWatcher = {}

--- @return FileWatcher
function FileWatcher:new()
    local fs_event_handle, new_fs_event_err = vim.loop.new_fs_event()
    log.ensure(
        fs_event_handle ~= nil,
        "|fzfx.file_watcher - FileWatcher:new| failed to create fs_event:%s",
        vim.inspect(new_fs_event_err)
    )
    local o = {
        fs_event_handle = fs_event_handle,
        registries = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- @param filename string
--- @param callback FileWatcherCallback
--- @return UniqueId
function FileWatcher:register(filename, callback)
    log.ensure(
        self.registries[filename] == nil,
        "|fzfx.file_watcher - FileWatcher:register| file %s already been registered",
        vim.inspect(filename)
    )
    log.ensure(
        type(callback) == "function",
        "|fzfx.file_watcher - FileWatcher:register| callback on file %s must be a function",
        vim.inspect(filename)
    )
    self.registries[filename] = callback
end

--- @param filename string
--- @return FileWatcherCallback
function FileWatcher:unregister(filename)
    log.ensure(
        type(self.registries[filename]) == "function",
        "|fzfx.file_watcher - FileWatcher:unregister| callback on file %s not exist",
        vim.inspect(filename)
    )
    local callback = self.registries[filename]
    self.registries[filename] = nil
    return callback
end

--- @param folder string
function FileWatcher:_watch(folder)
    log.ensure(
        vim.fn.isdirectory(folder) > 0,
        "|fzfx.file_watcher - FileWatcher:_watch| cannot watch on path:%s",
        vim.inspect(folder)
    )
    local start_result, start_err = self.fs_event_handle:start(
        folder,
        {},
        function(watch_err, filename, events)
            if watch_err then
                log.err(
                    not watch_err,
                    "|fzfx.file_watcher - FileWatcher:_watch| failed to complete watch on file:%s, events:%s, error:%s",
                    vim.inspect(filename),
                    vim.inspect(events),
                    vim.inspect(watch_err)
                )
                return
            end
            if type(self.registries[filename]) ~= "function" then
                return
            end
            local callback = self.registries[filename]
            callback(filename, events)
        end
    )
    log.ensure(
        start_result ~= nil,
        "|fzfx.file_watcher - FileWatcher:_watch| failed to start watch on path:%s, error:%s",
        vim.inspect(folder),
        vim.inspect(start_err)
    )
end

local FileWatcherInstance = nil

--- @return FileWatcher
local function get_file_watcher()
    return FileWatcherInstance --[[@as FileWatcher]]
end

local function setup()
    FileWatcherInstance = FileWatcher:new()
    FileWatcherInstance:_watch(conf.get_config().cache.dir)
end

local M = {
    setup = setup,
    get_file_watcher = get_file_watcher,
}

return M
