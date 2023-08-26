local log = require("fzfx.log")
local Popup = require("fzfx.popup").Popup
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")
local color = require("fzfx.color")
local utils = require("fzfx.utils")
local env = require("fzfx.env")
local path = require("fzfx.path")

-- provider switch {

--- @class ProviderSwitch
--- @field current_pipeline PipelineName?
--- @field providers table<PipelineName, Provider>?
--- @field provider_types table<PipelineName, ProviderType>?
--- @field context PipelineContext?
--- @field metafile string?
--- @field resultfile string?
local ProviderSwitch = {
    current_pipeline = nil,
    providers = nil,
    provider_types = nil,
    context = nil,
    metafile = nil,
    resultfile = nil,
}

--- @package
--- @param pipeline PipelineName
--- @param providers table<PipelineName, Provider>
--- @param provider_types table<PipelineName, ProviderType>
--- @param context PipelineContext?
--- @param query string?
--- @param metafile string
--- @param resultfile string
--- @return ProviderType
local function provider_switch_dump(
    pipeline,
    providers,
    provider_types,
    context,
    query,
    metafile,
    resultfile
)
    local provider = providers[pipeline]
    local provider_type = provider_types[pipeline]
    log.ensure(
        type(provider) == "string" or type(provider) == "function",
        "|fzfx.helpers - provider_switch_dump| invalid provider! providers:%s, pipeline:%s",
        vim.inspect(providers),
        vim.inspect(pipeline)
    )
    log.ensure(
        provider_type == "plain"
            or provider_type == "command"
            or provider_type == "list",
        "|fzfx.helpers - provider_switch_dump| invalid provider! provider_types:%s, pipeline:%s",
        vim.inspect(provider_types),
        vim.inspect(pipeline)
    )
    local metajson = vim.fn.json_encode({
        pipeline = pipeline,
        provider_type = provider_type,
    })
    vim.fn.writefile({ metajson }, metafile)
    if provider_type == "plain" then
        log.ensure(
            type(provider) == "string",
            "|fzfx.helpers - provider_switch_dump| plain provider must be string! providers:%s pipeline:%s, provider:%s",
            vim.inspect(providers),
            vim.inspect(pipeline),
            vim.inspect(provider)
        )
        vim.fn.writefile({ provider }, resultfile)
    elseif provider_type == "command" then
        local result = provider(query, context)
        log.ensure(
            type(result) == "string",
            "|fzfx.helpers - provider_switch_dump| command provider result must be string! providers:%s pipeline:%s, result:%s",
            vim.inspect(providers),
            vim.inspect(pipeline),
            vim.inspect(result)
        )
        vim.fn.writefile({ result }, resultfile)
    elseif provider_type == "list" then
        local result = provider(query, context)
        log.ensure(
            type(result) == "table",
            "|fzfx.helpers - provider_switch_dump| list provider result must be array! providers:%s, pipeline:%s, result:%s",
            vim.inspect(providers),
            vim.inspect(pipeline),
            vim.inspect(result)
        )
        vim.fn.writefile(result, resultfile)
    else
        log.throw(
            "|fzfx.helpers - provider_switch_dump| error! invalid provider type, provider_types:%s, pipeline:%s",
            vim.inspect(provider_types),
            vim.inspect(pipeline)
        )
    end
    return provider_type
end

--- @param name string
--- @param current_pipeline PipelineName
--- @param providers table<PipelineName, Provider>
--- @param provider_types table<PipelineName, ProviderType>
--- @param context PipelineContext?
--- @param query string?
--- @return ProviderSwitch
function ProviderSwitch:new(
    name,
    current_pipeline,
    providers,
    provider_types,
    context,
    query
)
    local ps = vim.tbl_deep_extend("force", vim.deepcopy(ProviderSwitch), {
        current_pipeline = current_pipeline,
        providers = providers,
        provider_types = provider_types,
        context = context,
        metafile = env.debug_enable() and path.join(
            vim.fn.stdpath("data"),
            "fzfx.nvim",
            "provider_switch_metafile_" .. name
        ) or vim.fn.tempname(),
        resultfile = env.debug_enable() and path.join(
            vim.fn.stdpath("data"),
            "fzfx.nvim",
            "provider_switch_resultfile_" .. name
        ) or vim.fn.tempname(),
    })
    provider_switch_dump(
        current_pipeline,
        providers,
        provider_types,
        context,
        query,
        ps.metafile,
        ps.resultfile
    )
    return ps
end

--- @param next_pipeline PipelineName
--- @param query string?
--- @return ProviderType
function ProviderSwitch:switch(next_pipeline, query)
    return provider_switch_dump(
        next_pipeline,
        self.providers,
        self.provider_types,
        self.context,
        query,
        self.metafile,
        self.resultfile
    )
end

-- provider switch }

