-- No Setup Need

local schema = require("fzfx.schema")
local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels

local function deprecated_notification()
    log.echo(
        LogLevels.WARN,
        "deprecated 'fzfx.meta', please migrate to latest config schema!"
    )
end
local delay = 3 * 1000
vim.defer_fn(deprecated_notification, delay)
vim.api.nvim_create_autocmd("VimEnter", {
    pattern = { "*" },
    callback = function()
        vim.defer_fn(deprecated_notification, delay)
    end,
})

local M = {
    ProviderTypeEnum = schema.ProviderTypeEnum,
    PreviewerTypeEnum = schema.PreviewerTypeEnum,
    CommandFeedEnum = schema.CommandFeedEnum,
}

return M
