local log = require("fzfx.log")
local env = require("fzfx.env")

local function nop(lines)
    log.debug("|fzfx.action - nop| lines:%s", vim.inspect(lines))
end

local function edit(lines)
    log.debug("|fzfx.action - edit| lines:%s", vim.inspect(lines))
    for i, line in ipairs(lines) do
        local filename = env.icon_enable() and vim.fn.split(line)[2] or line
        local cmd = string.format("edit %s", vim.fn.expand(filename))
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
        vim.cmd(edit_cmd)
        if i == #lines then
            vim.cmd(setpos_cmd)
        end
    end
end

local function buffer(lines)
    log.debug("|fzfx.action - buffer| lines:%s", vim.inspect(lines))
    for i, line in ipairs(lines) do
        local filename = env.icon_enable() and vim.fn.split(line)[2] or line
        local cmd = string.format("buffer %s", vim.fn.expand(filename))
        log.debug("|fzfx.action - buffer| line[%d] cmd:%s", i, vim.inspect(cmd))
        vim.cmd(cmd)
    end
end

local function buffer_rg(lines)
    log.debug("|fzfx.action - buffer_rg| lines:%s", vim.inspect(lines))
    for i, line in ipairs(lines) do
        local splits = vim.fn.split(line, ":")
        local filename = env.icon_enable() and vim.fn.split(splits[1])[2]
            or splits[1]
        local row = tonumber(splits[2])
        local col = tonumber(splits[3])
        local buffer_cmd = string.format("buffer %s", vim.fn.expand(filename))
        local setpos_cmd =
            string.format("call setpos('.', [0, %d, %d])", row, col)
        log.debug(
            "|fzfx.action - buffer_rg| line[%d] - splits:%s, filename:%s, row:%d, col:%d",
            i,
            vim.inspect(splits),
            vim.inspect(filename),
            vim.inspect(row),
            vim.inspect(col)
        )
        log.debug(
            "|fzfx.action - buffer_rg| line[%d] - buffer_cmd:%s, setpos_cmd:%s",
            i,
            vim.inspect(buffer_cmd),
            vim.inspect(setpos_cmd)
        )
        vim.cmd(buffer_cmd)
        if i == #lines then
            vim.cmd(setpos_cmd)
        end
    end
end

local function bdelete(lines)
    if type(lines) == "table" and #lines > 0 then
        for _, line in ipairs(lines) do
            local bufname = env.icon_enable() and vim.fn.split(line)[2] or line
            vim.cmd(vim.fn.trim(string.format([[ bdelete %s ]], bufname)))
        end
    end
end

local function git_checkout(lines)
    log.debug("|fzfx.action - git_checkout| lines:%s", vim.inspect(lines))
end

local M = {
    nop = nop,
    edit = edit,
    edit_rg = edit_rg,
    buffer = buffer,
    buffer_rg = buffer_rg,
    bdelete = bdelete,
    git_checkout = git_checkout,
}

return M
