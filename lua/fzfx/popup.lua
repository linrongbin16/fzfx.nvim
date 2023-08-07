local log = require("fzfx.log")
local conf = require("fzfx.config")
local path = require("fzfx.path")
local shell = require("fzfx.shell")

-- --- @class WindowContext
-- --- @field bufnr integer|nil
-- --- @field winnr integer|nil
-- --- @field tabnr integer|nil
--
-- --- @type WindowContext
-- local WindowContext = {
--     bufnr = nil,
--     winnr = nil,
--     tabnr = nil,
-- }
--
-- --- @param bufnr integer
-- --- @param winnr integer
-- --- @param tabnr integer
-- --- @return WindowContext
-- local function new_window_context(bufnr, winnr, tabnr)
--     local ctx = vim.tbl_deep_extend("force", vim.deepcopy(WindowContext), {
--         bufnr = bufnr,
--         winnr = winnr,
--         tabnr = tabnr,
--     })
--     return ctx
-- end
--
-- -- First in, last out
-- -- Last in, first out
-- --- @class WindowContextStack
-- --- @field size integer
-- --- @field stack WindowContext[]
-- local WindowContextStack = {
--     size = 0,
--     stack = {},
-- }
--
-- function WindowContextStack:push()
--     local current_bufnr = vim.api.nvim_get_current_buf()
--     local current_winnr = vim.api.nvim_get_current_win()
--     local current_tabnr = vim.api.nvim_get_current_tabpage()
--     local ctx = new_window_context(current_bufnr, current_winnr, current_tabnr)
--     table.insert(self.stack, ctx)
--     self.size = self.size + 1
--     log.debug(
--         "|fzfx.popup - WindowContextStack:push| self:%s",
--         vim.inspect(self)
--     )
--     return ctx
-- end
--
-- function WindowContextStack:top()
--     if self.size <= 0 then
--         return nil
--     end
--     return self.stack[self.size]
-- end
--
-- function WindowContextStack:pop()
--     if self.size <= 0 then
--         return nil
--     end
--     local top = self:top()
--     table.remove(self.stack)
--     self.size = self.size - 1
--     return top
-- end
--
-- local Context = {
--     window_context_stack = nil,
-- }
--
-- local function get_window_context_stack()
--     if Context.window_context_stack == nil then
--         Context.window_context_stack =
--             vim.tbl_deep_extend("force", vim.deepcopy(WindowContextStack), {
--                 size = 0,
--                 stack = {},
--             })
--     end
--     return Context.window_context_stack
-- end

--- @class Popup
--- @field bufnr integer|nil
--- @field winnr integer|nil
local Popup = {
    bufnr = nil,
    winnr = nil,
}

--- @class PopupOpts
--- @field relative "editor"|"win"|nil
--- @field width integer|nil
--- @field height integer|nil
--- @field row integer|nil
--- @field col integer|nil
--- @field style "minimal"|nil
--- @field border "none"|"single"|"double"|"rounded"|"solid"|"shadow"|nil
--- @field zindex integer|nil
local PopupOpts = {
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

--- @param win_opts Config
--- @return PopupOpts
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

    --- @type PopupOpts
    local popup_win_opts =
        vim.tbl_deep_extend("force", vim.deepcopy(PopupOpts), {
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
        vim.inspect(popup_win_opts)
    )
    return popup_win_opts
end

--- @param win_opts PopupOpts|nil
--- @return Popup
function Popup:new(win_opts)
    -- check executable: nvim, fzf
    require("fzfx.shell").nvim_exec()
    require("fzfx.shell").fzf_exec()

    -- local win_stack = get_window_context_stack() --[[@as WindowContextStack]]
    -- assert(
    --     win_stack ~= nil,
    --     "|fzfx.popup - new_popup_window| win_stack cannot be nil"
    -- )
    -- win_stack:push()

    --- @type integer
    local bufnr = vim.api.nvim_create_buf(false, true)
    -- setlocal nospell bufhidden=wipe nobuflisted nonumber
    -- setft=fzf
    vim.api.nvim_set_option_value("spell", false, { buf = bufnr })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
    vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })
    vim.api.nvim_set_option_value("number", false, { buf = bufnr })
    vim.api.nvim_set_option_value("filetype", "fzf", { buf = bufnr })

    --- @type PopupOpts
    local merged_win_opts = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(conf.get_config().win_opts),
        vim.deepcopy(win_opts) or {}
    )
    local popup_win_opts = make_popup_window_opts(merged_win_opts)

    --- @type integer
    local winnr = vim.api.nvim_open_win(bufnr, true, popup_win_opts)

    --- set winhighlight='Pmenu:,Normal:Normal'
    --- set colorcolumn=''
    vim.api.nvim_set_option_value(
        "winhighlight",
        "Pmenu:,Normal:Normal",
        { win = winnr }
    )
    vim.api.nvim_set_option_value("colorcolumn", "", { win = winnr })

    --- @type Popup
    local ppp = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(Popup),
        { bufnr = bufnr, winnr = winnr }
    )

    return ppp
