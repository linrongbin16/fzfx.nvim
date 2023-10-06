local DELAY_MS = 3 * 1000

local function notify(fmt, ...)
    local msg = string.format(fmt, ...)

    local function impl()
        local msg_lines = vim.split(msg, "\n", { plain = true })
        local msg_chunks = {}
        for _, line in ipairs(msg_lines) do
            table.insert(msg_chunks, {
                string.format("[fzfx] warning! %s", line),
                "WarningMsg",
            })
        end
        vim.api.nvim_echo(msg_chunks, false, {})
    end

    vim.defer_fn(impl, DELAY_MS)
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            vim.defer_fn(impl, DELAY_MS)
        end,
    })
end

local M = {
    notify = notify,
}

return M
