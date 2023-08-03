local function debug_enable()
    local v = tostring(vim.env._FZFX_NVIM_DEBUG_ENABLE):lower()
    return v:match("true$") or v == "1"
end

local M = {
    debug_enable = debug_enable,
}

return M
