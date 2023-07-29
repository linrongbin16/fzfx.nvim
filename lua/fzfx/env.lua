local function debug_enable()
    return vim.env._FZFX_DEBUG_ENABLE ~= nil and vim.env._FZFX_DEBUG_ENABLE
end

local function nvim_path()
    return vim.env._FZFX_NVIM_PATH
end

local M = {
    debug_enable = debug_enable,
    nvim_path = nvim_path,
}

return M
