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
    deletebuf_header = nil,
}

--- @param query string
--- @param bang boolean
--- @param opts Config?
--- @return Launch
local function buffers(query, bang, opts)
    local buffers_configs = conf.get_config().buffers
    -- action
    local deletebuf_action =
        string.lower(buffers_configs.actions.builtin.delete_buffer)

    -- rpc callback
    local function collect_buffers_rpc_callback(context)
        log.debug(
            "|fzfx.buffers - buffers.collect_buffers_rpc_callback| context:%s",
            vim.inspect(context)
        )
    end
    local collect_buffers_rpc_callback_id =
        server.get_global_rpc_server():register(collect_buffers_rpc_callback)

    local function delete_buffer_rpc_callback(context)
        log.debug(
            "|fzfx.buffers - buffers.delete_buffer_rpc_callback| context:%s",
            vim.inspect(context)
        )
    end
    local delete_buffer_rpc_callback_id =
        server.get_global_rpc_server():register(delete_buffer_rpc_callback)

    -- query command, both initial query + reload query
    local query_rpc_command = string.format(
        "%s %s",
        shell.make_lua_command("rpc", "client.lua"),
        collect_buffers_rpc_callback_id
    )
    local preview_command =
        string.format("%s {}", shell.make_lua_command("files", "previewer.lua"))
    local deletebuf_rpc_command = string.format(
        "%s %s {}",
        shell.make_lua_command("rpc", "client.lua"),
        delete_buffer_rpc_callback_id
    )

    log.debug(
        "|fzfx.buffers - files| query_command:%s, preview_command:%s, deletebuf_rpc_command:%s",
        vim.inspect(query_rpc_command),
        vim.inspect(preview_command),
        vim.inspect(deletebuf_rpc_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--header",
            Context.deletebuf_header,
        },
        {
            "--prompt",
            "Buffers > ",
        },
        {
            -- deletebuf action: delete buffer, reload query
            "--bind",
            string.format(
                "%s:execute-silent(%s)+reload(%s)",
                deletebuf_action,
                deletebuf_rpc_command,
                query_rpc_command
            ),
        },
        {
            "--preview",
            preview_command,
        },
    }
    fzf_opts = vim.list_extend(fzf_opts, vim.deepcopy(buffers_configs.fzf_opts))
    local actions = buffers_configs.actions.expect
    local ppp =
        Popup:new(bang and { height = 1, width = 1, row = 0, col = 0 } or nil)
    local launch = Launch:new(
        ppp,
        query_rpc_command,
        fzf_opts,
        actions,
        function()
            server
                .get_global_rpc_server()
                :unregister(collect_buffers_rpc_callback_id)
            server
                .get_global_rpc_server()
                :unregister(delete_buffer_rpc_callback_id)
        end
    )

    return launch
end

local function setup()
    local buffers_configs = conf.get_config().buffers

    log.debug(
        "|fzfx.buffers - setup| base_dir:%s, buffers_configs:%s",
        vim.inspect(path.base_dir()),
        vim.inspect(buffers_configs)
    )

    -- Context
    local deletebuf_action = buffers_configs.actions.builtin.delete_buffer
    Context.deletebuf_header = color.delete_buffer_header(deletebuf_action)

    -- User commands
    for _, command_configs in pairs(buffers_configs.commands.normal) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            log.debug(
                "|fzfx.buffers - setup| command:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(opts)
            )
            return buffers(opts.args, opts.bang, nil)
        end, command_configs.opts)
    end
    for _, command_configs in pairs(buffers_configs.commands.visual) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local selected = helpers.visual_select()
            log.debug(
                "|fzfx.buffers - setup| command:%s, selected:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(selected),
                vim.inspect(opts)
            )
            return buffers(selected, opts.bang, nil)
        end, command_configs.opts)
    end
    for _, command_configs in pairs(buffers_configs.commands.cword) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local word = vim.fn.expand("<cword>")
            log.debug(
                "|fzfx.buffers - setup| command:%s, word:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(word),
                vim.inspect(opts)
            )
            return buffers(word, opts.bang, nil)
        end, command_configs.opts)
    end
    for _, command_configs in pairs(buffers_configs.commands.put) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local yank = yank_history.get_yank()
            log.debug(
                "|fzfx.buffers - setup| command:%s, yank:%s, opts:%s",
                vim.inspect(command_configs.name),
                vim.inspect(yank),
                vim.inspect(opts)
            )
            return buffers(
                (yank ~= nil and type(yank.regtext) == "string")
                        and yank.regtext
                    or "",
                opts.bang,
                nil
            )
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
