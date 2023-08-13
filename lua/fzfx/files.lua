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

--- @return string
local function short_path()
    local cwd_path = vim.fn.fnamemodify(vim.fn.getcwd(), ":~:.")
    local shorten_path = vim.fn.pathshorten(cwd_path)
    return shorten_path
end

--- @param query string
--- @param bang boolean
--- @param opts Config
--- @return Launch
local function files(query, bang, opts)
    local files_configs = conf.get_config().files
    -- action
    local umode_action =
        string.lower(files_configs.actions.builtin.unrestricted_mode)
    local rmode_action =
        string.lower(files_configs.actions.builtin.restricted_mode)

    local provider_switch = helpers.Switch:new(
        "files_provider",
        opts.unrestricted and files_configs.providers.unrestricted
            or files_configs.providers.restricted,
        opts.unrestricted and files_configs.providers.restricted
            or files_configs.providers.unrestricted
    )

    -- rpc callback
    local function switch_provider_rpc_callback()
        log.debug("|fzfx.files - files.switch_provider_rpc_callback|")
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
            opts.unrestricted and Context.rmode_header or Context.umode_header,
        },
        {
            "--prompt",
            short_path() .. " > ",
        },
        {
            "--bind",
            string.format(
                "start:unbind(%s)",
                opts.unrestricted and umode_action or rmode_action
            ),
        },
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
                query_command
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
                query_command
            ),
        },
        {
            "--preview",
            preview_command,
        },
    }
    fzf_opts = vim.list_extend(fzf_opts, vim.deepcopy(files_configs.fzf_opts))
    local actions = files_configs.actions.expect
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

    -- Context
    local umode_action = files_configs.actions.builtin.unrestricted_mode
    local rmode_action = files_configs.actions.builtin.restricted_mode
    Context.umode_header = color.unrestricted_mode_header(umode_action)
    Context.rmode_header = color.restricted_mode_header(rmode_action)

    -- User commands
    for _, command_configs in pairs(files_configs.commands.normal) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            log.debug(
                "|fzfx.files - setup| command:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(opts)
            )
            return files(
                opts.args,
                opts.bang,
                command_configs.unrestricted and { unrestricted = true }
                    or { unrestricted = false }
            )
        end, command_configs.opts)
    end
    for _, command_configs in pairs(files_configs.commands.visual) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local selected = helpers.visual_select()
            log.debug(
                "|fzfx.files - setup| command:%s, selected:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(selected),
                vim.inspect(opts)
            )
            return files(
                selected,
                opts.bang,
                command_configs.unrestricted and { unrestricted = true }
                    or { unrestricted = false }
            )
        end, command_configs.opts)
    end
    for _, command_configs in pairs(files_configs.commands.cword) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.files - setup| command:%s, word:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(word),
                vim.inspect(opts)
            )
            return files(
                word,
                opts.bang,
                command_configs.unrestricted and { unrestricted = true }
                    or { unrestricted = false }
            )
        end, command_configs.opts)
    end
    for _, command_configs in pairs(files_configs.commands.put) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local yank = yank_history.get_yank()
            log.debug(
                "|fzfx.files - setup| command:%s, yank:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(yank),
                vim.inspect(opts)
            )
            return files(
                (yank ~= nil and type(yank.regtext) == "string")
                        and yank.regtext
                    or "",
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
