local log = require("fzfx.log")
local path = require("fzfx.path")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local Launch = require("fzfx.launch").Launch
local shell = require("fzfx.shell")
local color = require("fzfx.color")
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")
local yank_history = require("fzfx.yank_history")

local Context = {
    --- @type string|nil
    umode_header = nil,
    --- @type string|nil
    rmode_header = nil,
}

--- @param query string
--- @param bang boolean
--- @param opts Config
--- @return Launch
local function live_grep(query, bang, opts)
    local live_grep_configs = conf.get_config().live_grep
    local umode_action =
        string.lower(live_grep_configs.actions.builtin.unrestricted_mode)
    local rmode_action =
        string.lower(live_grep_configs.actions.builtin.restricted_mode)

    local provider_switch = helpers.Switch:new(
        "files_provider",
        opts.unrestricted and live_grep_configs.providers.unrestricted
            or live_grep_configs.providers.restricted,
        opts.unrestricted and live_grep_configs.providers.restricted
            or live_grep_configs.providers.unrestricted
    )
    -- rpc callback
    local function switch_provider_rpc_callback()
        log.debug(
            "|fzfx.live_grep - live_grep.switch_provider_rpc_callback| context"
        )
        provider_switch:switch()
    end
    local switch_provider_rpc_callback_id =
        server.get_global_rpc_server():register(switch_provider_rpc_callback)

    local initial_command = string.format(
        "%s %s %s",
        shell.make_lua_command("live_grep", "provider.lua"),
        provider_switch.tempfile,
        query
    )
    local onchange_reload_delay =
        live_grep_configs.other_opts.onchange_reload_delay
    local reload_command = vim.fn.trim(
        string.format(
            "%s %s %s {q}",
            (
                type(onchange_reload_delay) == "string"
                and string.len(onchange_reload_delay) > 0
            )
                    and onchange_reload_delay
                or "",
            shell.make_lua_command("live_grep", "provider.lua"),
            provider_switch.tempfile
        )
    )
    local preview_command = string.format(
        "%s {1} {2}",
        shell.make_lua_command("files", "previewer.lua")
    )
    local call_switch_provider_rpc_command = string.format(
        "%s %s",
        shell.make_lua_command("rpc", "client.lua"),
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
            opts.unrestricted and Context.rmode_header or Context.umode_header,
        },
        { "--prompt", "Live Grep > " },
        { "--delimiter", ":" },
        {
            "--bind",
            string.format(
                "start:unbind(%s)",
                opts.unrestricted and umode_action or rmode_action
            ),
        },
        { "--bind", string.format("change:reload:%s", reload_command) },
        {
            -- umode action: swap provider, change rmode header, rebind rmode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                umode_action,
                umode_action,
                call_switch_provider_rpc_command,
                Context.rmode_header,
                rmode_action,
                reload_command
            ),
        },
        {
            -- rmode action: swap provider, change umode header, rebind umode action, reload query
            "--bind",
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                rmode_action,
                rmode_action,
                call_switch_provider_rpc_command,
                Context.umode_header,
                umode_action,
                reload_command
            ),
        },
        {
            "--preview",
            preview_command,
        },
        { "--preview-window", "+{2}-/2" },
    }
    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(live_grep_configs.fzf_opts))
    local actions = live_grep_configs.actions.expect
    local ppp =
        Popup:new(bang and { height = 1, width = 1, row = 0, col = 0 } or nil)
    local launch = Launch:new(
        ppp,
        initial_command,
        fzf_opts,
        actions,
        function()
            server
                .get_global_rpc_server()
                :unregister(switch_provider_rpc_callback_id)
        end
    )

    return launch
end

local function setup()
    local live_grep_configs = conf.get_config().live_grep
    log.debug(
        "|fzfx.live_grep - setup| base_dir:%s, live_grep_configs:%s",
        vim.inspect(path.base_dir()),
        vim.inspect(live_grep_configs)
    )
    if not live_grep_configs then
        return
    end

    local umode_action = live_grep_configs.actions.builtin.unrestricted_mode
    local rmode_action = live_grep_configs.actions.builtin.restricted_mode

    -- Context
    Context.umode_header = color.unrestricted_mode_header(umode_action)
    Context.rmode_header = color.restricted_mode_header(rmode_action)

    -- User commands
    for _, command_configs in pairs(live_grep_configs.commands.normal) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            log.debug(
                "|fzfx.live_grep - setup| command:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(opts)
            )
            return live_grep(
                opts.args,
                opts.bang,
                { unrestricted = command_configs.unrestricted }
            )
        end, command_configs.opts)
    end
    for _, command_configs in pairs(live_grep_configs.commands.visual) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local selected = helpers.visual_select()
            log.debug(
                "|fzfx.live_grep - setup| command:%s, selected:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(selected),
                vim.inspect(opts)
            )
            return live_grep(
                selected,
                opts.bang,
                { unrestricted = command_configs.unrestricted }
            )
        end, command_configs.opts)
    end
    for _, command_configs in pairs(live_grep_configs.commands.cword) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.live_grep - setup| command:%s, word:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(word),
                vim.inspect(opts)
            )
            return live_grep(
                word,
                opts.bang,
                { unrestricted = command_configs.unrestricted }
            )
        end, command_configs.opts)
    end
    for _, command_configs in pairs(live_grep_configs.commands.put) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local yank = yank_history.get_yank()
            log.debug(
                "|fzfx.live_grep - setup| command:%s, yank:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(yank),
                vim.inspect(opts)
            )
            return live_grep(
                (yank ~= nil and type(yank.regtext) == "string")
                        and yank.regtext
                    or "",
                opts.bang,
                { unrestricted = command_configs.unrestricted }
            )
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
