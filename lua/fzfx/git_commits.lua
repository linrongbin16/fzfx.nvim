local log = require("fzfx.log")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local Launch = require("fzfx.launch").Launch
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local color = require("fzfx.color")
local server = require("fzfx.server")
local git_helpers = require("fzfx.git_helpers")
local utils = require("fzfx.utils")

local Context = {
    --- @type string?
    all_key = nil,
    --- @type string?
    buffer_key = nil,
    --- @type string?
    all_header = nil,
    --- @type string?
    buffer_header = nil,
}

--- @alias GitCommitsOptKey "default_provider"
--- @alias GitCommitsOptValue "all_commits"|"buffer_commits"
--- @alias GitCommitsOpts table<GitCommitsOptKey, GitCommitsOptValue>

--- @param query string
--- @param bang boolean
--- @param opts GitCommitsOpts
--- @return Launch
local function git_commits(query, bang, opts)
    local git_commits_configs = conf.get_config().git_commits

    local current_bufnr = vim.api.nvim_get_current_buf()
    local current_bufname = vim.api.nvim_buf_get_name(current_bufnr)
    local buffer_only_provider = utils.is_buf_valid(current_bufnr)
            and string.format(
                "%s -- %s",
                git_commits_configs.providers.buffer_commits[2],
                current_bufname
            )
        or git_commits_configs.providers.all_commits[2]
    local provider_switch = helpers.Switch:new(
        "git_commits_provider",
        opts.default_provider == "all_commits"
                and git_commits_configs.providers.all_commits[2]
            or buffer_only_provider,
        opts.default_provider == "buffer_commits" and buffer_only_provider
            or git_commits_configs.providers.all_commits[2]
    )

    -- rpc callback
    local function switch_provider_rpc_callback()
        log.debug(
            "|fzfx.git_commits - git_commits.switch_provider_rpc_callback|"
        )
        provider_switch:switch()
    end
    local switch_provider_rpc_callback_id =
        server.get_global_rpc_server():register(switch_provider_rpc_callback)

    -- query command, both initial query + reload query
    local query_command = string.format(
        "%s %s",
        shell.make_lua_command("git_commits", "provider.lua"),
        provider_switch.tempfile
    )
    local git_show_command = git_commits_configs.previewers
    local temp = vim.fn.tempname()
    vim.fn.writefile({ git_show_command }, temp, "b")
    local preview_command = string.format(
        "%s %s {}",
        shell.make_lua_command("git_commits", "previewer.lua"),
        temp
    )
    local call_switch_provider_rpc_command = string.format(
        "%s %s",
        shell.make_lua_command("rpc", "client.lua"),
        switch_provider_rpc_callback_id
    )
    log.debug(
        "|fzfx.git_commits - git_commits| query_command:%s, preview_command:%s, call_switch_provider_rpc_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command),
        vim.inspect(call_switch_provider_rpc_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--header",
            opts.default_provider == "all_commits" and Context.all_header
                or Context.buffer_header,
        },
        {
            "--bind",
            string.format(
                "start:unbind(%s)",
                opts.default_provider == "all_commits" and Context.buffer_key
                    or Context.all_key
            ),
        },
        {
            -- buffer key: swap provider, change rmode header, rebind rmode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                Context.buffer_key,
                Context.buffer_key,
                call_switch_provider_rpc_command,
                Context.all_header,
                Context.all_key,
                query_command
            ),
        },
        {
            -- all key: swap provider, change umode header, rebind umode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                Context.all_key,
                Context.all_key,
                call_switch_provider_rpc_command,
                Context.buffer_header,
                Context.buffer_key,
                query_command
            ),
        },
        {
            "--preview",
            preview_command,
        },
    }

    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(git_commits_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = git_commits_configs.actions
    local ppp =
        Popup:new(bang and { height = 1, width = 1, row = 0, col = 0 } or nil)
    local launch = Launch:new(ppp, query_command, fzf_opts, actions)

    return launch
end

local function setup()
    local git_commits_configs = conf.get_config().git_commits
    if not git_commits_configs then
        return
    end

    -- Context
    Context.all_key =
        string.lower(git_commits_configs.providers.local_branch[1])
    Context.buffer_key =
        string.lower(git_commits_configs.providers.remote_branch[1])
    Context.all_header = color.git_all_commits_header(Context.all_key)
    Context.buffer_header = color.git_buffer_commits_header(Context.buffer_key)

    -- User commands
    for _, command_configs in pairs(git_commits_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            -- log.debug(
            --     "|fzfx.git_commits - setup| command:%s, opts:%s",
            --     vim.inspect(command_configs.name),
            --     vim.inspect(opts)
            -- )
            local query = helpers.get_command_feed(opts, command_configs.feed)
            return git_commits(
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
