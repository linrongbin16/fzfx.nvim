local log = require("fzfx.log")
local LogLevel = require("fzfx.log").LogLevel
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local helpers = require("fzfx.helpers")
local color = require("fzfx.color")
local server = require("fzfx.server")
local gitcmd = require("fzfx.gitcmd")
local utils = require("fzfx.utils")
local general = require("fzfx.general")
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum

local Context = {
    --- @type string?
    local_key = nil,
    --- @type string?
    remote_key = nil,
    --- @type string?
    local_header = nil,
    --- @type string?
    remote_header = nil,
}

--- @alias GitBranchesOptKey "default_provider"
--- @alias GitBranchesOptValue "local_branch"|"remote_branch"
--- @alias GitBranchesOpts table<GitBranchesOptKey, GitBranchesOptValue>

--- @param query string
--- @param bang boolean
--- @param opts GitBranchesOpts
--- @return Popup
local function git_branches(query, bang, opts)
    local git_branches_configs = conf.get_config().git_branches

    local provider_switch = helpers.Switch:new(
        "git_branches_provider",
        opts.default_provider == "local_branch"
                and git_branches_configs.providers.local_branch[2]
            or git_branches_configs.providers.remote_branch[2],
        opts.default_provider == "local_branch"
                and git_branches_configs.providers.remote_branch[2]
            or git_branches_configs.providers.local_branch[2]
    )

    -- rpc callback
    local function switch_provider_rpc_callback()
        log.debug(
            "|fzfx.git_branches - git_branches.switch_provider_rpc_callback|"
        )
        provider_switch:switch()
    end
    local switch_provider_rpc_callback_id =
        server.get_global_rpc_server():register(switch_provider_rpc_callback)

    -- query command, both initial query + reload query
    local query_command = string.format(
        "%s %s",
        helpers.make_lua_command("git_branches", "provider.lua"),
        provider_switch.tempfile
    )
    local git_log_command = git_branches_configs.previewers
    local temp = vim.fn.tempname()
    vim.fn.writefile({ git_log_command }, temp, "b")
    local preview_command = string.format(
        "%s %s {}",
        helpers.make_lua_command("git_branches", "previewer.lua"),
        temp
    )
    local call_switch_provider_rpc_command = string.format(
        "%s %s",
        helpers.make_lua_command("rpc", "client.lua"),
        switch_provider_rpc_callback_id
    )
    log.debug(
        "|fzfx.git_branches - git_branches| query_command:%s, preview_command:%s, call_switch_provider_rpc_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command),
        vim.inspect(call_switch_provider_rpc_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--header",
            opts.default_provider == "local_branch" and Context.remote_header
                or Context.local_header,
        },
        {
            "--bind",
            string.format(
                "start:unbind(%s)",
                opts.default_provider == "local_branch" and Context.local_key
                    or Context.remote_key
            ),
        },
        {
            -- remote key: swap provider, change rmode header, rebind rmode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                Context.remote_key,
                Context.remote_key,
                call_switch_provider_rpc_command,
                Context.local_header,
                Context.local_key,
                query_command
            ),
        },
        {
            -- local key: swap provider, change umode header, rebind umode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                Context.local_key,
                Context.local_key,
                call_switch_provider_rpc_command,
                Context.remote_header,
                Context.remote_key,
                query_command
            ),
        },
        {
            "--preview",
            preview_command,
        },
        function()
            local git_root_cmd = gitcmd.GitRootCmd:run()
            if git_root_cmd:wrong() then
                return nil
            end
            local git_current_branch_cmd = gitcmd.GitCurrentBranchCmd:run()
            if git_current_branch_cmd:wrong() then
                return nil
            end
            return utils.string_not_empty(git_current_branch_cmd:value())
                    and "--header-lines=1"
                or nil
        end,
    }

    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(git_branches_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = git_branches_configs.actions
    local p = Popup:new(
        bang and { height = 1, width = 1, row = 0, col = 0 } or nil,
        query_command,
        fzf_opts,
        actions
    )
    return p
end

local function setup()
    local git_branches_configs = conf.get_config().git_branches
    if not git_branches_configs then
        return
    end

    local deprecated = false
    for provider_name, provider_opts in pairs(git_branches_configs.providers) do
        if
            #provider_opts >= 2
            or type(provider_opts[1]) == "string"
            or type(provider_opts[2]) == "string"
        then
            --- @type ActionKey
            provider_opts.key = provider_opts[1]
            --- @type Provider
            provider_opts.provider = provider_opts[2]
            deprecated = true
        end
    end
    if type(git_branches_configs.previewers) == "string" then
        local old_previewer = git_branches_configs.previewers
        git_branches_configs.previewers = {}
        for provider_name, _ in pairs(git_branches_configs.providers) do
            git_branches_configs.previewers[provider_name] = {
                previewer = function(line)
                    local commit = vim.fn.split(line)[1]
                    return string.format("%s %s", old_previewer, commit)
                end,
                previewer_type = PreviewerTypeEnum.COMMAND,
            }
        end
        deprecated = true
    end
    general.setup("git_branches", git_branches_configs)
    if deprecated then
        local function deprecated_notification()
            log.echo(
                LogLevel.WARN,
                "deprecated 'FzfxGBranches' configs, please migrate to latest config schema!"
            )
        end
        local delay = 3 * 1000
        vim.defer_fn(deprecated_notification, delay)
        vim.api.nvim_create_autocmd("VimEnter", {
            pattern = { "*" },
            callback = function()
                vim.defer_fn(deprecated_notification, delay)
            end,
        })
    end
end

local M = {
    setup = setup,
}

return M
