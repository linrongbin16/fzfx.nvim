local log = require("fzfx.log")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local color = require("fzfx.color")
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")
local utils = require("fzfx.utils")

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

--- @alias LiveGrepOptKey "default_provider"
--- @alias LiveGrepOptValue "restricted"|"unrestricted"
--- @alias LiveGrepOpts table<LiveGrepOptKey, LiveGrepOptValue>
--- @param query string
--- @param bang boolean
--- @param opts LiveGrepOpts
--- @return Popup
local function live_grep(query, bang, opts)
    local live_grep_configs = conf.get_config().live_grep

    local provider_switch = helpers.Switch:new(
        "live_grep_provider",
        opts.default_provider == "restricted"
                and live_grep_configs.providers.restricted[2]
            or live_grep_configs.providers.unrestricted[2],
        opts.default_provider == "restricted"
                and live_grep_configs.providers.unrestricted[2]
            or live_grep_configs.providers.restricted[2]
    )
    -- rpc callback
    local function switch_provider_rpc_callback()
        log.debug("|fzfx.live_grep - live_grep.switch_provider_rpc_callback|")
        provider_switch:switch()
    end
    local switch_provider_rpc_callback_id =
        server.get_global_rpc_server():register(switch_provider_rpc_callback)

    local initial_command = string.format(
        "%s %s %s",
        helpers.make_lua_command("live_grep", "provider.lua"),
        provider_switch.tempfile,
        query
    )
    local onchange_reload_delay =
        live_grep_configs.other_opts.onchange_reload_delay
    local reload_command = vim.trim(
        string.format(
            "%s %s %s {q}",
            utils.string_not_empty(onchange_reload_delay)
                    and onchange_reload_delay
                or "",
            helpers.make_lua_command("live_grep", "provider.lua"),
            provider_switch.tempfile
        )
    )
    local preview_command = string.format(
        "%s {1} {2}",
        helpers.make_lua_command("files", "previewer.lua")
    )
    local call_switch_provider_rpc_command = string.format(
        "%s %s",
        helpers.make_lua_command("rpc", "client.lua"),
        switch_provider_rpc_callback_id
    )
    log.debug(
        "|fzfx.live_grep - live_grep| initial_command:%s, reload_command:%s, preview_command:%s, call_switch_provider_rpc_command:%s",
        vim.inspect(initial_command),
        vim.inspect(reload_command),
        vim.inspect(preview_command),
        vim.inspect(call_switch_provider_rpc_command)
    )

    local fzf_opts = {
        "--disabled",
        { "--query", query },
        {
            "--header",
            opts.default_provider == "restricted" and Context.umode_header
                or Context.rmode_header,
        },
        {
            "--bind",
            string.format(
                "start:unbind(%s)",
                opts.default_provider == "restricted" and Context.rmode_key
                    or Context.umode_key
            ),
        },
        { "--bind", string.format("change:reload:%s", reload_command) },
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
                reload_command
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
                reload_command
            ),
        },
        {
            "--preview",
            preview_command,
        },
    }
    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(live_grep_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = live_grep_configs.actions
    local p = Popup:new(
        bang and { height = 1, width = 1, row = 0, col = 0 } or nil,
        initial_command,
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
    local live_grep_configs = conf.get_config().live_grep
    if not live_grep_configs then
        return
    end

    -- Context
    Context.rmode_key = string.lower(live_grep_configs.providers.restricted[1])
    Context.umode_key =
        string.lower(live_grep_configs.providers.unrestricted[1])
    Context.rmode_header = color.restricted_mode_header(Context.rmode_key)
    Context.umode_header = color.unrestricted_mode_header(Context.umode_key)

    -- User commands
    for _, command_configs in pairs(live_grep_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            -- log.debug(
            --     "|fzfx.live_grep - setup| command_configs:%s, opts:%s",
            --     vim.inspect(command_configs),
            --     vim.inspect(opts)
            -- )
            local query = helpers.get_command_feed(opts, command_configs.feed)
            return live_grep(
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
