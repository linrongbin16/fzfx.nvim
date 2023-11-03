-- No Setup Need

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

    local timer = vim.loop.new_timer()
    timer:start(
        3000,
        0,
        vim.schedule_wrap(function()
            timer:stop()
            timer:close()
            impl()
        end)
    )
end

local M = {
    notify = notify,
}

return M
