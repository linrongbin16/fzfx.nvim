local log = require("fzfx.log")
local conf = require("fzfx.config")

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
local PopupWindowLayout = {}

--- @param win_height number
--- @param win_width number
local function new_popup_window_layout(win_height, win_width)
    --- @type integer
    local columns = vim.o.columns
    --- @type integer
    local lines = vim.o.lines
    --- @type integer
    local width = math.min(
        math.max(
            3,
            win_width > 1 and win_width or math.floor(columns * win_width)
        ),
        columns
    )
    --- @type integer
    local height = math.min(
        math.max(
            3,
            win_height > 1 and win_height or math.floor(lines * win_height)
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

    local win_layout = new_popup_window_layout(win_opts.height, win_opts.width)
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

function PopupWindow:close() end

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

--- @param popup_win PopupWindow
--- @param source string|string[]
--- @return PopupFzf
local function new_popup_fzf(popup_win, source)
    local function on_fzf_exit(jobid2, exitcode, event)
        log.debug(
            "|fzfx.term - create_terminal| jobid2:%s, exitcode:%s, event:%s",
            vim.inspect(jobid2),
            vim.inspect(exitcode),
            vim.inspect(event)
        )
    end

    local jobid =
        vim.api.nvim_open_term(popup_win.bufnr, { on_exit = on_fzf_exit }) --[[@as integer ]]
    -- startinsert
    vim.api.nvim_buf_call(popup_win.bufnr, function()
        vim.cmd([[ startinsert ]])
    end)

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
