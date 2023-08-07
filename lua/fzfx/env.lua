local conf = require("fzfx.config")

local function debug_enable()
    return tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"
end

local function setup()
    local config = conf.get_config()
    vim.env._FZFX_NVIM_DEBUG_ENABLE = config.debug.enable and 1 or 0
    vim.env._FZFX_NVIM_DEBUG_ENABLE = config.debug.enable and 1 or 0
end

local M = {
    debug_enable = debug_enable,
    setup = setup,
}

return M
