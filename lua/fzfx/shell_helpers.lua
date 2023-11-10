-- infra utils {

local is_windows = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0

if is_windows then
    vim.o.shell = "cmd.exe"
    vim.o.shellslash = false
    vim.o.shellcmdflag = "/s /c"
    vim.o.shellxquote = '"'
    vim.o.shellquote = ""
    vim.o.shellredir = ">%s 2>&1"
    vim.o.shellpipe = "2>&1| tee"
    vim.o.shellxescape = ""
else
    vim.o.shell = "sh"
end

--- @type string
local PATH_SEPARATOR = (vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0)
        and "\\"
    or "/"

local DEBUG_ENABLE = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE) == "1"

local LoggerContext = {
    level = DEBUG_ENABLE and require("fzfx.log").LogLevels.DEBUG
        or require("fzfx.log").LogLevels.INFO,
    console_log = DEBUG_ENABLE and true or false,
    file_log = DEBUG_ENABLE and true or false,
    file_path = nil,
}

--- @param name string
local function setup(name)
    LoggerContext.file_path = string.format(
        "%s%s%s",
        vim.fn.stdpath("data"),
        PATH_SEPARATOR,
        string.format("fzfx_bin_%s.log", name)
    )
end

--- @param level integer
--- @param msg string
local function _log(level, msg)
    local LogLevelNames = require("fzfx.log").LogLevelNames
    if level < LoggerContext.level then
        return
    end

    local msg_lines = require("fzfx.utils").string_split(msg, "\n")
    if LoggerContext.console_log then
        for _, line in ipairs(msg_lines) do
            io.write(string.format("%s %s\n", LogLevelNames[level], line))
        end
    end
    if LoggerContext.file_log then
        local fp = io.open(LoggerContext.file_path, "a")
        if fp then
            for _, line in ipairs(msg_lines) do
                fp:write(
                    string.format(
                        "%s [%s]: %s\n",
                        os.date("%Y-%m-%d %H:%M:%S"),
                        LogLevelNames[level],
                        line
                    )
                )
            end
            fp:close()
        end
    end
end

local function log_debug(fmt, ...)
    local LogLevels = require("fzfx.log").LogLevels
    _log(LogLevels.DEBUG, string.format(fmt, ...))
end

local function log_err(fmt, ...)
    local LogLevels = require("fzfx.log").LogLevels
    _log(LogLevels.ERROR, string.format(fmt, ...))
end

local function log_throw(fmt, ...)
    log_err(fmt, ...)
    error(string.format(fmt, ...))
end

--- @param cond boolean
--- @param fmt string
--- @param ... any[]|any
local function log_ensure(cond, fmt, ...)
    if not cond then
        log_throw(fmt, ...)
    end
end

-- infra utils }

-- icon render {

local DEVICONS_PATH = vim.env._FZFX_NVIM_DEVICONS_PATH
local UNKNOWN_FILE_ICON = vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON
local FOLDER_ICON = vim.env._FZFX_NVIM_FILE_FOLDER_ICON
local DEVICONS = nil
if type(DEVICONS_PATH) == "string" and string.len(DEVICONS_PATH) > 0 then
    vim.opt.runtimepath:append(DEVICONS_PATH)
    DEVICONS = require("nvim-web-devicons")
end

--- @param line string
--- @param delimiter string?
--- @param pos integer?
local function prepend_path_with_icon(line, delimiter, pos)
    if DEVICONS == nil then
        return line
    end
    local filename = nil
    if
        type(delimiter) == "string"
        and string.len(delimiter) > 0
        and type(pos) == "number"
    then
        local splits = require("fzfx.utils").string_split(line, delimiter)
        filename = splits[pos]
    else
        filename = line
    end
    -- remove ansi color codes
    -- see: https://stackoverflow.com/a/55324681/4438921
    if type(filename) == "string" and string.len(filename) > 0 then
        filename = require("fzfx.color").erase(filename)
    end
    local ext = vim.fn.fnamemodify(filename, ":e")
    local icon, icon_color = DEVICONS.get_icon_color(filename, ext)
    -- log_debug(
    --     "|fzfx.shell_helpers - render_line_with_icon| ext:%s, icon:%s, icon_color:%s",
    --     vim.inspect(ext),
    --     vim.inspect(icon),
    --     vim.inspect(icon_color)
    -- )
    if type(icon) == "string" and string.len(icon) > 0 then
        local colorfmt = require("fzfx.color").csi(icon_color, true)
        if colorfmt then
            return string.format("[%sm%s[0m %s", colorfmt, icon, line)
        else
            return string.format("%s %s", icon, line)
        end
    else
        if vim.fn.isdirectory(filename) > 0 then
            return string.format("%s %s", FOLDER_ICON, line)
        else
            return string.format("%s %s", UNKNOWN_FILE_ICON, line)
        end
    end
end

-- icon render }

