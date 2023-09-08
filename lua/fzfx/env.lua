-- Zero Dependency

--- @return boolean
local function debug_enable()
    return tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"
end

--- @return boolean
local function icon_enable()
    return type(vim.env._FZFX_NVIM_DEVICONS_PATH) == "string"
        and string.len(vim.env._FZFX_NVIM_DEVICONS_PATH) > 0
end

local M = {
    debug_enable = debug_enable,
    icon_enable = icon_enable,
}

return M
