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
        local cmd = string.format("edit %s", vim.fn.expand(filename))
        log.debug(
            "|fzfx.action - edit_rg| line[%d] - splits:%s, filename:%s, cmd:%s",
            i,
            vim.inspect(splits),
            vim.inspect(filename),
            vim.inspect(cmd)
        )
        vim.cmd(cmd)
    end
end

local M = {
    edit = edit,
    edit_rg = edit_rg,
}

return M