-- make pipe rpc {

--- @param registry_id string
--- @param params string?
local function make_pipe_rpc_notify(registry_id, params)
    local address = vim.env._FZFX_NVIM_PIPE_ADDRESS

    local client_handle, new_client_err = vim.loop.new_pipe(false) --[[@as uv_pipe_t]]
    log_ensure(
        client_handle ~= nil,
        "|fzfx.shell_helpers - make_pipe_rpc_notify| failed to create new pipe client:%s",
        vim.inspect(new_client_err)
    )

    local function _close_handle()
        if client_handle and not client_handle:is_closing() then
            client_handle:close(function()
                vim.loop.stop()
            end)
        end
    end

    local connect_result, connect_err = client_handle:connect(
        address,
        function(connect_complete_err)
            log_debug(
                "|fzfx.shell_helpers - make_pipe_rpc_notify| connect complete on address: %s",
                vim.inspect(address)
            )
            if connect_complete_err then
                log_err(
                    "|fzfx.shell_helpers - make_pipe_rpc_notify| failed to complete connection on address:%s, error:%s",
                    vim.inspect(address),
                    vim.inspect(connect_complete_err)
                )
                return
            end

            --- @type RpcParams
            local obj = {
                ["id"] = registry_id,
                params = params,
            }
            local send_data = require("fzfx.json").encode(obj) --[[@as string]]
            local write_result, write_err = client_handle:write(
                send_data,
                function(write_complete_err)
                    if write_complete_err then
                        log_err(
                            "|fzfx.shell_helpers - make_pipe_rpc_notify| failed to write on client pipe:%s, data:%s",
                            vim.inspect(write_complete_err),
                            vim.inspect(send_data)
                        )
                    end
                    _close_handle()
                end
            )
            log_ensure(
                write_result ~= nil,
                "|fzfx.shell_helpers - make_pipe_rpc_notify| failed to write client pipe on address:%s, error:%s",
                vim.inspect(address),
                vim.inspect(write_err)
            )
        end
    )
    log_ensure(
        connect_result ~= nil,
        "|fzfx.shell_helpers - make_pipe_rpc_notify| failed to connect to pipe server on address: %s, error: %s",
        vim.inspect(address),
        vim.inspect(connect_err)
    )
    vim.loop.run()
end

-- make pipe rpc }

local M = {
    setup = setup,
    log_debug = log_debug,
    log_err = log_err,
    log_throw = log_throw,
    log_ensure = log_ensure,
    json = require("fzfx.json"),
    prepend_path_with_icon = prepend_path_with_icon,
    Cmd = require("fzfx.cmd").Cmd,
    GitRootCmd = require("fzfx.cmd").GitRootCmd,
    GitBranchCmd = require("fzfx.cmd").GitBranchCmd,
    GitCurrentBranchCmd = require("fzfx.cmd").GitCurrentBranchCmd,
    string_ltrim = require("fzfx.utils").string_ltrim,
    string_rtrim = require("fzfx.utils").string_rtrim,
    FileLineReader = require("fzfx.utils").FileLineReader,
    readfile = require("fzfx.utils").readfile,
    writefile = require("fzfx.utils").writefile,
    Spawn = require("fzfx.spawn").Spawn,
    make_pipe_rpc_notify = make_pipe_rpc_notify,
}

return M
