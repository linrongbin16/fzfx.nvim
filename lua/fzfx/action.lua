local log = require("fzfx.log")

local function edit(lines)
    log.debug("|fzfx.action - edit| lines:%s", vim.inspect(lines))
    for i, line in ipairs(lines) do
        local cmd = string.format("edit %s", vim.fn.expand(line))
        log.debug("|fzfx.action - edit| line[%d] cmd:%s", i, vim.inspect(cmd))
        vim.cmd(cmd)
    end
end

local M = {
    edit = edit,
}

return M
