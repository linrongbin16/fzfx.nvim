local log = require("fzfx.log")

local function edit(lines)
    log.debug("|fzfx.action - edit| lines:%s", vim.inspect(lines))
    for i, line in ipairs(lines) do
        local cmd = string.format("edit %s", vim.fn.expand(line))
        log.debug("|fzfx.action - edit| line[%d] cmd:%s", i, vim.inspect(cmd))
        vim.cmd(cmd)
    end
end

local function edit_rg(lines)
    log.debug("|fzfx.action - edit_rg| lines:%s", vim.inspect(lines))
    for i, line in ipairs(lines) do
        local splits = vim.split(line, ":")
        local filename = splits[1]
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
        vim.cmd(setpos_cmd)
    end
end

local M = {
    edit = edit,
    edit_rg = edit_rg,
}

return M
