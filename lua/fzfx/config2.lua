--- @type Config
local Defaults = {
    -- the 'Files' commands
    --- @type Schema[]
    files = { require("fzfx.files2").files },
}

--- @type Config
local Configs = {}

--- @param options Config|nil
--- @return Config
local function setup(options)
    Configs = vim.tbl_deep_extend("force", Defaults, options or {})
    return Configs
end

--- @return Config
local function get_config()
    return Configs
end

local M = {
    setup = setup,
    get_config = get_config,
}

return M
