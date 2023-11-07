local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels
local general = require("fzfx.general")

--- @param options Options?
local function setup(options)
    -- configs
    local configs = require("fzfx.config").setup(options)

    -- log
    log.setup({
        level = configs.debug.enable and LogLevels.DEBUG or LogLevels.INFO,
        console_log = configs.debug.console_log,
        file_log = configs.debug.file_log,
    })

    if configs.debug.enable then
        log.debug(
            "|fzfx - setup| Defaults:\n%s",
            vim.inspect(require("fzfx.config").get_defaults())
        )
    end
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
    require("fzfx.module").setup()

    -- rpc server
    require("fzfx.server").setup()
    require("fzfx.rpc_server").setup()

    -- yank history
    require("fzfx.yank_history").setup()

    -- fzf helpers
    require("fzfx.fzf_helpers").setup()

    -- popup
    require("fzfx.popup").setup()

    -- files & buffers
    general.setup("files", configs.files)
    general.setup("buffers", configs.buffers)

    -- grep
    general.setup("live_grep", configs.live_grep)

    -- git
    general.setup("git_files", configs.git_files)
    general.setup("git_status", configs.git_status)
    general.setup("git_branches", configs.git_branches)
    general.setup("git_commits", configs.git_commits)
    general.setup("git_blame", configs.git_blame)

    -- lsp & diagnostics
    general.setup("lsp_diagnostics", configs.lsp_diagnostics)
    general.setup("lsp_definitions", configs.lsp_definitions)
    general.setup("lsp_type_definitions", configs.lsp_type_definitions)
    general.setup("lsp_references", configs.lsp_references)
    general.setup("lsp_implementations", configs.lsp_implementations)

    -- vim
    general.setup("vim_commands", configs.commands or configs.vim_commands)
    general.setup("vim_keymaps", configs.vim_keymaps)

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

--- @param name string
--- @param configs Options
local function register(name, configs)
    general.setup(name, configs)
end

local M = {
    setup = setup,
    register = register,
}

return M
