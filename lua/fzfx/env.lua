local function debug_enable()
    return tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower() == "1"
end

local M = {
    debug_enable = debug_enable,
}

return M
