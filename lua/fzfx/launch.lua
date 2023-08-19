local constants = require("fzfx.constants")
local log = require("fzfx.log")
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local conf = require("fzfx.config")

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

--- @param fzf_opts Configs
--- @param actions Configs
--- @param result string
--- @return string
local function make_fzf_command(fzf_opts, actions, result)
    local final_opts = merge_fzf_opts(fzf_opts, actions)
    local final_opts_string = helpers.make_fzf_opts(final_opts)
    log.debug(
        "|fzfx.popup - make_fzf_command| final_opts:%s, builder:%s",
        vim.inspect(final_opts),
        vim.inspect(final_opts_string)
    )
    local command =
        string.format("%s %s >%s", shell.fzf_exec(), final_opts_string, result)
    log.debug(
        "|fzfx.popup - make_fzf_command| command:%s",
        vim.inspect(command)
    )
    return command
end

--- @class ShellOptsContext
--- @field shell string?
--- @field shellslash string?
--- @field shellcmdflag string?
--- @field shellxquote string?
--- @field shellquote string?
--- @field shellredir string?
--- @field shellpipe string?
--- @field shellxescape string?
local ShellOptsContext = {
    shell = nil,
    shellslash = nil,
    shellcmdflag = nil,
    shellxquote = nil,
    shellquote = nil,
    shellredir = nil,
    shellpipe = nil,
    shellxescape = nil,
}

--- @return ShellOptsContext
function ShellOptsContext:save()
    local ctx = vim.tbl_deep_extend("force", vim.deepcopy(ShellOptsContext), {
        shell = vim.o.shell,
        shellslash = vim.o.shellslash,
        shellcmdflag = vim.o.shellcmdflag,
        shellxquote = vim.o.shellxquote,
        shellquote = vim.o.shellquote,
        shellredir = vim.o.shellredir,
        shellpipe = vim.o.shellpipe,
        shellxescape = vim.o.shellxescape,
    })
    log.debug(
        "|fzfx.launch - ShellOptsContext:save| before, shell:%s, shellslash:%s, shellcmdflag:%s, shellxquote:%s, shellquote:%s, shellredir:%s, shellpipe:%s, shellxescape:%s",
        vim.inspect(vim.o.shell),
        vim.inspect(vim.o.shellslash),
        vim.inspect(vim.o.shellcmdflag),
        vim.inspect(vim.o.shellxquote),
        vim.inspect(vim.o.shellquote),
        vim.inspect(vim.o.shellredir),
        vim.inspect(vim.o.shellpipe),
        vim.inspect(vim.o.shellxescape)
    )

    if constants.is_windows then
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

    log.debug(
        "|fzfx.launch - ShellOptsContext:save| after, shell:%s, shellslash:%s, shellcmdflag:%s, shellxquote:%s, shellquote:%s, shellredir:%s, shellpipe:%s, shellxescape:%s",
        vim.inspect(vim.o.shell),
        vim.inspect(vim.o.shellslash),
        vim.inspect(vim.o.shellcmdflag),
        vim.inspect(vim.o.shellxquote),
        vim.inspect(vim.o.shellquote),
        vim.inspect(vim.o.shellredir),
        vim.inspect(vim.o.shellpipe),
        vim.inspect(vim.o.shellxescape)
    )
    return ctx
end

--- @return nil
function ShellOptsContext:restore()
    vim.o.shell = self.shell
    vim.o.shellslash = self.shellslash
    vim.o.shellcmdflag = self.shellcmdflag
    vim.o.shellxquote = self.shellxquote
    vim.o.shellquote = self.shellquote
    vim.o.shellredir = self.shellredir
    vim.o.shellpipe = self.shellpipe
    vim.o.shellxescape = self.shellxescape
end

--- @alias OnLaunchExit fun(launch:Launch):nil

--- @param popup Popup
--- @param source string
--- @param fzf_opts Configs
--- @param actions Configs
--- @param on_launch_exit OnLaunchExit|nil
--- @return Launch
function Launch:new(popup, source, fzf_opts, actions, on_launch_exit)
    local result = vim.fn.tempname()

    -- save shell opts
    local shell_opts = ShellOptsContext:save()
    local prev_fzf_default_opts = vim.env.FZF_DEFAULT_OPTS
    local prev_fzf_default_command = vim.env.FZF_DEFAULT_COMMAND
    vim.env.FZF_DEFAULT_OPTS = helpers.make_fzf_default_opts()
    vim.env.FZF_DEFAULT_COMMAND = source

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
                "error! command '%s' running with exit code %d",
                fzf_command,
                exitcode
            )
            return
        end

        local esc_key =
            vim.api.nvim_replace_termcodes("<ESC>", true, false, true)

        -- press <ESC> if still in fzf terminal
        if vim.o.buftype == "terminal" and vim.o.filetype == "fzf" then
            vim.api.nvim_feedkeys(esc_key, "x", false)
        end

        -- close popup window and restore old window
        popup:close()

        -- -- press <ESC> if in insert mode
        -- vim.api.nvim_feedkeys(esc_key, "x", false)

        log.ensure(
            vim.fn.filereadable(result) > 0,
            "|fzfx.popup - Launch:new.on_fzf_exit| error! result %s must be readable",
            vim.inspect(result)
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
        if actions[action_key] ~= nil then
            local action_callback = actions[action_key]
            if type(action_callback) ~= "function" then
                log.throw(
                    "error! wrong action type on key: %s, must be function(%s): %s",
                    vim.inspect(action_key),
                    type(action_callback),
                    vim.inspect(action_callback)
                )
            else
                action_callback(action_lines)
            end
        else
            log.throw("error! unknown action key: %s", vim.inspect(action_key))
        end
        if type(on_launch_exit) == "function" then
            on_launch_exit(self)
        end
    end

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

    -- launch
    local jobid = vim.fn.termopen(fzf_command, { on_exit = on_fzf_exit }) --[[@as integer ]]

    -- restore shell opts
    shell_opts:restore()
    vim.env.FZF_DEFAULT_COMMAND = prev_fzf_default_command
    vim.env.FZF_DEFAULT_OPTS = prev_fzf_default_opts

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
