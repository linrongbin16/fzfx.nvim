local log = require("fzfx.log")
local env = require("fzfx.env")
local utils = require("fzfx.utils")

local function skip_unmodifiable_window()
    local modifiable = "modifiable"
    local current_bufnr = vim.api.nvim_win_get_buf(0)
    log.debug(
        "|fzfx.action - skip_unmodifiable_window| current_bufnr:%s, valid:%s, modifiable:%s",
        vim.inspect(current_bufnr),
        vim.inspect(vim.api.nvim_buf_is_valid(current_bufnr)),
        vim.inspect(utils.get_buf_option(current_bufnr, modifiable))
    )
    if
        vim.api.nvim_buf_is_valid(current_bufnr)
        and utils.get_buf_option(current_bufnr, modifiable)
    then
        return
    end
    local all_windows = vim.api.nvim_tabpage_list_wins(0)
    log.debug(
        "|fzfx.action - skip_unmodifiable_window| all_windows:%s",
        vim.inspect(all_windows)
    )
    for _, winnr in ipairs(all_windows) do
        local bufnr = vim.api.nvim_win_get_buf(winnr)
        log.debug(
            "|fzfx.action - skip_unmodifiable_window| winnr:%s, bufnr:%s, valid:%s, modifiable:%s",
            vim.inspect(winnr),
            vim.inspect(bufnr),
            vim.inspect(vim.api.nvim_buf_is_valid(bufnr)),
            vim.inspect(utils.get_buf_option(bufnr, modifiable))
        )
        if
            vim.api.nvim_buf_is_valid(bufnr)
            and utils.get_buf_option(bufnr, modifiable)
        then
            vim.api.nvim_set_current_win(winnr)
            return
        end
    end
end

local function no_action(lines)
    log.debug("|fzfx.action - exit| lines:%s", vim.inspect(lines))
end

local function edit(lines)
    log.debug("|fzfx.action - edit| lines:%s", vim.inspect(lines))
    for i, line in ipairs(lines) do
        local filename = env.icon_enable() and vim.fn.split(line)[2] or line
        local cmd = string.format("edit %s", vim.fn.expand(filename))
        skip_unmodifiable_window()
        log.debug("|fzfx.action - edit| line[%d] cmd:%s", i, vim.inspect(cmd))
        vim.cmd(cmd)
    end
end

local function edit_rg(lines)
    log.debug("|fzfx.action - edit_rg| lines:%s", vim.inspect(lines))
    for i, line in ipairs(lines) do
        local splits = vim.fn.split(line, ":")
        local filename = env.icon_enable() and vim.fn.split(splits[1])[2]
            or splits[1]
        local row = tonumber(splits[2])
        local col = tonumber(splits[3])
        local edit_cmd = string.format("edit %s", vim.fn.expand(filename))
        local setpos_cmd =
            string.format("call setpos('.', [0, %d, %d])", row, col)
        log.debug(
            "|fzfx.action - edit_rg| line[%d] - splits:%s, filename:%s, row:%d, col:%d",
            i,
            vim.inspect(splits),
            vim.inspect(filename),
            vim.inspect(row),
            vim.inspect(col)
        )
        log.debug(
            "|fzfx.action - edit_rg| line[%d] - edit_cmd:%s, setpos_cmd:%s",
            i,
            vim.inspect(edit_cmd),
            vim.inspect(setpos_cmd)
        )
        skip_unmodifiable_window()
        vim.cmd(edit_cmd)
        if i == #lines then
            vim.cmd(setpos_cmd)
        end
    end
end

local M = {
    no_action = no_action,
    edit = edit,
    edit_rg = edit_rg,
}

return M
