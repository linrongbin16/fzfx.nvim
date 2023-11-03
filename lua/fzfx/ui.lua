local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels
local utils = require("fzfx.utils")

local default_user_canceled_error = "canceled."

--- @param bufnr integer
--- @param callback fun():any
--- @return boolean
local function confirm_discard_buffer_modified(bufnr, callback)
    if utils.get_buf_option(bufnr, "modified") then
        vim.ui.input(
            { prompt = "Current buffer has unsaved changes, discard? (y/n)" },
            function(input)
                if
                    type(input) == "string"
                    and string.len(input) > 0
                    and utils.string_startswith(input:lower(), "y")
                then
                    callback()
                else
                    log.echo(LogLevels.INFO, default_user_canceled_error)
                end
            end
        )
    end
end

local M = {
    confirm_discard_buffer_modified = confirm_discard_buffer_modified,
}

return M
