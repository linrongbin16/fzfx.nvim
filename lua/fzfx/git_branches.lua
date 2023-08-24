local log = require("fzfx.log")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local color = require("fzfx.color")
local server = require("fzfx.server")
local git_helpers = require("fzfx.git_helpers")
local utils = require("fzfx.utils")

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
        shell.make_lua_command("git_branches", "provider.lua"),
        provider_switch.tempfile
    )
    local git_log_command = git_branches_configs.previewers
    local temp = vim.fn.tempname()
    vim.fn.writefile({ git_log_command }, temp, "b")
    local preview_command = string.format(
        "%s %s {}",
        shell.make_lua_command("git_branches", "previewer.lua"),
        temp
    )
    local call_switch_provider_rpc_command = string.format(
        "%s %s",
        shell.make_lua_command("rpc", "client.lua"),
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
            local git_root_cmd = git_helpers.GitRootCommand:run()
            if git_root_cmd:wrong() then
                return nil
            end
            local git_current_branch_cmd =
                git_helpers.GitCurrentBranchCommand:run()
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

    -- Context
    Context.local_key =
        string.lower(git_branches_configs.providers.local_branch[1])
    Context.remote_key =
        string.lower(git_branches_configs.providers.remote_branch[1])
    Context.local_header = color.git_local_branches_header(Context.local_key)
    Context.remote_header = color.git_remote_branches_header(Context.remote_key)

    -- User commands
    for _, command_configs in pairs(git_branches_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            -- log.debug(
            --     "|fzfx.git_branches - setup| command:%s, opts:%s",
            --     vim.inspect(command_configs.name),
            --     vim.inspect(opts)
            -- )
            local query = helpers.get_command_feed(opts, command_configs.feed)
            return git_branches(
                query,
                opts.bang,
                { default_provider = command_configs.default_provider }
            )
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
