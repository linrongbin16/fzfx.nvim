local log = require("fzfx.log")
local conf = require("fzfx.config")
local utils = require("fzfx.utils")
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")

--- @class PopupWindow
--- @field window_opts_context WindowOptsContext?
--- @field bufnr integer|nil
--- @field winnr integer|nil
local PopupWindow = {
    window_opts_context = nil,
    bufnr = nil,
    winnr = nil,
}

--- @class PopupWindowOpts
--- @field relative "editor"|"win"|nil
--- @field width integer|nil
--- @field height integer|nil
--- @field row integer|nil
--- @field col integer|nil
--- @field style "minimal"|nil
--- @field border "none"|"single"|"double"|"rounded"|"solid"|"shadow"|nil
--- @field zindex integer|nil
local PopupWindowOpts = {
    relative = nil,
    width = nil,
    height = nil,
    row = nil,
    col = nil,
    style = nil,
    border = nil,
    zindex = nil,
}

local function safe_range(left, value, right)
    return math.min(math.max(left, value), right)
end

--- @param win_opts Configs
--- @return PopupWindowOpts
local function make_popup_window_opts(win_opts)
    --- @type integer
    local columns = vim.o.columns
    --- @type integer
    local lines = vim.o.lines
    --- @type integer
    local width = safe_range(
        3,
        win_opts.width > 1 and win_opts.width
            or math.floor(columns * win_opts.width),
        columns
    )
    --- @type integer
    local height = safe_range(
        3,
        win_opts.height > 1 and win_opts.height
            or math.floor(lines * win_opts.height),
        lines
    )
    --- @type integer
    local row = nil
    if
        (win_opts.row > -1 and win_opts.row < -0.5)
        or (win_opts.row > 0.5 and win_opts.row < 1)
    then
        log.throw(
            "error! invalid option win_opts.row '%s'!",
            vim.inspect(win_opts.row)
        )
    else
        local base_row = math.floor((lines - height) * 0.5)
        if win_opts.row >= 0 then
            local shift_row = win_opts.row < 1
                    and math.floor((lines - height) * win_opts.row)
                or win_opts.row
            row = safe_range(0, base_row + shift_row, lines - height)
        else
            local shift_row = win_opts.row > -1
                    and math.ceil((lines - height) * win_opts.row)
                or win_opts.row
            row = safe_range(0, base_row + shift_row, lines - height)
        end
    end
    --- @type integer
    local col = nil
    if
        (win_opts.col > -1 and win_opts.col < -0.5)
        or (win_opts.col > 0.5 and win_opts.col < 1)
    then
        log.throw(
            "error! invalid option win_opts.col '%s'!",
            vim.inspect(win_opts.col)
        )
    else
        local base_col = math.floor((columns - width) * 0.5)
        if win_opts.col >= 0 then
            local shift_col = win_opts.col < 1
                    and math.floor((columns - width) * win_opts.col)
                or win_opts.col
            col = safe_range(0, base_col + shift_col, columns - width)
        else
            local shift_col = win_opts.col > -1
                    and math.ceil((columns - width) * win_opts.col)
                or win_opts.col
            col = safe_range(0, base_col + shift_col, columns - width)
        end
    end

    --- @type PopupWindowOpts
    local popup_window_opts =
        vim.tbl_deep_extend("force", vim.deepcopy(PopupWindowOpts), {
            anchor = "NW",
            relative = "editor",
            width = width,
            height = height,
            -- start point on NW
            row = row,
            col = col,
            style = "minimal",
            border = win_opts.border,
            zindex = win_opts.zindex,
        })
    log.debug(
        "|fzfx.popup - make_popup_window_opts| (origin) win_opts:%s, popup_win_opts:%s",
        vim.inspect(win_opts),
        vim.inspect(popup_window_opts)
    )
    return popup_window_opts
end

--- @param win_opts PopupWindowOpts?
--- @return PopupWindow
function PopupWindow:new(win_opts)
    -- check executable: nvim, fzf
    require("fzfx.shell").nvim_exec()
    require("fzfx.shell").fzf_exec()

    -- save current window context
    local window_opts_context = utils.WindowOptsContext:save()

    -- local win_stack = get_window_context_stack() --[[@as WindowContextStack]]
    -- assert(
    --     win_stack ~= nil,
    --     "|fzfx.popup - new_popup_window| win_stack cannot be nil"
    -- )
    -- win_stack:push()

    --- @type integer
    local bufnr = vim.api.nvim_create_buf(false, true)
    -- setlocal bufhidden=wipe nobuflisted
    -- setft=fzf
    utils.set_buf_option(bufnr, "bufhidden", "wipe")
    utils.set_buf_option(bufnr, "buflisted", false)
    utils.set_buf_option(bufnr, "filetype", "fzf")

    --- @type PopupWindowOpts
    local merged_win_opts = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(conf.get_config().popup.win_opts),
        vim.deepcopy(win_opts) or {}
    )
    local popup_opts = make_popup_window_opts(merged_win_opts)

    --- @type integer
    local winnr = vim.api.nvim_open_win(bufnr, true, popup_opts)

    --- setlocal nospell nonumber
    --- set winhighlight='Pmenu:,Normal:Normal'
    --- set colorcolumn=''
    utils.set_win_option(winnr, "spell", false)
    utils.set_win_option(winnr, "number", false)
    utils.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
    utils.set_win_option(winnr, "colorcolumn", "")

    --- @type PopupWindow
    local pw = vim.tbl_deep_extend("force", vim.deepcopy(PopupWindow), {
        window_opts_context = window_opts_context,
        bufnr = bufnr,
        winnr = winnr,
    })

    return pw
