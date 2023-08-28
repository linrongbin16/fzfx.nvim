local schema = require("fzfx.schema")

vim.api.nvim_echo(
    {
        {
            "[fzfx] warning! deprecated 'fzfx.meta', please migrate to latest config schema!",
            "WarningMsg",
        },
    },
    false,
    {}
)

local M = {
    ProviderTypeEnum = schema.ProviderTypeEnum,
    PreviewerTypeEnum = schema.PreviewerTypeEnum,
    CommandFeedEnum = schema.CommandFeedEnum,
}

return M
