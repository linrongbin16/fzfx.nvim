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

--- @param popup_win PopupWindow
--- @param source string
--- @return PopupFzf
local function new_popup_fzf(popup_win, source, fzf_opts)
    local result_temp = path.tempname()

    local merged_opts = vim.deepcopy(conf.get_config().fzf_opts)
    for _, o in ipairs(fzf_opts) do
        table.insert(merged_opts, o)
    end
    local fzf_exec = vim.fn["fzf#exec"]()
    local fzf_command = string.format(
        'sh -c "%s" | %s %s >%s',
        source,
        fzf_exec,
        table.concat(merged_opts, " "),
        result_temp
    )
    log.debug(
        "|fzfx.popup - new_popup_fzf| fzf_command:%s",
        vim.inspect(fzf_command)
    )

    local function on_fzf_exit(jobid2, exitcode, event)
        log.debug(
            "|fzfx.popup - new_popup_fzf.on_fzf_exit| jobid2:%s, exitcode:%s, event:%s",
            vim.inspect(jobid2),
            vim.inspect(exitcode),
            vim.inspect(event)
        )
        if exitcode == 130 then
            return
        elseif vim.fn.has("nvim") > 0 and exitcode == 129 then
            return
        elseif exitcode > 1 then
            log.err(
                "error! command %s running with exit code %d",
                fzf_command,
                exitcode
            )
        end
    end
    local function on_fzf_stdout(chanid, data, name)
        log.debug(
            "|fzfx.popup - new_popup_fzf.on_fzf_stdout| chanid:%s, data:%s, name:%s",
            vim.inspect(chanid),
            vim.inspect(data),
            vim.inspect(name)
        )
    end
    local function on_fzf_stderr(chanid, data, name)
        log.debug(
            "|fzfx.popup - new_popup_fzf.on_fzf_stderr| chanid:%s, data:%s, name:%s",
            vim.inspect(chanid),
            vim.inspect(data),
            vim.inspect(name)
        )
    end
    local jobid = vim.fn.termopen(fzf_command, {
        on_exit = on_fzf_exit,
        on_stdout = on_fzf_stdout,
        on_stderr = on_fzf_stderr,
    }) --[[@as integer ]]
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
