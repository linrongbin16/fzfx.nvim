local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels
local general = require("fzfx.general")

--- @param options Configs?
--- @return nil
local function setup(options)
    -- configs
    local configs = require("fzfx.config").setup(options)
    local defaults = require("fzfx.config").get_defaults()

    -- log
    log.setup({
        level = configs.debug.enable and LogLevels.DEBUG or LogLevels.INFO,
        console_log = configs.debug.console_log,
        file_log = configs.debug.file_log,
    })

    log.debug("|fzfx - setup| Defaults:\n%s", vim.inspect(defaults))
    log.debug("|fzfx - setup| Configs:\n%s", vim.inspect(configs))

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

    -- yank history
    require("fzfx.yank_history").setup()

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

    -- lsp diagnostics
    general.setup("lsp_diagnostics", configs.lsp_diagnostics)

    -- lsp definitions
    general.setup("lsp_definitions", configs.lsp_definitions)

    -- lsp type definitions
    general.setup("lsp_type_definitions", configs.lsp_type_definitions)

    -- lsp references
    general.setup("lsp_references", configs.lsp_references)

    -- lsp implementations
    general.setup("lsp_implementations", configs.lsp_implementations)

    -- file explorer
    general.setup("file_explorer", configs.file_explorer)

    -- users commands
    if type(configs.users) == "table" then
        for user_group, user_configs in pairs(configs.users) do
            local ok, error_msg = pcall(general.setup, user_group, user_configs)
            if not ok then
                log.err(
                    "failed to create user commands for %s! %s",
                    vim.inspect(user_group),
                    vim.inspect(error_msg)
                )
            end
        end
    end
end

local M = {
    setup = setup,
}

return M
