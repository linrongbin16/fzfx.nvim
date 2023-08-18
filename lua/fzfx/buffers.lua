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
local utils = require("fzfx.utils")

local Context = {
    --- @type string?
    bdelete_key = nil,
    --- @type string?
    bdelete_header = nil,
    --- @type table<string, boolean>?
    exclude_filetypes = nil,
}

--- @param bufnr integer
--- @return boolean
local function buf_exclude(bufnr)
    if Context.exclude_filetypes == nil then
        Context.exclude_filetypes = {}
        local exclude_filetypes =
            conf.get_config().buffers.other_opts.exclude_filetypes
        if type(exclude_filetypes) == "table" and #exclude_filetypes > 0 then
            for _, ft in ipairs(exclude_filetypes) do
                Context.exclude_filetypes[ft] = true
            end
        end
    end
    local ft = utils.get_buf_option(bufnr, "filetype")
    return Context.exclude_filetypes[ft] ~= nil
end

--- @param bufnr integer
--- @return boolean
local function buf_valid(bufnr)
    return utils.buffer_valid(bufnr) and not buf_exclude(bufnr)
end

--- @param bufnr integer
--- @return string
local function buf_path(bufnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    return vim.fn.fnamemodify(bufname, ":~:.")
end

-- rpc callback
local function collect_buffers_rpc_callback()
    local current_bufnr = vim.api.nvim_get_current_buf()
    local bufs_list = vim.api.nvim_list_bufs()
    -- log.debug(
    --     "|fzfx.buffers - buffers.collect_buffers_rpc_callback| current_bufnr:%s, bufs_list:%s",
    --     vim.inspect(current_bufnr),
    --     vim.inspect(bufs_list)
    -- )
    local filtered_bufs_list = {}
    if buf_valid(current_bufnr) then
        table.insert(filtered_bufs_list, buf_path(current_bufnr))
    end
    if type(bufs_list) == "table" then
        for _, bufnr in ipairs(bufs_list) do
            -- log.debug(
            --     "|fzfx.buffers - buffers.collect_buffers_rpc_callback| 1-bufnr:%s, name:%s, buf ft:%s",
            --     vim.inspect(bufnr),
            --     vim.inspect(vim.api.nvim_buf_get_name(bufnr)),
            --     vim.inspect(utils.get_buf_option(bufnr, "filetype"))
            -- )
            -- log.debug(
            --     "|fzfx.buffers - buffers.collect_buffers_rpc_callback| 1-valid:%s, loaded:%s, buflisted:%s",
            --     vim.inspect(vim.api.nvim_buf_is_valid(bufnr)),
            --     vim.inspect(vim.api.nvim_buf_is_loaded(bufnr)),
            --     vim.inspect(vim.fn.buflisted(bufnr))
            -- )
            if buf_valid(bufnr) and bufnr ~= current_bufnr then
                table.insert(filtered_bufs_list, buf_path(bufnr))
            end
        end
    end
    return filtered_bufs_list
end

--- @param query string
--- @param bang boolean
--- @param opts Configs?
--- @return Launch
local function buffers(query, bang, opts)
    local buffers_configs = conf.get_config().buffers

    -- action
    local bdelete_action = buffers_configs.actions.builtin.delete_buffer[2]

    -- rpc
    local collect_buffers_rpc_callback_id =
        server.get_global_rpc_server():register(collect_buffers_rpc_callback)

    local function delete_buffer_rpc_callback(params)
        log.debug(
            "|fzfx.buffers - buffers.delete_buffer_rpc_callback| params:%s",
            vim.inspect(params)
        )
        if type(params) == "string" then
            params = { params }
        end
        bdelete_action(params)
    end
    local delete_buffer_rpc_callback_id =
        server.get_global_rpc_server():register(delete_buffer_rpc_callback)

    -- query command, both initial query + reload query
    local query_command = string.format(
        "%s %s",
        shell.make_lua_command("buffers", "provider.lua"),
        collect_buffers_rpc_callback_id
    )
    local preview_command =
        string.format("%s {}", shell.make_lua_command("files", "previewer.lua"))
    local bdelete_rpc_command = string.format(
        "%s %s {}",
        shell.make_lua_command("rpc", "client.lua"),
        delete_buffer_rpc_callback_id
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
    local actions = buffers_configs.actions
    local ppp =
        Popup:new(bang and { height = 1, width = 1, row = 0, col = 0 } or nil)
    local launch = Launch:new(ppp, query_command, fzf_opts, actions, function()
        server
            .get_global_rpc_server()
            :unregister(collect_buffers_rpc_callback_id)
        server.get_global_rpc_server():unregister(delete_buffer_rpc_callback_id)
    end)

    return launch
end

local function setup()
    local buffers_configs = conf.get_config().buffers
    if not buffers_configs then
        return
    end

    -- Context
    Context.bdelete_key = buffers_configs.interactions.bdelete[1]
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
