local log = require("fzfx.log")

local function open_buffer(action, lines)
    log.debug(
        "|fzfx.action - open_buffer| action:%s, lines:%s",
        vim.inspect(action),
        vim.inspect(lines)
    )
end

local M = {
    open_buffer = open_buffer,
}

return M
