local log = require("fzfx.log")

local function open_buffer(lines)
    log.debug("|fzfx.action - open_buffer| lines:%s", vim.inspect(lines))
end

local M = {
    open_buffer = open_buffer,
}

return M
