local log = require("fzfx.log")
local Popup = require("fzfx.popup").Popup
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")
local color = require("fzfx.color")
local utils = require("fzfx.utils")

--- @param query string
--- @param bang boolean
--- @param general_configs Configs
--- @param default_pipeline PipelineName?
--- @return Popup
local function general(query, bang, general_configs, default_pipeline)
    --- @type PipelineContext
    local pipeline_context = {
        bufnr = vim.api.nvim_get_current_buf(),
        winnr = vim.api.nvim_get_current_win(),
        tabnr = vim.api.nvim_get_current_tabpage(),
    }

    -- provider
    local providers_map = {}
    local provider_types_map = {}
    for pipeline, provider_opts in pairs(general_configs.providers) do
        local provider = provider_opts[2]
        local provider_type = provider_opts[3] or "plain"
        providers_map[pipeline] = provider
        provider_types_map[pipeline] = provider_type
    end
    local default_provider_action_key = nil
    if default_pipeline == nil then
        local pipeline, provider_opts = next(general_configs.providers)
        default_pipeline = pipeline
        default_provider_action_key = provider_opts[1]
    else
        local provider_opts = general_configs.providers[default_pipeline]
        default_provider_action_key = provider_opts[1]
    end

    --- @type ProviderSwitch
    local provider_switch = helpers.ProviderSwitch:new(
        "general",
        default_pipeline,
        providers_map,
        provider_types_map,
        pipeline_context,
        query
    )

    -- previewer
    local previewers_map = {}
    local previewer_types_map = {}
    for pipeline, previewer_opts in pairs(general_configs.previewers) do
        local previewer = previewer_opts[1]
        local previewer_type = previewer_opts[2]
        previewers_map[pipeline] = previewer
        previewer_types_map[pipeline] = previewer_type
    end

    --- @type PreviewerSwitch
    local previewer_switch = helpers.PreviewerSwitch:new(
        "general",
        default_pipeline,
        previewers_map,
        previewer_types_map,
        pipeline_context
    )

    local query_command = string.format(
        "%s %s %s %s",
        shell.make_lua_command("general", "provider.lua"),
        provider_switch.metafile,
        provider_switch.resultfile,
        utils.shellescape(query)
    )
    local reload_query_command = string.format(
        "%s %s %s {q}",
        shell.make_lua_command("general", "provider.lua"),
        provider_switch.metafile,
        provider_switch.resultfile
    )
    local preview_command = string.format(
        "%s %s %s {}",
        shell.make_lua_command("general", "previewer.lua"),
        previewer_switch.metafile,
        previewer_switch.resultfile
    )
    log.debug(
        "|fzfx.general - general| query_command:%s, preview_command:%s",
        vim.inspect(query_command),
        vim.inspect(preview_command)
    )
    local fzf_opts = {
        { "--query", query },
        {
            "--preview",
            preview_command,
        },
    }
    local header_builder = {}
    for pipeline, provider_opts in pairs(general_configs.providers) do
        local switch_pipeline_key = string.lower(provider_opts[1])
        table.insert(
            header_builder,
            color.render(
                "%s to %s",
                color.magenta,
                string.upper(switch_pipeline_key),
                table.concat(vim.fn.split(pipeline, "_"), " ")
            )
        )
    end
    local headers = ":: Press " .. table.concat(header_builder, ", ")
    for pipeline, provider_opts in pairs(general_configs.providers) do
        local switch_pipeline_key = string.lower(provider_opts[1])
        local function switch_pipeline_callback(query_params)
            provider_switch:switch(pipeline, query_params)
            previewer_switch:switch(pipeline)
        end
        local switch_pipeline_registry_id =
            server.get_global_rpc_server():register(switch_pipeline_callback)
        local switch_pipeline_command = string.format(
            "%s %s",
            shell.make_lua_command("rpc", "client.lua"),
            switch_pipeline_registry_id
        )
        local bind_builder = string.format(
            "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+reload(%s)",
            switch_pipeline_key,
            switch_pipeline_key,
            switch_pipeline_command,
            headers,
            reload_query_command
        )
        for pipeline2, provider_opts2 in pairs(general_configs.providers) do
            if pipeline2 ~= pipeline then
                local switch_pipeline_key2 = string.lower(provider_opts2[1])
                bind_builder = bind_builder
                    .. string.format("+rebind(%s)", switch_pipeline_key2)
            end
        end
        table.insert(fzf_opts, {
            "--bind",
            bind_builder,
        })
    end
    table.insert(fzf_opts, {
        "--bind",
        string.format("start:unbind(%s)", default_provider_action_key),
    })
    table.insert(fzf_opts, { "--preview", preview_command })

    fzf_opts = vim.list_extend(fzf_opts, vim.deepcopy(general_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = general_configs.actions
    local p = Popup:new(
        bang and { height = 1, width = 1, row = 0, col = 0 } or nil,
        query_command,
        fzf_opts,
        actions
    )
    return p
end

--- @param general_configs Configs?
local function setup(general_configs)
    if not general_configs then
        return
    end

    -- User commands
    for _, command_configs in pairs(general_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
            -- log.debug(
            --     "|fzfx.general - setup| command:%s, opts:%s",
            --     vim.inspect(command_configs.name),
            --     vim.inspect(opts)
            -- )
            local query = helpers.get_command_feed(opts, command_configs.feed)
            return general(
                query,
                opts.bang,
                general_configs,
                command_configs.default_provider
            )
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
