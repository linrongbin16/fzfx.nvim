local log = require("fzfx.log")
local conf = require("fzfx.config")
local path = require("fzfx.path")

--- @alias BufId integer
--- @alias WinId integer
--- @alias JobId integer

--- @class PopupWindow
--- @field bufnr BufId|nil
--- @field winnr WinId|nil

--- @type PopupWindow
local PopupWindow = {
    bufnr = nil,
    winnr = nil,
}

--- @class PopupWindowLayout
--- @field relative "editor"|"win"
--- @field width integer
--- @field height integer
--- @field row integer
--- @field col integer
--- @field style "minimal"
--- @field border "none"|"single"|"double"|"rounded"|"solid"|"shadow"
--- @field zindex integer
local PopupWindowLayout = {}

--- @param win_opts Config
local function new_popup_window_layout(win_opts)
    --- @type integer
    local columns = vim.o.columns
    --- @type integer
    local lines = vim.o.lines
    --- @type integer
    local width = math.min(
        math.max(
            3,
            win_opts.width > 1 and win_opts.width
                or math.floor(columns * win_opts.width)
        ),
        columns
    )
    --- @type integer
    local height = math.min(
        math.max(
            3,
            win_opts.height > 1 and win_opts.height
                or math.floor(lines * win_opts.height)
        ),
        lines
    )
    --- @type integer
    local row =
        math.min(math.max(math.floor((lines - height) / 2), 0), lines - height)
    --- @type integer
    local col = math.min(
        math.max(math.floor((columns - width) / 2), 0),
        columns - width
    )

    --- @type PopupWindowLayout
    local win_layout =
        vim.tbl_deep_extend("force", vim.deepcopy(PopupWindowLayout), {
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
        "|fzfx.popup - new_window_layout| win_layout:%s",
        vim.inspect(win_layout)
    )
    return win_layout
end

--- @param win_opts Config
--- @return PopupWindow
local function new_popup_window(win_opts)
    --- @type BufId
    local bufnr = vim.api.nvim_create_buf(false, true)
    -- setlocal nospell bufhidden=wipe nobuflisted nonumber
    -- setft=fzf
    vim.api.nvim_set_option_value("spell", false, { buf = bufnr })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
    vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })
    vim.api.nvim_set_option_value("number", false, { buf = bufnr })
    vim.api.nvim_set_option_value("filetype", "fzf", { buf = bufnr })

    local win_layout = new_popup_window_layout(win_opts)
    --- @type WinId
    local winnr = vim.api.nvim_open_win(bufnr, true, win_layout)
    --- set winhighlight='Pmenu:,Normal:Normal'
    --- set colorcolumn=''
    vim.api.nvim_set_option_value(
        "winhighlight",
        "Pmenu:,Normal:Normal",
        { win = winnr }
    )
    vim.api.nvim_set_option_value("colorcolumn", "", { win = winnr })

    --- @type PopupWindow
    local popup_win = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(PopupWindow),
        { bufnr = bufnr, winnr = winnr }
    )

    return popup_win
end

function PopupWindow:close()
    log.debug(
        "|fzfx.popup - PopupWindow:close| bufnr:%s, winnr:%s",
        vim.inspect(self.bufnr),
        vim.inspect(self.winnr)
    )
end

--- @class PopupFzf
--- @field popup_win PopupWindow|nil
--- @field source string|string[]|nil
--- @field jobid JobId|nil

--- @type PopupFzf
local PopupFzf = {
    popup_win = nil,
    source = nil,
    jobid = nil,
}

function PopupFzf:close()
    log.debug(
        "|fzfx.popup - PopupFzf:close| popup_win:%s, source:%s, jobid:%s",
        vim.inspect(self.popup_win),
        vim.inspect(self.source),
        vim.inspect(self.jobid)
    )
end

--- @param actions Config
local function make_expect_keys(actions)
    local expect_keys = {}
    if type(actions) == "table" then
        for name, _ in pairs(actions) do
            table.insert(expect_keys, { "--expect", name })
        end
    end
    return expect_keys
end

--- @param fzf_opts Config
--- @param actions Config
--- @param result_temp any
local function make_fzf_command(fzf_opts, actions, result_temp)
    local base_opts = vim.deepcopy(conf.get_config().fzf.opts)
    local expect_keys = make_expect_keys(actions)
    fzf_opts = vim.list_extend(base_opts, fzf_opts)
    fzf_opts = vim.list_extend(fzf_opts, expect_keys)

    local fzf_exec = vim.fn["fzf#exec"]()
    local builder = {}
    for _, opt in ipairs(fzf_opts) do
        if type(opt) == "table" then
            local key = opt[1]
            local value = opt[2]
            table.insert(
                builder,
                string.format("%s %s", key, vim.fn.shellescape(value))
            )
        else
            table.insert(builder, opt)
        end
    end
    log.debug(
        "|fzfx.popup - make_fzf_command| fzf_opts:%s, builder:%s",
        vim.inspect(fzf_opts),
        vim.inspect(builder)
    )
    local command = string.format(
        "%s %s >%s",
        fzf_exec,
        table.concat(builder, " "),
        result_temp
    )
    log.debug(
        "|fzfx.popup - make_fzf_command| command:%s",
        vim.inspect(command)
    )
    return command
end

--- @param popup_win PopupWindow
--- @param source string
--- @param fzf_opts Config
--- @param actions Config
--- @return PopupFzf
local function new_popup_fzf(popup_win, source, fzf_opts, actions)
    local result_temp = path.tempname()

    local fzf_command = make_fzf_command(fzf_opts, actions, result_temp)
    local term_command = string.format("%s | %s", source, fzf_command)
    log.debug(
        "|fzfx.popup - new_popup_fzf| term_command:%s",
        vim.inspect(term_command)
    )

    local function feed_terminal_exit()
        if vim.o.buftype == "terminal" then
            vim.fn.feedkeys(vim.o.filetype == "fzf" and "i" or "<Nop>")
        end
    end

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
                term_command,
                exitcode
            )
        else
            feed_terminal_exit()
        end

        if vim.fn.filereadable(result_temp) > 0 then
            local result_lines = vim.fn.readfile(result_temp)
            log.debug(
                "|fzfx.popup - new_popup_fzf.on_fzf_exit| found result tempfile:%s, result_lines:%s",
                vim.inspect(result_temp),
                vim.inspect(result_lines)
            )
            local action = result_lines[1]
            local lines = result_lines[1]
        end
    end
    local jobid = vim.fn.termopen(term_command, { on_exit = on_fzf_exit }) --[[@as integer ]]
    vim.cmd([[ startinsert ]])

    --- @type PopupFzf
    local popup_fzf = vim.tbl_deep_extend(
        "force",
        vim.deepcopy(PopupFzf),
        { popup_win = popup_win, source = source, jobid = jobid }
    )

    return popup_fzf
end

local function setup() end

local M = {
    new_popup_window = new_popup_window,
    new_popup_fzf = new_popup_fzf,
    setup = setup,
}

return M
