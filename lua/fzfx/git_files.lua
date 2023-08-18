local log = require("fzfx.log")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local Launch = require("fzfx.launch").Launch
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")

--- @param query string
--- @param bang boolean
--- @param opts Configs?
--- @return Launch
local function git_files(query, bang, opts)
    local git_files_configs = conf.get_config().git_files

    -- query command, both initial query + reload query
    local provider_command = git_files_configs.providers
    local temp = vim.fn.tempname()
    vim.fn.writefile({ provider_command }, temp, "b")
    local query_command = string.format(
        "%s %s",
        shell.make_lua_command("git_files", "provider.lua"),
        temp
    )
    local preview_command =
        string.format("%s {}", shell.make_lua_command("files", "previewer.lua"))
    log.debug(
        "|fzfx.git_files - git_files| query_command:%s, preview_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--preview",
            preview_command,
        },
    }
    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(git_files_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = git_files_configs.actions
    local ppp =
        Popup:new(bang and { height = 1, width = 1, row = 0, col = 0 } or nil)
    local launch = Launch:new(ppp, query_command, fzf_opts, actions)

    return launch
end

local function setup()
    local git_files_configs = conf.get_config().git_files
    if not git_files_configs then
        return
    end

    -- User commands
    for _, command_configs in pairs(git_files_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            -- log.debug(
            --     "|fzfx.git_files - setup| command:%s, opts:%s",
            --     vim.inspect(command_configs.name),
            --     vim.inspect(opts)
            -- )
            return git_files(opts.args, opts.bang)
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
