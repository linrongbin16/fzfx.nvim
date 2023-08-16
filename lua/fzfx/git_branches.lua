local log = require("fzfx.log")
local path = require("fzfx.path")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local Launch = require("fzfx.launch").Launch
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local yank_history = require("fzfx.yank_history")
local color = require("fzfx.color")
local server = require("fzfx.server")

local Context = {
    --- @type string|nil
    remote_header = nil,
    --- @type string|nil
    local_header = nil,
}

--- @alias GitBranchesOptKey "local"
--- @alias GitBranchesOptValue boolean
--- @alias GitBranchesOpts table<GitBranchesOptKey, GitBranchesOptValue>

--- @param query string
--- @param bang boolean
--- @param opts GitBranchesOpts
--- @return Launch
local function git_branches(query, bang, opts)
    local git_branches_configs = conf.get_config().git_branches
    -- action
    local remote_action =
        string.lower(git_branches_configs.actions.builtin.remote_mode)
    local local_action =
        string.lower(git_branches_configs.actions.builtin.local_mode)

    local provider_switch = helpers.Switch:new(
        "git_branches_provider",
        opts.local and git_branches_configs.providers.local_branch
            or git_branches_configs.providers.remote_branch,
        opts.local and git_branches_configs.providers.remote_branch
            or git_branches_configs.providers.local_branch
    )

    -- rpc callback
    local function switch_provider_rpc_callback()
        log.debug("|fzfx.git_branches - git_branches.switch_provider_rpc_callback|")
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
    local preview_command =
        string.format("%s {}", shell.make_lua_command("git_branches", "previewer.lua"))
    log.debug(
        "|fzfx.git_branches - git_branches| query_command:%s, preview_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--prompt",
            "GBranches > ",
        },
        {
            "--preview",
            preview_command,
        },
    }
    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(git_branches_configs.fzf_opts))
    local actions = git_branches_configs.actions.expect
    local ppp =
        Popup:new(bang and { height = 1, width = 1, row = 0, col = 0 } or nil)
    local launch = Launch:new(ppp, query_command, fzf_opts, actions)

    return launch
end

local function setup()
    local git_branches_configs = conf.get_config().git_branches
    log.debug(
        "|fzfx.git_branches - setup| base_dir:%s, git_branches_configs:%s",
        vim.inspect(path.base_dir()),
        vim.inspect(git_branches_configs)
    )
    if not git_branches_configs then
        return
    end

    -- Context
    local remote_action = git_branches_configs.actions.builtin.remote_mode
    local local_action = git_branches_configs.actions.builtin.local_mode
    Context.remote_header = color.git_remote_branches_header(remote_action)
    Context.local_header = color.git_local_branches_header(local_action)

    -- User commands
    for _, command_configs in pairs(git_branches_configs.commands.normal) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            log.debug(
                "|fzfx.git_branches - setup| command:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(opts)
            )
            return git_branches(opts.args, opts.bang)
        end, command_configs.opts)
    end
    for _, command_configs in pairs(git_branches_configs.commands.visual) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local selected = helpers.visual_select()
            log.debug(
                "|fzfx.git_branches - setup| command:%s, selected:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(selected),
                vim.inspect(opts)
            )
            return git_branches(selected, opts.bang)
        end, command_configs.opts)
    end
    for _, command_configs in pairs(git_branches_configs.commands.cword) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.git_branches - setup| command:%s, word:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(word),
                vim.inspect(opts)
            )
            return git_branches(word, opts.bang)
        end, command_configs.opts)
    end
    for _, command_configs in pairs(git_branches_configs.commands.put) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local yank = yank_history.get_yank()
            log.debug(
                "|fzfx.git_branches - setup| command:%s, yank:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(yank),
                vim.inspect(opts)
            )
            return git_branches(
                (yank ~= nil and type(yank.regtext) == "string")
                        and yank.regtext
                    or "",
                opts.bang
            )
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
