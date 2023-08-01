local log = require("fzfx.log")
local conf = require("fzfx.config")

--- @alias BufNr integer
--- @alias WinNr integer
--- @alias JobId integer

--- @return table<"bufnr"|"winnr", BufNr|WinNr>
local function create_window()
    --- @type Config
    local win_configs = conf.get_config().win_opts

    --- @type integer
    local columns = vim.o.columns
    --- @type integer
    local lines = vim.o.lines

    --- @type integer
    local width = math.min(
        math.max(
            3,
            win_configs.width > 1 and win_configs.width
                or math.floor(columns * win_configs.width)
        ),
        columns
    )
    --- @type integer
    local height = math.min(
        math.max(
            3,
            win_configs.height > 1 and win_configs.height
                or math.floor(lines * win_configs.height)
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

    --- @type Config
    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        -- start point on NW
        row = row,
        col = col,
        style = "minimal",
    }

    --- @type BufNr
    local bufnr = vim.api.nvim_create_buf(false, true)
    --- @type WinNr
    local winnr = vim.api.nvim_open_win(bufnr, true, win_opts)
    vim.cmd(
        string.format(
            "silent! call setwinvar(%d, '&winhighlight', 'Pmenu:,Normal:Normal')",
            winnr
        )
    )
    vim.fn.setwinvar(winnr, "&colorcolumn", "")

    return {
        bufnr = bufnr,
        winnr = winnr,
    }
end

--- @param command string[]|string
--- @return JobId
local function create_terminal(command)
    local popup_win = create_window()

    local function on_fzf_exit(jobid, exitcode, event)
        log.debug(
            "|fzfx.term - create_terminal| jobid:%s, exitcode:%s, event:%s",
            vim.inspect(jobid),
            vim.inspect(exitcode),
            vim.inspect(event)
        )
    end

    local job =
        vim.api.nvim_open_term(popup_win.bufnr, { on_exit = on_fzf_exit }) --[[@as integer ]]
    vim.cmd([[ 
      setlocal nospell bufhidden=wipe nobuflisted nonumber
      setf fzf
      startinsert
    ]])
    return job
end

local function setup() end

local M = {
    create_terminal = create_terminal,
    setup = setup,
}

return M
