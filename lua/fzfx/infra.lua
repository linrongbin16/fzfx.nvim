local log = require("fzfx.log")

--- @type boolean
local is_windows = vim.fn.has("win32") > 0 or vim.fn.has("win64") > 0
--- @type boolean
local is_macos = vim.fn.has("mac") > 0
--- @type string
local plugin_home = vim.fn["fzfx#nvim#plugin_home_dir"]()
--- @type string
local plugin_bin = is_windows and plugin_home .. "\\bin"
    or plugin_home .. "/bin"

--- @param path string
--- @return string
local function normalize_path(path)
    local result = path
    if string.match(path, "\\") then
        result, _ = string.gsub(path, "\\", "/")
    end
    return vim.fn.trim(result)
end

--- @alias VimScriptId string
--- @alias VimScriptPath string
--- @alias VimScriptIdInfoKey "script_id"|"script_path"
--- @alias VimScriptIdInfoValue VimScriptId|VimScriptPath
--- @alias VimScriptIdInfo table<VimScriptIdInfoKey, VimScriptIdInfoValue>
--- @param script_name string
--- @return VimScriptIdInfo
local function get_sinfo(script_name)
    local all_scripts = vim.fn.split(vim.fn.execute("scriptnames"), "\n")
    local matched_line = nil
    for _, line in ipairs(all_scripts) do
        local normalized = normalize_path(line)
        if string.find(string.lower(normalized), string.lower(script_name)) then
            if matched_line == nil then
                matched_line = normalized
                break
            end
        end
    end

    if matched_line == nil then
        return { script_id = nil, script_path = nil }
    end

    local split_matched = vim.fn.split(matched_line)
    if #split_matched ~= 2 then
        log.err(
            "|fzfx.infra| cannot parse matched script path: %s!",
            matched_line
        )
        return { script_id = nil, script_path = nil }
    end

    local first_entry = split_matched[1]
    local script_id = string.gsub(first_entry, ":", "")
    local script_path = split_matched[2]
    return { script_id = script_id, script_path = script_path }
end

--- @return VimScriptId|nil
local function get_fzf_autoload_sid()
    local fzf_autoload_path = "fzf.vim/autoload/fzf/vim.vim"
    local fzf_plugin_path = "fzf.vim/plugin/fzf.vim"

    -- first try autoload
    local autoload_sinfo1 = get_sinfo(fzf_autoload_path)
    if autoload_sinfo1.script_id ~= nil then
        return autoload_sinfo1.script_id
    end

    -- then try plugin
    local plugin_sinfo = get_sinfo(fzf_plugin_path)
    if plugin_sinfo.script_id == nil then
        log.throw(
            "|fzfx.infra| failed to find vimscript '%s'!",
            fzf_plugin_path
        )
        return nil
    end

    -- finally construct autoload by hand
    local plugin_path = plugin_sinfo.script_path
    local my_autoload_path = vim.fn.expand(
        string.sub(plugin_path, 1, #plugin_path - 15 + 1)
            .. "autoload/fzf/vim.vim"
    )
    log.debug(
        "|fzfx.infra| fzf_plugin_path:%s, fzf_autoload_path:%s",
        plugin_path,
        my_autoload_path
    )

    if vim.fn.filereadable(my_autoload_path) > 0 then
        vim.cmd('execute "source ' .. my_autoload_path .. '"')
    else
        log.throw(
            "|fzfx.infra| failed to load vimscript '%s'!",
            my_autoload_path
        )
        return nil
    end

    local autoload_sinfo2 = get_sinfo(fzf_autoload_path)
    if autoload_sinfo2.script_id == nil then
        log.throw(
            "|fzfx.infra| failed to find vimscript '%s' again!",
            fzf_autoload_path
        )
        return nil
    end

    return autoload_sinfo2.script_id
end

--- @param sid VimScriptId
--- @param func_name string
--- @return string
local function get_func_snr(sid, func_name)
    return string.format("<SNR>%s_%s", sid, func_name)
end

local fzf_autoload_sid = get_fzf_autoload_sid()
local action_for = get_func_snr(fzf_autoload_sid --[[@as string]], "action_for")
local magenta = get_func_snr(fzf_autoload_sid --[[@as string]], "magenta")
local red = get_func_snr(fzf_autoload_sid --[[@as string]], "red")
local green = get_func_snr(fzf_autoload_sid --[[@as string]], "green")
local blue = get_func_snr(fzf_autoload_sid --[[@as string]], "blue")
local yellow = get_func_snr(fzf_autoload_sid --[[@as string]], "yellow")
local cyan = get_func_snr(fzf_autoload_sid --[[@as string]], "cyan")
local bufopen = get_func_snr(fzf_autoload_sid --[[@as string]], "bufopen")

local M = {
    os = {
        is_windows = is_windows,
        is_macos = is_macos,
    },
    fs = {
        plugin_home = plugin_home,
        plugin_bin = plugin_bin,
    },
    func_snr = {
        magenta,
        red,
        green,
        blue,
        yellow,
        cyan,
        action_for,
        bufopen,
    },
}

log.debug("|fzfx.infra| %s", vim.inspect(M))

return M