-- previewer switch {

--- @class PreviewerSwitch
--- @field current_pipeline PipelineName?
--- @field previewers table<PipelineName, Previewer>?
--- @field previewer_types table<PipelineName, PreviewerType>?
--- @field metafile string?
--- @field resultfile string?
local PreviewerSwitch = {
    current_pipeline = nil,
    previewers = nil,
    previewer_types = nil,
    context = nil,
    metafile = nil,
    resultfile = nil,
}

--- @param name string
--- @param current_pipeline PipelineName
--- @param previewers table<PipelineName, Previewer>
--- @param previewer_types table<PipelineName, PreviewerType>
--- @param context PipelineContext?
--- @return PreviewerSwitch
function PreviewerSwitch:new(
    name,
    current_pipeline,
    previewers,
    previewer_types,
    context
)
    local ps = vim.tbl_deep_extend("force", vim.deepcopy(PreviewerSwitch), {
        current_pipeline = current_pipeline,
        previewers = previewers,
        previewer_types = previewer_types,
        context = context,
        metafile = env.debug_enable() and path.join(
            vim.fn.stdpath("data"),
            "fzfx.nvim",
            "previewer_switch_metafile_" .. name
        ) or vim.fn.tempname(),
        resultfile = env.debug_enable() and path.join(
            vim.fn.stdpath("data"),
            "fzfx.nvim",
            "previewer_switch_resultfile_" .. name
        ) or vim.fn.tempname(),
    })
    return ps
end

--- @param next_pipeline PipelineName
--- @return nil
function PreviewerSwitch:switch(next_pipeline)
    self.current_pipeline = next_pipeline
end

--- @param line string
--- @return PreviewerType
function PreviewerSwitch:preview(line)
    local previewer = self.previewers[self.current_pipeline]
    local previewer_type = self.previewer_types[self.current_pipeline]
    log.ensure(
        type(previewer) == "function",
        "|fzfx.helpers - previewer_switch_dump| invalid previewer! previewers:%s, pipeline:%s",
        vim.inspect(self.previewers),
        vim.inspect(self.current_pipeline)
    )
    log.ensure(
        previewer_type == "command" or previewer_type == "list",
        "|fzfx.helpers - previewer_switch_dump| invalid previewer_type! previewer_types:%s, pipeline:%s",
        vim.inspect(self.previewer_types),
        vim.inspect(self.current_pipeline)
    )
    local metajson = vim.fn.json_encode({
        pipeline = self.current_pipeline,
        previewer_type = previewer_type,
    })
    vim.fn.writefile({ metajson }, self.metafile)
    if previewer_type == "command" then
        local result = previewer(line, self.context, self.current_pipeline)
        log.ensure(
            type(result) == "string",
            "|fzfx.helpers - previewer_switch_dump| command previewer result must be string! previewers:%s pipeline:%s, result:%s",
            vim.inspect(self.previewers),
            vim.inspect(self.current_pipeline),
            vim.inspect(result)
        )
        vim.fn.writefile({ result }, self.resultfile)
    elseif previewer_type == "list" then
        local result = previewer(line, self.context, self.current_pipeline)
        log.ensure(
            type(result) == "table",
            "|fzfx.helpers - previewer_switch_dump| list previewer result must be array! previewers:%s, pipeline:%s, result:%s",
            vim.inspect(self.previewers),
            vim.inspect(self.current_pipeline),
            vim.inspect(result)
        )
        vim.fn.writefile(result, self.resultfile)
    else
        log.throw(
            "|fzfx.helpers - previewer_switch_dump| error! invalid previewer type, previewer_types:%s, pipeline:%s",
            vim.inspect(self.previewer_types),
            vim.inspect(self.current_pipeline)
        )
    end
    return previewer_type
end

-- previewer switch }

