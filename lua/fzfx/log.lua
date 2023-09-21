local NotifyLevels = require("fzfx.notify").NotifyLevels
local NotifyLevelNames = require("fzfx.notify").NotifyLevelNames
local notify = require("fzfx.notify")

--- @type Configs
local Defaults = {
    --- @type integer
    level = NotifyLevels.INFO,
    --- @type boolean
    console_log = true,
    --- @type string|nil
    name = "[fzfx]",
    --- @type boolean
    file_log = false,
    --- @type string|nil
    file_name = "fzfx.log",
    --- @type string|nil
    file_dir = vim.fn.stdpath("data"),
    --- @type string|nil
    file_path = nil,
}

--- @type Configs
local Configs = {}

--- @type string
local PathSeparator = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
        and "\\"
    or "/"

--- @param option Configs
--- @return nil
local function setup(option)
    Configs = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), option or {})
    if type(Configs.level) == "string" then
        Configs.level = NotifyLevels[Configs.level]
    end
    if Configs.file_name and string.len(Configs.file_name) > 0 then
        -- For Windows: $env:USERPROFILE\AppData\Local\nvim-data\fzfx.log
        -- For *NIX: ~/.local/share/nvim/fzfx.log
        if Configs.file_dir then
            Configs.file_path = string.format(
                "%s%s%s",
                Configs.file_dir,
                PathSeparator,
                Configs.file_name
            )
        else
            Configs.file_path = Configs.file_name
        end
    end
    assert(type(Configs.name) == "string")
    assert(string.len(Configs.name) > 0)
    assert(type(Configs.level) == "number")
    if Configs.file_log then
        assert(type(Configs.file_path) == "string")
        assert(string.len(Configs.file_path) > 0)
        assert(type(Configs.file_name) == "string")
        assert(string.len(Configs.file_name) > 0)
    end
end

--- @param level integer
--- @param msg string
--- @return nil
local function log(level, msg)
    if Configs.level == nil then
        return
    end
    if level < Configs.level then
        return
    end

    local msg_lines = require("fzfx.utils").string_split(msg, "\n")
    if Configs.console_log and level >= NotifyLevels.INFO then
        notify.echo(level, msg)
    end
    if Configs.file_log then
        local fp = io.open(Configs.file_path, "a")
        if fp then
            for _, line in ipairs(msg_lines) do
                fp:write(
                    string.format(
                        "%s [%s]: %s\n",
                        os.date("%Y-%m-%d %H:%M:%S"),
                        NotifyLevelNames[level],
                        line
                    )
                )
            end
            fp:close()
        end
    end
end

local function debug(fmt, ...)
    log(NotifyLevels.DEBUG, string.format(fmt, ...))
end

local function info(fmt, ...)
    log(NotifyLevels.INFO, string.format(fmt, ...))
end

local function warn(fmt, ...)
    log(NotifyLevels.WARN, string.format(fmt, ...))
end

local function err(fmt, ...)
    log(NotifyLevels.ERROR, string.format(fmt, ...))
end

local function throw(fmt, ...)
    err(fmt, ...)
    error(string.format(fmt, ...))
end

--- @param condition boolean
--- @param fmt string
--- @param ... any[]|any
local function ensure(condition, fmt, ...)
    if not condition then
        throw(fmt, ...)
    end
end

local M = {
    setup = setup,
    throw = throw,
    ensure = ensure,
    err = err,
    warn = warn,
    info = info,
    debug = debug,
}

return M
