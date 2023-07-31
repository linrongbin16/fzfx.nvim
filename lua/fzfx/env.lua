local function debug_enable()
    return vim.env._FZFX_NVIM_DEBUG_ENABLE
end

local M = {
    debug_enable = debug_enable,
}

return M
