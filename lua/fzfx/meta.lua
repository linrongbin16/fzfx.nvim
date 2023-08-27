local schema = require("fzfx.schema")

-- print(
--     "[fzfx] warning! deprecated 'fzfx.meta' usage, please migrate to latest config schema!"
-- )

local M = {
    ProviderTypeEnum = schema.ProviderTypeEnum,
    PreviewerTypeEnum = schema.PreviewerTypeEnum,
    CommandFeedEnum = schema.CommandFeedEnum,
}

return M