end

function Popup:close()
    log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))
    vim.api.nvim_win_close(self.winnr, true)
end

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

function Launch:close()
    log.debug("|fzfx.popup - Launch:close| self:%s", vim.inspect(self))
end

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
    local base_fzf_opts = conf.get_config().fzf_opts
    local expect_keys = make_expect_keys(actions)
    local merged_opts =
        vim.list_extend(vim.deepcopy(base_fzf_opts), vim.deepcopy(fzf_opts))
    merged_opts = vim.list_extend(merged_opts, expect_keys)
    log.debug(
        "|fzfx.popup - merge_fzf_opts| base_fzf_opts:%s, fzf_opts:%s, actions:%s, merged_opts:%s",
        vim.inspect(base_fzf_opts),
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

--- @param popup_win Popup
--- @param source string
--- @param fzf_opts Config
--- @param actions Config
--- @return Launch
local function new_popup_fzf(popup_win, source, fzf_opts, actions)
    local result = path.tempname()
    local fzf_command = make_fzf_command(fzf_opts, actions, result)

    local function on_fzf_exit(jobid2, exitcode, event)
        log.debug(
            "|fzfx.popup - new_popup_fzf.on_fzf_exit| jobid2:%s, exitcode:%s, event:%s",
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
        vim.api.nvim_win_close(popup_win.winnr, true)
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
        vim.api.nvim_feedkeys(esc, "x", false)

        -- local saved_win_context = get_window_context_stack():pop()
        -- log.debug(
        --     "|fzfx.popup - new_popup_fzf.on_fzf_exit| saved_win_context:%s",
        --     vim.inspect(saved_win_context)
        -- )
        -- if saved_win_context then
        --     vim.api.nvim_set_current_win(saved_win_context.winnr)
        -- end

        assert(
            vim.fn.filereadable(result) > 0,
            string.format(
                "|fzfx.popup - new_popup_fzf.on_fzf_exit| result %s must be readable",
                vim.inspect(result)
            )
        )
        local result_lines = vim.fn.readfile(result)
        log.debug(
            "|fzfx.popup - new_popup_fzf.on_fzf_exit| result:%s, result_lines:%s",
            vim.inspect(result),
            vim.inspect(result_lines)
        )
        local action_key = vim.fn.trim(result_lines[1])
        local action_lines = vim.list_slice(result_lines, 2)
        log.debug(
            "|fzfx.popup - new_popup_fzf.on_fzf_exit| action_key:%s, action_lines:%s",
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
        "|fzfx.popup - new_popup_fzf| $FZF_DEFAULT_COMMAND:%s",
        vim.inspect(vim.env.FZF_DEFAULT_COMMAND)
    )
    log.debug(
        "|fzfx.popup - new_popup_fzf| fzf_command:%s",
        vim.inspect(fzf_command)
    )
    local jobid = vim.fn.termopen(fzf_command, { on_exit = on_fzf_exit }) --[[@as integer ]]
    vim.env.FZF_DEFAULT_COMMAND = prev_fzf_default_command
    vim.cmd([[ startinsert ]])

    --- @type Launch
    local popup_fzf = vim.tbl_deep_extend("force", vim.deepcopy(Launch), {
        popup_win = popup_win,
        source = source,
        jobid = jobid,
        result = result,
    })

    return popup_fzf
end

local function setup() end

local M = {
    Popup = Popup,
    new_popup_fzf = new_popup_fzf,
    setup = setup,
}

return M