end

function PopupWindow:close()
    log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

    if vim.api.nvim_win_is_valid(self.winnr) then
        vim.api.nvim_win_close(self.winnr, true)
    else
        log.debug(
            "error! cannot close invalid popup window! %s",
            vim.inspect(self.winnr)
        )
    end

    ---@diagnostic disable-next-line: undefined-field
    self.window_opts_context:restore()
end

--- @class Popup
--- @field popup_window PopupWindowOpts?
--- @field source string|string[]|nil
--- @field jobid integer|nil
--- @field result string|nil
local Popup = {
    popup_window = nil,
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

--- @alias OnPopupExit fun(launch:Popup):nil

--- @param win_opts PopupWindowOpts?
--- @param source string
--- @param fzf_opts Configs
--- @param actions Configs
--- @param on_launch_exit OnPopupExit|nil
--- @return Popup
function Popup:new(win_opts, source, fzf_opts, actions, on_launch_exit)
    local result = vim.fn.tempname()
    local fzf_command = make_fzf_command(fzf_opts, actions, result)
    local popup_window = PopupWindow:new(win_opts)

    local function on_fzf_exit(jobid2, exitcode, event)
        log.debug(
            "|fzfx.popup - Popup:new.on_fzf_exit| jobid2:%s, exitcode:%s, event:%s",
            vim.inspect(jobid2),
            vim.inspect(exitcode),
            vim.inspect(event)
        )
        if exitcode > 1 and (exitcode ~= 130 and exitcode ~= 129) then
            log.err(
                "command '%s' running with exit code %d",
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
        popup_window:close()

        -- -- press <ESC> if in insert mode
        -- vim.api.nvim_feedkeys(esc_key, "x", false)

        log.ensure(
            vim.fn.filereadable(result) > 0,
            "|fzfx.popup - Popup:new.on_fzf_exit| error! result %s must be readable",
            vim.inspect(result)
        )
        local result_lines = vim.fn.readfile(result)
        log.debug(
            "|fzfx.popup - Popup:new.on_fzf_exit| result:%s, result_lines:%s",
            vim.inspect(result),
            vim.inspect(result_lines)
        )
        local action_key = vim.fn.trim(result_lines[1])
        local action_lines = vim.list_slice(result_lines, 2)
        log.debug(
            "|fzfx.popup - Popup:new.on_fzf_exit| action_key:%s, action_lines:%s",
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

    -- save shell opts
    local shell_opts_context = utils.ShellOptsContext:save()
    local prev_fzf_default_opts = vim.env.FZF_DEFAULT_OPTS
    local prev_fzf_default_command = vim.env.FZF_DEFAULT_COMMAND
    vim.env.FZF_DEFAULT_OPTS = helpers.make_fzf_default_opts()
    vim.env.FZF_DEFAULT_COMMAND = source
    log.debug(
        "|fzfx.popup - Popup:new| $FZF_DEFAULT_OPTS:%s",
        vim.inspect(vim.env.FZF_DEFAULT_OPTS)
    )
    log.debug(
        "|fzfx.popup - Popup:new| $FZF_DEFAULT_COMMAND:%s",
        vim.inspect(vim.env.FZF_DEFAULT_COMMAND)
    )
    log.debug(
        "|fzfx.popup - Popup:new| fzf_command:%s",
        vim.inspect(fzf_command)
    )

    -- launch
    local jobid = vim.fn.termopen(fzf_command, { on_exit = on_fzf_exit }) --[[@as integer ]]

    -- restore shell opts
    shell_opts_context:restore()
    vim.env.FZF_DEFAULT_COMMAND = prev_fzf_default_command
    vim.env.FZF_DEFAULT_OPTS = prev_fzf_default_opts

    vim.cmd([[ startinsert ]])

    --- @type Popup
    local p = vim.tbl_deep_extend("force", vim.deepcopy(Popup), {
        popup_window = popup_window,
        source = source,
        jobid = jobid,
        result = result,
    })

    return p
end

function Popup:close()
    log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))
end

local M = {
    Popup = Popup,
}

return M