--- @param pipeline_configs Configs
local function get_pipeline_size(pipeline_configs)
    local n = 0
    if type(pipeline_configs) == "table" then
        for _, _ in pairs(pipeline_configs.providers) do
            n = n + 1
        end
    end
    return n
end

--- @param query string
--- @param bang boolean
--- @param pipeline_configs Configs
--- @param default_pipeline PipelineName?
--- @return Popup
local function general(query, bang, pipeline_configs, default_pipeline)
    --- @type PipelineContext
    local pipeline_context = {
        bufnr = vim.api.nvim_get_current_buf(),
        winnr = vim.api.nvim_get_current_win(),
        tabnr = vim.api.nvim_get_current_tabpage(),
    }

    local pipeline_size = get_pipeline_size(pipeline_configs)

    -- provider
    local providers_map = {}
    local provider_types_map = {}
    for pipeline, provider_opts in pairs(pipeline_configs.providers) do
        local provider = provider_opts.provider
        local provider_type = provider_opts.provider_type or "plain"
        providers_map[pipeline] = provider
        provider_types_map[pipeline] = provider_type
    end
    local default_provider_action_key = nil
    if default_pipeline == nil then
        local pipeline, provider_opts = next(pipeline_configs.providers)
        default_pipeline = pipeline
        default_provider_action_key = provider_opts.key
    else
        local provider_opts = pipeline_configs.providers[default_pipeline]
        default_provider_action_key = provider_opts.key
    end

    --- @type ProviderSwitch
    local provider_switch = ProviderSwitch:new(
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
    for pipeline, previewer_opts in pairs(pipeline_configs.previewers) do
        local previewer = previewer_opts.previewer
        local previewer_type = previewer_opts.previewer_type
        previewers_map[pipeline] = previewer
        previewer_types_map[pipeline] = previewer_type
    end

    --- @type PreviewerSwitch
    local previewer_switch = PreviewerSwitch:new(
        "general",
        default_pipeline,
        previewers_map,
        previewer_types_map,
        pipeline_context
    )

    --- @param line_param string
    local function preview_rpc(line_param)
        previewer_switch:preview(line_param)
    end

    local preview_rpc_registry_id =
        server:get_global_rpc_server():register(preview_rpc)

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
        "%s %s %s %s {}",
        shell.make_lua_command("general", "previewer.lua"),
        preview_rpc_registry_id,
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

    -- only have 1 pipeline, no need to add help message and switch keys
    if pipeline_size > 1 then
        local header_builder = {}
        for pipeline, provider_opts in pairs(pipeline_configs.providers) do
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

        for pipeline, provider_opts in pairs(pipeline_configs.providers) do
            local switch_pipeline_key = string.lower(provider_opts[1])
            local function switch_pipeline_callback(query_params)
                provider_switch:switch(pipeline, query_params)
                previewer_switch:switch(pipeline)
            end
            local switch_pipeline_registry_id = server
                .get_global_rpc_server()
                :register(switch_pipeline_callback)
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
            for pipeline2, provider_opts2 in pairs(pipeline_configs.providers) do
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
    end

    table.insert(fzf_opts, { "--preview", preview_command })

    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(pipeline_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = pipeline_configs.actions
    local p = Popup:new(
        bang and { height = 1, width = 1, row = 0, col = 0 } or nil,
        query_command,
        fzf_opts,
        actions,
        function()
            server.get_global_rpc_server():unregister(preview_rpc_registry_id)
        end
    )
    return p
end

--- @param pipeline_configs Configs?
local function setup(pipeline_configs)
    if not pipeline_configs then
        return
    end

    -- User commands
    for _, command_configs in pairs(pipeline_configs.commands) do
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
                pipeline_configs,
                command_configs.default_provider
            )
        end, command_configs.opts)
    end
end

local M = {
    setup = setup,
}

return M
