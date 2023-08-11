local log = require("fzfx.log")

--- @param options Config|nil
--- @return nil
local function setup(options)
    -- configs
    local configs = require("fzfx.config").setup(options)

    -- log
    log.setup({
        level = configs.debug.enable and "DEBUG" or "INFO",
        console_log = configs.debug.console_log,
        file_log = configs.debug.file_log,
    })
    log.debug("|fzfx - setup| configs:%s", vim.inspect(configs))

    -- cache
    vim.fn.mkdir(configs.cache.dir, "p")

    -- env
    require("fzfx.env").setup(configs)

    -- files
    require("fzfx.files").setup()

    -- live_grep
    require("fzfx.live_grep").setup()
end

local M = {
    setup = setup,
}

return M
