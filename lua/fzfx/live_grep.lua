local log = require("fzfx.log")
local path = require("fzfx.path")
local conf = require("fzfx.config")
local popup = require("fzfx.popup")
local shell = require("fzfx.shell")
local FileSwitch = require("fzfx.utils").FileSwitch
local color = require("fzfx.color")
local helpers = require("fzfx.helpers")

local Context = {
    --- @type string|nil
    umode_header = nil,
    --- @type string|nil
    rmode_header = nil,
}

--- @param query string
--- @param bang boolean|integer
--- @param opts Config
--- @return Launch
local function live_grep(query, bang, opts)
    local live_grep_configs = conf.get_config().live_grep
    local umode_action =
        string.lower(live_grep_configs.actions.builtin.unrestricted_mode)
    local rmode_action =
        string.lower(live_grep_configs.actions.builtin.restricted_mode)

    local runtime = {
        --- @type FileSwitch
        provider = FileSwitch:new("live_grep_provider", {
            opts.unrestricted and live_grep_configs.providers.unrestricted
                or live_grep_configs.providers.restricted,
        }, {
            opts.unrestricted and live_grep_configs.providers.restricted
                or live_grep_configs.providers.unrestricted,
        }),
    }
    log.debug("|fzfx.live_grep - live_grep| runtime:%s", vim.inspect(runtime))

    local initial_command = string.format(
        "%s %s %s",
        shell.make_lua_command("live_grep", "provider.lua"),
        runtime.provider.value,
        query
    )
    local reload_command = string.format(
        "%s %s {q} || true",
        shell.make_lua_command("live_grep", "provider.lua"),
        runtime.provider.value
    )
    local preview_command = string.format(
        "%s {1} {2}",
        shell.make_lua_command("files", "previewer.lua")
    )
    log.debug(
        "|fzfx.live_grep - live_grep| initial_command:%s, reload_command:%s, preview_command:%s",
        vim.inspect(initial_command),
        vim.inspect(reload_command),
        vim.inspect(preview_command)
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
                runtime.provider:switch(),
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
                runtime.provider:switch(),
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
    local ppp = popup.Popup:new(bang and { height = 1, width = 1 } or nil)
    local popup_fzf =
        popup.new_popup_fzf(ppp, initial_command, fzf_opts, actions)

    return popup_fzf
end

local function setup()
    local live_grep_configs = conf.get_config().live_grep
    log.debug(
        "|fzfx.live_grep - setup| base_dir:%s, live_grep_configs:%s",
        vim.inspect(path.base_dir()),
        vim.inspect(live_grep_configs)
    )

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
                command_configs.unrestricted and { unrestricted = true }
                    or { unrestricted = false }
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
                command_configs.unrestricted and { unrestricted = true }
                    or { unrestricted = false }
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
                command_configs.unrestricted and { unrestricted = true }
                    or { unrestricted = false }
            )
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
