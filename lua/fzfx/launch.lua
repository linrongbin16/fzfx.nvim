local log = require("fzfx.log")
local conf = require("fzfx.config")
local path = require("fzfx.path")
local shell = require("fzfx.shell")

--- @class Launch
--- @field popup Popup|nil
--- @field source string|string[]|nil
--- @field jobid integer|nil
--- @field result string|nil
local Launch = {
    popup = nil,
    source = nil,
    jobid = nil,
    result = nil,
}

--- @param actions table<string, any>
--- @return string[][]
local function make_expect_keys(actions)
    local expect_keys = {}
    if type(actions) == "table" then
        for name, _ in pairs(actions) do
            table.insert(expect_keys, { "--expect", name })
        end
    end
    return expect_keys
end

--- @param fzf_opts string[]|string[][]
--- @param actions table<string, any>
--- @return string[]
local function merge_fzf_opts(fzf_opts, actions)
    local expect_keys = make_expect_keys(actions)
    local merged_opts = vim.list_extend(vim.deepcopy(fzf_opts), expect_keys)
    log.debug(
        "|fzfx.popup - merge_fzf_opts| fzf_opts:%s, actions:%s, merged_opts:%s",
        vim.inspect(fzf_opts),
        vim.inspect(actions),
        vim.inspect(merged_opts)
    )
    return merged_opts
end

--- @param fzf_opts Config
--- @param actions Config
--- @param result string
--- @return string
local function make_fzf_command(fzf_opts, actions, result)
    fzf_opts = merge_fzf_opts(fzf_opts, actions)

    local fzf_path = shell.fzf_exec()
    local builder = {}
    for _, opt in ipairs(fzf_opts) do
        if type(opt) == "table" and #opt == 2 then
            local key = opt[1]
            local value = opt[2]
            table.insert(
                builder,
                string.format("%s %s", key, vim.fn.shellescape(value))
            )
        elseif type(opt) == "string" then
            table.insert(builder, opt)
        else
            log.err("error! invalid fzf opt '%s'!", vim.inspect(opt))
        end
    end
    log.debug(
        "|fzfx.popup - make_fzf_command| fzf_opts:%s, builder:%s",
        vim.inspect(fzf_opts),
        vim.inspect(builder)
    )
    local command =
        string.format("%s %s >%s", fzf_path, table.concat(builder, " "), result)
    log.debug(
        "|fzfx.popup - make_fzf_command| command:%s",
        vim.inspect(command)
    )
    return command
end

--- @param popup Popup
--- @param source string
--- @param fzf_opts Config
--- @param actions Config
--- @return Launch
function Launch:new(popup, source, fzf_opts, actions)
    local result = path.tempname()
    local fzf_command = make_fzf_command(fzf_opts, actions, result)

    local function on_fzf_exit(jobid2, exitcode, event)
        log.debug(
            "|fzfx.popup - Launch:new.on_fzf_exit| jobid2:%s, exitcode:%s, event:%s",
            vim.inspect(jobid2),
            vim.inspect(exitcode),
            vim.inspect(event)
        )
        if exitcode > 1 and (exitcode ~= 130 and exitcode ~= 129) then
            log.err(
                "error! command %s running with exit code %d",
                fzf_command,
                exitcode
            )
            return
        end
        if vim.o.buftype == "terminal" and vim.o.filetype == "fzf" then
            vim.api.nvim_feedkeys("i", "m", false)
        end
        vim.api.nvim_win_close(popup.winnr, true)
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
        vim.api.nvim_feedkeys(esc, "x", false)

        -- local saved_win_context = get_window_context_stack():pop()
        -- log.debug(
        --     "|fzfx.popup - Launch:new.on_fzf_exit| saved_win_context:%s",
        --     vim.inspect(saved_win_context)
        -- )
        -- if saved_win_context then
        --     vim.api.nvim_set_current_win(saved_win_context.winnr)
        -- end

        assert(
            vim.fn.filereadable(result) > 0,
            string.format(
                "|fzfx.popup - Launch:new.on_fzf_exit| error! result %s must be readable",
                vim.inspect(result)
            )
        )
        local result_lines = vim.fn.readfile(result)
        log.debug(
            "|fzfx.popup - Launch:new.on_fzf_exit| result:%s, result_lines:%s",
            vim.inspect(result),
            vim.inspect(result_lines)
        )
        local action_key = vim.fn.trim(result_lines[1])
        local action_lines = vim.list_slice(result_lines, 2)
        log.debug(
            "|fzfx.popup - Launch:new.on_fzf_exit| action_key:%s, action_lines:%s",
            vim.inspect(action_key),
            vim.inspect(action_lines)
        )
        if type(action_key) == "string" and string.len(action_key) == 0 then
            action_key = "enter"
        end
        if not tostring(action_key):match("v:null") then
            local action_callback = actions[action_key]
            if type(action_callback) ~= "function" then
                log.err("error! wrong action type: %s", action_key)
            else
                action_callback(action_lines)
            end
        end
    end
    local prev_fzf_default_command = vim.env.FZF_DEFAULT_COMMAND
    vim.env.FZF_DEFAULT_COMMAND = source
    log.debug(
        "|fzfx.popup - Launch:new| $FZF_DEFAULT_OPTS:%s",
        vim.inspect(vim.env.FZF_DEFAULT_OPTS)
    )
    log.debug(
        "|fzfx.popup - Launch:new| $FZF_DEFAULT_COMMAND:%s",
        vim.inspect(vim.env.FZF_DEFAULT_COMMAND)
    )
    log.debug(
        "|fzfx.popup - Launch:new| fzf_command:%s",
        vim.inspect(fzf_command)
    )
    local jobid = vim.fn.termopen(fzf_command, { on_exit = on_fzf_exit }) --[[@as integer ]]
    vim.env.FZF_DEFAULT_COMMAND = prev_fzf_default_command
    vim.cmd([[ startinsert ]])

    --- @type Launch
    local popup_fzf = vim.tbl_deep_extend("force", vim.deepcopy(Launch), {
        popup_win = popup,
        source = source,
        jobid = jobid,
        result = result,
    })

    return popup_fzf
end

function Launch:close()
    log.debug("|fzfx.popup - Launch:close| self:%s", vim.inspect(self))
end

local M = {
    Launch = Launch,
}

return M
