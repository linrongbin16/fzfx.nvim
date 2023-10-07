-- No Setup Need

local schema = require("fzfx.schema")

require("fzfx.deprecated").notify(
    "deprecated 'fzfx.meta', please migrate to new config schema!"
)

local M = {
    ProviderTypeEnum = schema.ProviderTypeEnum,
    PreviewerTypeEnum = schema.PreviewerTypeEnum,
    CommandFeedEnum = schema.CommandFeedEnum,
}

return M
