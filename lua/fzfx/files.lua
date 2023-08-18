local log = require("fzfx.log")
local path = require("fzfx.path")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local Launch = require("fzfx.launch").Launch
local shell = require("fzfx.shell")
local color = require("fzfx.color")
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")

local Context = {
    --- @type string?
    rmode_key = nil,
    --- @type string?
    umode_key = nil,
    --- @type string?
    umode_header = nil,
    --- @type string?
    rmode_header = nil,
}

--- @alias FilesOptKey "default_provider"
--- @alias FilesOptValue "restricted"|"unrestricted"
--- @alias FilesOpts table<FilesOptKey, FilesOptValue>

--- @param query string
--- @param bang boolean
--- @param opts FilesOpts
--- @return Launch
local function files(query, bang, opts)
    local files_configs = conf.get_config().files

    local provider_switch = helpers.Switch:new(
        "files_provider",
        opts.default_provider == "restricted"
                and files_configs.providers.restricted[2]
            or files_configs.providers.unrestricted[2],
        opts.default_provider == "restricted"
                and files_configs.providers.unrestricted[2]
            or files_configs.providers.restricted[1]
    )

    -- rpc callback
    local function switch_provider_rpc_callback()
        log.debug("|fzfx.files - files.switch_provider_rpc_callback| context")
        provider_switch:switch()
    end
    local switch_provider_rpc_callback_id =
        server.get_global_rpc_server():register(switch_provider_rpc_callback)

    -- query command, both initial query + reload query
    local query_command = string.format(
        "%s %s",
        shell.make_lua_command("files", "provider.lua"),
        provider_switch.tempfile
    )
    local preview_command =
        string.format("%s {}", shell.make_lua_command("files", "previewer.lua"))
    local call_switch_provider_rpc_command = string.format(
        "%s %s",
        shell.make_lua_command("rpc", "client.lua"),
        switch_provider_rpc_callback_id
    )
    log.debug(
        "|fzfx.files - files| query_command:%s, preview_command:%s, call_switch_provider_rpc_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command),
        vim.inspect(call_switch_provider_rpc_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--header",
            opts.default_provider == "restricted" and Context.umode_header
                or Context.rmode_header,
        },
        {
            "--prompt",
            path.shorten() .. " > ",
        },
        {
            "--bind",
            string.format(
                "start:unbind(%s)",
                opts.default_provider == "restricted" and Context.rmode_key
                    or Context.umode_key
            ),
        },
        {
            -- umode action: swap provider, change rmode header, rebind rmode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                Context.umode_key,
                Context.umode_key,
                call_switch_provider_rpc_command,
                Context.rmode_header,
                Context.rmode_key,
                query_command
            ),
        },
        {
            -- rmode action: swap provider, change umode header, rebind umode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                Context.rmode_key,
                Context.rmode_key,
                call_switch_provider_rpc_command,
                Context.umode_header,
                Context.umode_key,
                query_command
            ),
        },
        {
            "--preview",
            preview_command,
        },
    }
    fzf_opts = vim.list_extend(fzf_opts, vim.deepcopy(files_configs.fzf_opts))
    local actions = files_configs.actions
    local ppp =
        Popup:new(bang and { height = 1, width = 1, row = 0, col = 0 } or nil)
    local launch = Launch:new(ppp, query_command, fzf_opts, actions, function()
        server
            .get_global_rpc_server()
            :unregister(switch_provider_rpc_callback_id)
    end)

    return launch
end

local function setup()
    local files_configs = conf.get_config().files
    log.debug(
        "|fzfx.files - setup| base_dir:%s, files_configs:%s",
        vim.inspect(path.base_dir()),
        vim.inspect(files_configs)
    )

    if not files_configs then
        return
    end

    -- Context
    Context.rmode_key = string.lower(files_configs.providers.restricted[1])
    Context.umode_key = string.lower(files_configs.providers.unrestricted[1])
    Context.rmode_header = color.restricted_mode_header(Context.rmode_key)
    Context.umode_header = color.unrestricted_mode_header(Context.umode_key)

    -- User commands
    for _, command_configs in pairs(files_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            log.debug(
                "|fzfx.files - setup| command_configs:%s, opts:%s",
                vim.inspect(command_configs),
                vim.inspect(opts)
            )
            local query = helpers.get_command_feed(opts, command_configs.feed)
            return files(
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
