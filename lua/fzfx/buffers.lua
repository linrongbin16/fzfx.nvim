local log = require("fzfx.log")
local conf = require("fzfx.config")
local Popup = require("fzfx.popup").Popup
local Launch = require("fzfx.launch").Launch
local shell = require("fzfx.shell")
local color = require("fzfx.color")
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")
local utils = require("fzfx.utils")

local Context = {
    --- @type string?
    bdelete_key = nil,
    --- @type string?
    bdelete_header = nil,
}

--- @param query string
--- @param bang boolean
--- @param opts Configs?
--- @return Launch
local function buffers(query, bang, opts)
    local buffers_configs = conf.get_config().buffers

    -- action
    local bdelete_action = buffers_configs.interactions[2]
    local buf_provider = buffers_configs.providers

    local provider_switch = helpers.ProviderSwitch:new(
        "buffers",
        { [buf_provider[1]] = buf_provider[2] },
        { [buf_provider[1]] = buf_provider[3] },
        buf_provider[1],
        query
    )

    -- rpc
    local function collect_bufs_rpc_callback()
        provider_switch:switch(buf_provider[1])
    end

    local collect_bufs_rpc_callback_id =
        server.get_global_rpc_server():register(collect_bufs_rpc_callback)

    local function bdelete_rpc_callback(params)
        log.debug(
            "|fzfx.buffers - buffers.bdelete_rpc_callback| params:%s",
            vim.inspect(params)
        )
        if type(params) == "string" then
            params = { params }
        end
        bdelete_action(params)
    end
    local bdelete_rpc_callback_id =
        server.get_global_rpc_server():register(bdelete_rpc_callback)

    -- query command, both initial query + reload query
    local query_command = string.format(
        "%s %s %s",
        shell.make_lua_command("buffers", "provider.lua"),
        collect_bufs_rpc_callback_id,
        provider_switch.tempfile
    )
    local preview_command =
        string.format("%s {}", shell.make_lua_command("files", "previewer.lua"))
    local bdelete_rpc_command = string.format(
        "%s %s {}",
        shell.make_lua_command("rpc", "client.lua"),
        bdelete_rpc_callback_id
    )

    log.debug(
        "|fzfx.buffers - files| query_command:%s, preview_command:%s, bdelete_rpc_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command),
        vim.inspect(bdelete_rpc_command)
    )

    local fzf_opts = {
        { "--query", query },
        {
            "--header",
            Context.bdelete_header,
        },
        {
            -- bdelete action: delete buffer, reload query
            "--bind",
            string.format(
                "%s:execute-silent(%s)+reload(%s)",
                Context.bdelete_key,
                bdelete_rpc_command,
                query_command
            ),
        },
        {
            "--preview",
            preview_command,
        },
    }

    fzf_opts = vim.list_extend(fzf_opts, vim.deepcopy(buffers_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = buffers_configs.actions
    local ppp =
        Popup:new(bang and { height = 1, width = 1, row = 0, col = 0 } or nil)
    local launch = Launch:new(ppp, query_command, fzf_opts, actions, function()
        server.get_global_rpc_server():unregister(collect_bufs_rpc_callback_id)
        server.get_global_rpc_server():unregister(bdelete_rpc_callback_id)
    end)

    return launch
end

local function setup()
    local buffers_configs = conf.get_config().buffers
    if not buffers_configs then
        return
    end

    -- Context
    Context.bdelete_key = string.lower(buffers_configs.interactions[1])
    Context.bdelete_header = color.delete_buffer_header(Context.bdelete_key)

    -- User commands
    for _, command_configs in pairs(buffers_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            local query = helpers.get_command_feed(opts, command_configs.feed)
            return buffers(query, opts.bang, nil)
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
