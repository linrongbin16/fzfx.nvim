local log = require("fzfx.log")
local Popup = require("fzfx.popup").Popup
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")
local color = require("fzfx.color")
local utils = require("fzfx.utils")
local env = require("fzfx.env")
local path = require("fzfx.path")
local ProviderTypeEnum = require("fzfx.meta").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.meta").PreviewerTypeEnum

-- provider switch {

--- @class ProviderSwitch
--- @field pipeline PipelineName?
--- @field providers table<PipelineName, Provider>?
--- @field provider_types table<PipelineName, ProviderType>?
--- @field metafile string?
--- @field resultfile string?
local ProviderSwitch = {
    pipeline = nil,
    providers = nil,
    provider_types = nil,
    metafile = nil,
    resultfile = nil,
}

--- @param name string
--- @param pipeline PipelineName
--- @param provider_configs Configs
--- @return ProviderSwitch
function ProviderSwitch:new(name, pipeline, provider_configs)
    local providers_map = {}
    local provider_types_map = {}
    for provider_name, provider_opts in pairs(provider_configs) do
        local provider = provider_opts.provider
        local provider_type = provider_opts.provider_type or "plain"
        providers_map[provider_name] = provider
        provider_types_map[provider_name] = provider_type
    end
    return vim.tbl_deep_extend("force", vim.deepcopy(ProviderSwitch), {
        pipeline = pipeline,
        providers = providers_map,
        provider_types = provider_types_map,
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
end

--- @param next_pipeline PipelineName
--- @return nil
function ProviderSwitch:switch(next_pipeline)
    self.pipeline = next_pipeline
end

--- @param query string?
--- @param context PipelineContext?
function ProviderSwitch:provide(query, context)
    local provider = self.providers[self.pipeline]
    local provider_type = self.provider_types[self.pipeline]
    log.ensure(
        type(provider) == "string" or type(provider) == "function",
        "|fzfx.general - ProviderSwitch:provide| invalid provider! %s",
        vim.inspect(self)
    )
    log.ensure(
        provider_type == ProviderTypeEnum.PLAIN
            or provider_type == ProviderTypeEnum.COMMAND
            or provider_type == ProviderTypeEnum.LIST,
        "|fzfx.general - ProviderSwitch:provide| invalid provider type! %s",
        vim.inspect(self)
    )
    local metajson = vim.fn.json_encode({
        pipeline = self.pipeline,
        provider_type = provider_type,
    })
    vim.fn.writefile({ metajson }, self.metafile)
    if provider_type == ProviderTypeEnum.PLAIN then
        log.ensure(
            type(provider) == "string",
            "|fzfx.general - ProviderSwitch:provide| plain provider must be string! self:%s, provider:%s",
            vim.inspect(self),
            vim.inspect(provider)
        )
        vim.fn.writefile({ provider }, self.resultfile)
    elseif provider_type == ProviderTypeEnum.COMMAND then
        local result = provider(query, context)
        log.ensure(
            type(result) == "string",
            "|fzfx.general - ProviderSwitch:provide| command provider result must be string! self:%s, result:%s",
            vim.inspect(self),
            vim.inspect(result)
        )
        vim.fn.writefile({ result }, self.resultfile)
    elseif provider_type == ProviderTypeEnum.LIST then
        local result = provider(query, context)
        log.ensure(
            type(result) == "table",
            "|fzfx.general - ProviderSwitch:provide| list provider result must be array! self:%s, result:%s",
            vim.inspect(self),
            vim.inspect(result)
        )
        vim.fn.writefile(result, self.resultfile)
    else
        log.throw(
            "|fzfx.general - ProviderSwitch:provide| error! invalid provider type! %s",
            vim.inspect(self)
        )
    end
    return provider_type
end

-- provider switch }

-- previewer switch {

--- @class PreviewerSwitch
--- @field pipeline PipelineName?
--- @field previewers table<PipelineName, Previewer>?
--- @field previewer_types table<PipelineName, PreviewerType>?
--- @field metafile string?
--- @field resultfile string?
local PreviewerSwitch = {
    pipeline = nil,
    previewers = nil,
    previewer_types = nil,
    metafile = nil,
    resultfile = nil,
}

--- @param name string
--- @param pipeline PipelineName
--- @param previewer_configs Configs
--- @return PreviewerSwitch
function PreviewerSwitch:new(name, pipeline, previewer_configs)
    local previewers_map = {}
    local previewer_types_map = {}
    for previewer_name, previewer_opts in pairs(previewer_configs) do
        local previewer = previewer_opts.previewer
        local previewer_type = previewer_opts.previewer_type
        previewers_map[previewer_name] = previewer
        previewer_types_map[previewer_name] = previewer_type
    end
    return vim.tbl_deep_extend("force", vim.deepcopy(PreviewerSwitch), {
        pipeline = pipeline,
        previewers = previewers_map,
        previewer_types = previewer_types_map,
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
end

--- @param next_pipeline PipelineName
--- @return nil
function PreviewerSwitch:switch(next_pipeline)
    self.pipeline = next_pipeline
end

--- @param line string
--- @param context PipelineContext?
--- @return PreviewerType
function PreviewerSwitch:preview(line, context)
    local previewer = self.previewers[self.pipeline]
    local previewer_type = self.previewer_types[self.pipeline]
    log.ensure(
        type(previewer) == "function",
        "|fzfx.general - PreviewerSwitch:preview| invalid previewer! %s",
        vim.inspect(self)
    )
    log.ensure(
        previewer_type == PreviewerTypeEnum.COMMAND
            or previewer_type == PreviewerTypeEnum.LIST,
        "|fzfx.general - PreviewerSwitch:preview| invalid previewer_type! %s",
        vim.inspect(self)
    )
    local metajson = vim.fn.json_encode({
        pipeline = self.pipeline,
        previewer_type = previewer_type,
    })
    vim.fn.writefile({ metajson }, self.metafile)
    if previewer_type == PreviewerTypeEnum.COMMAND then
        local result = previewer(line, context, self.pipeline)
        log.ensure(
            type(result) == "string",
            "|fzfx.general - PreviewerSwitch:preview| command previewer result must be string! self:%s, result:%s",
            vim.inspect(self),
            vim.inspect(result)
        )
        vim.fn.writefile({ result }, self.resultfile)
    elseif previewer_type == PreviewerTypeEnum.LIST then
        local result = previewer(line, context, self.pipeline)
        log.ensure(
            type(result) == "table",
            "|fzfx.general - PreviewerSwitch:preview| list previewer result must be array! self:%s, result:%s",
            vim.inspect(self),
            vim.inspect(result)
        )
        vim.fn.writefile(result, self.resultfile)
    else
        log.throw(
            "|fzfx.general - PreviewerSwitch:preview| error! invalid previewer type! %s",
            vim.inspect(self)
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

--- @param name string
--- @param query string
--- @param bang boolean
--- @param pipeline_configs Configs
--- @param default_pipeline PipelineName?
--- @return Popup
local function general(name, query, bang, pipeline_configs, default_pipeline)
    --- @type PipelineContext
    local context = {
        bufnr = vim.api.nvim_get_current_buf(),
        winnr = vim.api.nvim_get_current_win(),
        tabnr = vim.api.nvim_get_current_tabpage(),
    }

    local pipeline_size = get_pipeline_size(pipeline_configs)

    local default_provider_key = nil
    if default_pipeline == nil then
        local pipeline, provider_opts = next(pipeline_configs.providers)
        default_pipeline = pipeline
        default_provider_key = provider_opts.key
    else
        local provider_opts = pipeline_configs.providers[default_pipeline]
        default_provider_key = provider_opts.key
    end

    --- @type ProviderSwitch
    local provider_switch =
        ProviderSwitch:new(name, default_pipeline, pipeline_configs.providers)

    --- @type PreviewerSwitch
    local previewer_switch =
        PreviewerSwitch:new(name, default_pipeline, pipeline_configs.previewers)

    --- @param query_params string
    local function provide_rpc(query_params)
        provider_switch:provide(query_params, context)
    end

    --- @param line_params string
    local function preview_rpc(line_params)
        previewer_switch:preview(line_params)
    end

    local provide_rpc_registry_id =
        server:get_global_rpc_server():register(provide_rpc)
    local preview_rpc_registry_id =
        server:get_global_rpc_server():register(preview_rpc)

    local query_command = string.format(
        "%s %s %s %s %s",
        shell.make_lua_command("general", "provider.lua"),
        provide_rpc_registry_id,
        provider_switch.metafile,
        provider_switch.resultfile,
        utils.shellescape(query)
    )
    local reload_query_command = string.format(
        "%s %s %s %s {q}",
        shell.make_lua_command("general", "provider.lua"),
        provide_rpc_registry_id,
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
            local switch_pipeline_key = string.lower(provider_opts.key)

            local function switch_pipeline_rpc()
                provider_switch:switch(pipeline)
                previewer_switch:switch(pipeline)
            end

            local switch_pipeline_registry_id =
                server.get_global_rpc_server():register(switch_pipeline_rpc)

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
                    local switch_pipeline_key2 =
                        string.lower(provider_opts2.key)
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
            string.format("start:unbind(%s)", default_provider_key),
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

--- @param name string
--- @param pipeline_configs Configs?
local function setup(name, pipeline_configs)
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
                name,
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
