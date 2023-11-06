local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels
local utils = require("fzfx.utils")

local user_cancelled_error = "cancelled."

--- @param bufnr integer
--- @param callback fun():any
local function confirm_discard_buffer_modified(bufnr, callback)
    if utils.get_buf_option(bufnr, "modified") then
        local input = vim.fn.input({
            prompt = "[fzfx] current buffer has been modified, continue? (y/n) ",
            cancelreturn = "n",
        })
        if
            type(input) == "string"
            and string.len(input) > 0
            and utils.string_startswith(input:lower(), "y")
        then
            callback()
        else
            log.echo(LogLevels.INFO, user_cancelled_error)
        end
    else
        callback()
    end
end

local M = {
    confirm_discard_buffer_modified = confirm_discard_buffer_modified,
}

return M
