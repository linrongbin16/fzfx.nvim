--- @type table<string, Schema>
local Defaults = {
    -- the 'Files' commands
    FzfxFiles = require("fzfx.files2").files,
    FzfxFilesU = require("fzfx.files2").files_u,
}

--- @type table<string, Schema>
local Schemas = {}

--- @param schemas table<string, Schema>?
--- @return table<string, Schema>?
local function setup(schemas)
    Schemas = vim.tbl_deep_extend("force", Defaults, schemas or {})
    return Schemas
end

--- @return table<string, Schema>?
local function get_schemas()
    return Schemas
end

local M = {
    setup = setup,
    get_schemas = get_schemas,
}

return M
