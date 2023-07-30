local function debug_enable()
    return vim.env._FZFX_NVIM_DEBUG_ENABLE
end

local function nvim_exec()
    return vim.env._FZFX_NVIM_NVIM_EXEC
end

local M = {
    debug_enable = debug_enable,
    nvim_exec = nvim_exec,
}

return M
