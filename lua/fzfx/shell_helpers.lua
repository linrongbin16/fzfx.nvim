-- infra utils {

if vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0 then
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

local DEBUG_ENABLE = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"

local LoggerContext = {
    --- @type "DEBUG"|"INFO"|"WARN"|"ERROR"
    level = DEBUG_ENABLE and "DEBUG" or "INFO",
    --- @type boolean
    console_log = true,
    --- @type string|nil
    name = "[fzfx-shell-helpers]",
    --- @type boolean
    file_log = DEBUG_ENABLE and true or false,
    --- @type string|nil
    file_path = string.format(
        "%s%s%s",
        vim.fn.stdpath("data"),
        PATH_SEPARATOR,
        "fzfx_shell_helpers.log"
    ),
}

--- @param level "DEBUG"|"INFO"|"WARN"|"ERROR"
--- @param msg string
--- @return nil
local function _log(level, msg)
    if vim.log.levels[level] < vim.log.levels[LoggerContext.level] then
        return
    end

    local msg_lines = vim.split(msg, "\n")
    if LoggerContext.console_log then
        for _, line in ipairs(msg_lines) do
            io.write(string.format("%s %s\n", level, line))
        end
    end
    if LoggerContext.file_log then
        local fp = io.open(LoggerContext.file_path, "a")
        if fp then
            for _, line in ipairs(msg_lines) do
                fp:write(
                    string.format(
                        "%s %s [%s]: %s\n",
                        LoggerContext.name,
                        os.date("%Y-%m-%d %H:%M:%S"),
                        level,
                        line
                    )
                )
            end
            fp:close()
        end
    end
end

local function log_debug(fmt, ...)
    _log("DEBUG", string.format(fmt, ...))
end

local function log_info(fmt, ...)
    _log("INFO", string.format(fmt, ...))
end

local function log_warn(fmt, ...)
    _log("WARN", string.format(fmt, ...))
end

local function log_err(fmt, ...)
    _log("ERROR", string.format(fmt, ...))
end

local function log_throw(fmt, ...)
    log_err(fmt, ...)
    error(string.format(fmt, ...))
end

--- @param condition boolean
--- @param fmt string
--- @param ... any[]|any
local function log_ensure(condition, fmt, ...)
    if not condition then
        log_throw(fmt, ...)
    end
end

-- infra utils }

-- provider {

--- @param provider string
--- @return string|nil
local function read_provider_command(provider)
    local f = io.open(provider --[[@as string]], "r")
    log_ensure(
        f ~= nil,
        "|fzfx.shell_helpers| error! failed to open provider:%s",
        vim.inspect(provider)
    )
    ---@diagnostic disable-next-line: need-check-nil
    local cmd = vim.fn.trim(f:read("*a"))
    ---@diagnostic disable-next-line: need-check-nil
    f:close()
    return cmd
end

-- provider }

-- icon render {

local DEVICONS_PATH = vim.env._FZFX_NVIM_DEVICONS_PATH
local UNKNOWN_FILE_ICON = vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON
local FOLDER_ICON = vim.env._FZFX_NVIM_FILE_FOLDER_ICON
local DEVICONS = nil
if type(DEVICONS_PATH) == "string" and string.len(DEVICONS_PATH) > 0 then
    vim.opt.runtimepath:append(DEVICONS_PATH)
    DEVICONS = require("nvim-web-devicons")
end

--- @param color string
--- @param fg boolean
--- @return string|nil
local function csi(color, fg)
    local code = fg and 38 or 48
    local r, g, b = color:match("#(..)(..)(..)")
    if r and g and b then
        r = tonumber(r, 16)
        g = tonumber(g, 16)
        b = tonumber(b, 16)
        local result = string.format("%d;2;%d;%d;%d", code, r, g, b)
        -- log_debug(
        --     "|fzfx.shell_helpers - color_csi| rgb, color:%s, fg:%s, result:%s",
        --     vim.inspect(color),
        --     vim.inspect(fg),
        --     vim.inspect(result)
        -- )
        return result
    else
        local result = string.format("%d;5;%s", code, color)
        -- log_debug(
        --     "|fzfx.shell_helpers - color_csi| non-rgb, color:%s, fg:%s, result:%s",
        --     vim.inspect(color),
        --     vim.inspect(fg),
        --     vim.inspect(result)
        -- )
        return result
    end
end

--- @param p string?
local function normalize_filepath(p)
    if type(p) ~= "string" or string.len(p) == 0 then
        return p
    end
    if p:sub(1, 2) == [[./]] or p:sub(1, 2) == [[.\]] then
        return p:sub(3, #p)
    end
    return p
end

--- @param line string
--- @param delimiter string?
--- @param pos integer?
local function render_filepath_line(line, delimiter, pos)
    if DEVICONS == nil then
        return normalize_filepath(line)
    end
    local filename = nil
    if
        type(delimiter) == "string"
        and string.len(delimiter) > 0
        and type(pos) == "number"
    then
        local splits = vim.fn.split(line, delimiter)
        filename = splits[pos]
    else
        filename = line
    end
    if type(filename) == "string" and string.len(filename) > 0 then
        filename = filename:gsub("\x1b%[%d+m", "")
    end
    local ext = vim.fn.fnamemodify(filename, ":e")
    local icon, icon_color = DEVICONS.get_icon_color(filename, ext)
    -- if DEBUG_ENABLE then
    --     log_debug(
    --         "|fzfx.shell_helpers - render_line_with_icon| line:%s, ext:%s, icon:%s, color:%s\n",
    --         vim.inspect(line),
    --         vim.inspect(ext),
    --         vim.inspect(icon),
    --         vim.inspect(color)
    --     )
    -- end
    if type(icon) == "string" and string.len(icon) > 0 then
        local colorfmt = csi(icon_color, true)
        if colorfmt then
            return string.format(
                "[%sm%s[0m %s",
                colorfmt,
                icon,
                normalize_filepath(line)
            )
        else
            return string.format("%s %s", icon, normalize_filepath(line))
        end
    else
        if vim.fn.isdirectory(filename) > 0 then
            return string.format("%s %s", FOLDER_ICON, normalize_filepath(line))
        else
            return string.format(
                "%s %s",
                UNKNOWN_FILE_ICON,
                normalize_filepath(line)
            )
        end
    end
end

-- icon render }

-- parse query {

--- @param content string
--- @return string[]
local function parse_query(content)
    local flag = "--"
    local flag_pos = nil
    local query = ""
    local option = nil

    for i = 1, #content do
        if i + 1 <= #content and string.sub(content, i, i + 1) == flag then
            flag_pos = i
            break
        end
    end

    if flag_pos ~= nil and flag_pos > 0 then
        query = vim.fn.trim(string.sub(content, 1, flag_pos - 1))
        option = vim.fn.trim(string.sub(content, flag_pos + 2))
    else
        query = vim.fn.trim(content)
    end

    return { query, option }
end

-- parse query }

local M = {
    log_debug = log_debug,
    log_info = log_info,
    log_warn = log_warn,
    log_err = log_err,
    log_throw = log_throw,
    log_ensure = log_ensure,
    read_provider_command = read_provider_command,
    color_csi = csi,
    render_filepath_line = render_filepath_line,
    parse_query = parse_query,
    Command = require("fzfx.command").Command,
    GitRootCommand = require("fzfx.git_command_helpers").GitRootCommand,
    GitBranchCommand = require("fzfx.git_command_helpers").GitBranchCommand,
    GitCurrentBranchCommand = require("fzfx.git_command_helpers").GitCurrentBranchCommand,
}

return M
