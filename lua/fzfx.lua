local log = require("fzfx.log")
local general = require("fzfx.general")

--- @param options Configs|nil
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
    if vim.fn.filereadable(configs.cache.dir) > 0 then
        log.throw(
            "error! the 'cache.dir' (%s) already exist but not a directory!",
            configs.cache.dir
        )
    else
        vim.fn.mkdir(configs.cache.dir, "p")
    end

    -- lua module environment
    require("fzfx.module").setup(configs)

    -- rpc server
    require("fzfx.server").setup()

    -- files
    require("fzfx.files").setup()

    -- live_grep
    require("fzfx.live_grep").setup()

    -- buffers
    require("fzfx.buffers").setup()

    -- git files
    require("fzfx.git_files").setup()

    -- git branches
    require("fzfx.git_branches").setup()

    -- git commits
    require("fzfx.git_commits").setup()

    -- git blame
    general.setup("git_blame", configs.git_blame)

    -- yank history
    require("fzfx.yank_history").setup()
end

local M = {
    setup = setup,
}

return M
