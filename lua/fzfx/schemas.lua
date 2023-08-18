local constants = require("fzfx.constants")

--- @type Command[]
local Defaults = {
    -- the 'Files' commands

    -- FzfxFiles
    require("fzfx.files2").files,
    -- FzfxFilesU
    require("fzfx.files2").files_u,
}

--- @type Config
local Schemas = {}

--- @param options Config|nil
--- @return Config
local function setup(options)
    Schemas = vim.tbl_deep_extend("force", Defaults, options or {})
    return Schemas
end

--- @return Config
local function get_config()
    return Schemas
end

local M = {
    setup = setup,
    get_config = get_config,
}

return M
