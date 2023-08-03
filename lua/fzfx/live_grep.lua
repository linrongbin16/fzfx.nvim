local log = require("fzfx.log")
local utils = require("fzfx.utils")
local path = require("fzfx.path")
local conf = require("fzfx.config")

local Context = {
    --- @type string|nil
    umode_header = nil,
    --- @type string|nil
    rmode_header = nil,
}

--- @param query string
--- @param fullscreen boolean|integer
--- @param opts Config
local function live_grep(query, fullscreen, opts)
    local live_grep_configs = conf.get_config().live_grep
    local umode_action =
        string.lower(live_grep_configs.actions.builtin.unrestricted_mode)
    local rmode_action =
        string.lower(live_grep_configs.actions.builtin.restricted_mode)

    local runtime = {
        --- @type FileSwitch
        provider = utils.new_file_switch("live_grep_provider", {
            opts.unrestricted and live_grep_configs.provider.unrestricted
                or live_grep_configs.provider.restricted,
        }, {
            opts.unrestricted and live_grep_configs.provider.restricted
                or live_grep_configs.provider.unrestricted,
        }),
    }
    log.debug("|fzfx.live_grep - live_grep| runtime:%s", vim.inspect(runtime))

    local initial_command = string.format(
        "%s %s %s || true",
        utils.run_lua_script("live_grep_provider.lua"),
        runtime.provider.value,
        query
    )
    local reload_command = string.format(
        "%s %s {q} || true",
        utils.run_lua_script("live_grep_provider.lua"),
        runtime.provider.value
    )
    log.debug(
        "|fzfx.live_grep - live_grep| initial_command:%s, reload_command:%s",
        vim.inspect(initial_command),
        vim.inspect(reload_command)
    )

    local spec = {
        options = {
            "--ansi",
            "--disabled",
            "--query",
            query,
            "--header",
            opts.unrestricted and Context.rmode_header or Context.umode_header,
            "--bind",
            string.format(
                "start:unbind(%s)",
                opts.unrestricted and umode_action or rmode_action
            ),
            "--prompt",
            "Live Grep> ",
            "--bind",
            string.format("change:reload:%s", reload_command),
            "--bind",
            -- umode action: swap provider, change rmode header, rebind rmode action, reload query
            string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+rebind(%s)+reload(%s)",
                umode_action,
                umode_action,
                runtime.provider:switch(),
                Context.rmode_header,
                rmode_action,
                reload_command
            ),
            "--bind",
            -- rmode action: swap provider, change umode header, rebind umode action, reload query
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
    }
    spec = vim.fn["fzf#vim#with_preview"](spec)
    log.debug("|fzfx.live_grep - live_grep| spec:%s", vim.inspect(spec))
    return vim.fn["fzf#vim#grep"](initial_command, spec, fullscreen)
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
    Context.umode_header = utils.unrestricted_mode_header(umode_action)
    Context.rmode_header = utils.restricted_mode_header(rmode_action)

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
            local selected = utils.visual_select()
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
