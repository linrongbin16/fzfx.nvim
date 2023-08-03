local log = require("fzfx.log")
local utils = require("fzfx.utils")
local path = require("fzfx.path")
local conf = require("fzfx.config")
local popup = require("fzfx.popup")

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
    return path.normalize(shorten_path)
end

--- @param query string
--- @param bang boolean|integer
--- @param opts Config
--- @return PopupFzf
local function files(query, bang, opts)
    local files_configs = conf.get_config().files
    -- action
    local umode_action =
        string.lower(files_configs.actions.builtin.unrestricted_mode)
    local rmode_action =
        string.lower(files_configs.actions.builtin.restricted_mode)

    --- @type table<string, FileSwitch>
    local runtime = {
        --- @type FileSwitch
        provider = utils.new_file_switch("files_provider", {
            opts.unrestricted and files_configs.providers.unrestricted
                or files_configs.providers.restricted,
        }, {
            opts.unrestricted and files_configs.providers.restricted
                or files_configs.providers.unrestricted,
        }),
    }
    log.debug("|fzfx.files - files| runtime:%s", vim.inspect(runtime))

    -- query command, both initial query + reload query
    local nvim_path = conf.get_config().env.nvim
    local query_command = string.format(
        "%s %s",
        utils.run_lua_script(path.join("files", "provider.lua"), nvim_path),
        runtime.provider.value
    )
    local preview_command = string.format(
        "%s {}",
        utils.run_lua_script(path.join("files", "previewer.lua"), nvim_path)
    )
    log.debug(
        "|fzfx.files - files| query_command:%s, preview_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--header",
            opts.unrestricted and Context.rmode_header or Context.umode_header,
        },
        {
            "--prompt",
            short_path() .. " ",
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
                runtime.provider:switch(),
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
                runtime.provider:switch(),
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
    local actions = files_configs.actions.expect
    local popup_win = popup.new_popup_window()
    local popup_fzf =
        popup.new_popup_fzf(popup_win, query_command, fzf_opts, actions)

    return popup_fzf
end

local function setup()
    local files_configs = conf.get_config().files

    log.debug(
        "|fzfx.files - setup| base_dir:%s, files_configs:%s",
        vim.inspect(path.base_dir()),
        vim.inspect(files_configs)
    )

    local umode_action = files_configs.actions.builtin.unrestricted_mode
    local rmode_action = files_configs.actions.builtin.restricted_mode

    -- Context
    Context.umode_header = utils.unrestricted_mode_header(umode_action)
    Context.rmode_header = utils.restricted_mode_header(rmode_action)

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
            local selected = utils.visual_select()
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
end

local M = {
    setup = setup,
}

return M
