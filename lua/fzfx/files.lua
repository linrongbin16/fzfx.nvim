local log = require("fzfx.log")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local color = require("fzfx.color")
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")

local Constants = {
    --- @type string?
    restricted_key = nil,
    --- @type string?
    unrestricted_key = nil,
    --- @type string?
    restricted_header = nil,
    --- @type string?
    unrestricted_header = nil,
}

--- @alias FilesOptKey "default_provider"
--- @alias FilesOptValue "restricted"|"unrestricted"
--- @alias FilesOpts table<FilesOptKey, FilesOptValue>
--- @param query string
--- @param bang boolean
--- @param opts FilesOpts
--- @return Popup
local function files(query, bang, opts)
    local files_configs = conf.get_config().files

    local provider_switch = helpers.Switch:new(
        "files_provider",
        opts.default_provider == "restricted"
                and files_configs.providers.restricted[2]
            or files_configs.providers.unrestricted[2],
        opts.default_provider == "restricted"
                and files_configs.providers.unrestricted[2]
            or files_configs.providers.restricted[2]
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
        helpers.make_lua_command("files", "provider.lua"),
        provider_switch.tempfile
    )
    local preview_command = string.format(
        "%s {}",
        helpers.make_lua_command("files", "previewer.lua")
    )
    local call_switch_provider_rpc_command = string.format(
        "%s %s",
        helpers.make_lua_command("rpc", "client.lua"),
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
            opts.default_provider == "restricted"
                    and Constants.unrestricted_header
                or Constants.restricted_header,
        },
        {
            "--bind",
            string.format(
                "start:unbind(%s)",
                opts.default_provider == "restricted"
                        and Constants.restricted_key
                    or Constants.unrestricted_key
            ),
        },
        {
            -- umode action: swap provider, change rmode header, rebind rmode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                Constants.unrestricted_key,
                Constants.unrestricted_key,
                call_switch_provider_rpc_command,
                Constants.restricted_header,
                Constants.restricted_key,
                query_command
            ),
        },
        {
            -- rmode action: swap provider, change umode header, rebind umode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                Constants.restricted_key,
                Constants.restricted_key,
                call_switch_provider_rpc_command,
                Constants.unrestricted_header,
                Constants.unrestricted_key,
                query_command
            ),
        },
        {
            "--preview",
            preview_command,
        },
    }
    fzf_opts = vim.list_extend(fzf_opts, vim.deepcopy(files_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = files_configs.actions
    local p = Popup:new(
        bang and { height = 1, width = 1, row = 0, col = 0 } or nil,
        query_command,
        fzf_opts,
        actions,
        function()
            server
                .get_global_rpc_server()
                :unregister(switch_provider_rpc_callback_id)
        end
    )
    return p
end

local function setup()
    local files_configs = conf.get_config().files
    if not files_configs then
        return
    end

    -- Context
    Constants.restricted_key =
        string.lower(files_configs.providers.restricted[1])
    Constants.unrestricted_key =
        string.lower(files_configs.providers.unrestricted[1])
    Constants.restricted_header =
        color.restricted_mode_header(Constants.restricted_key)
    Constants.unrestricted_header =
        color.unrestricted_mode_header(Constants.unrestricted_key)

    -- User commands
    for _, command_configs in pairs(files_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            -- log.debug(
            --     "|fzfx.files - setup| command_configs:%s, opts:%s",
            --     vim.inspect(command_configs),
            --     vim.inspect(opts)
            -- )
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
