local log = require("fzfx.log")
local Popup = require("fzfx.popup").Popup
local shell = require("fzfx.shell")
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")
local color = require("fzfx.color")
local utils = require("fzfx.utils")
local env = require("fzfx.env")
local path = require("fzfx.path")
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum

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
    -- log.debug("|fzfx.general - ProviderSwitch:provide| 1")
    local provider = self.providers[self.pipeline]
    -- log.debug("|fzfx.general - ProviderSwitch:provide| 2")
    local provider_type = self.provider_types[self.pipeline]
    -- log.debug("|fzfx.general - ProviderSwitch:provide| 3")
    log.ensure(
        provider == nil
            or type(provider) == "string"
            or type(provider) == "function",
        "|fzfx.general - ProviderSwitch:provide| invalid provider! %s",
        vim.inspect(self)
    )
    -- log.debug("|fzfx.general - ProviderSwitch:provide| 4")
    log.ensure(
        provider_type == ProviderTypeEnum.PLAIN
            or provider_type == ProviderTypeEnum.COMMAND
            or provider_type == ProviderTypeEnum.LIST,
        "|fzfx.general - ProviderSwitch:provide| invalid provider type! %s",
        vim.inspect(self)
    )
    -- log.debug("|fzfx.general - ProviderSwitch:provide| 5")
    local metajson = vim.fn.json_encode({
        pipeline = self.pipeline,
        provider_type = provider_type,
    })
    -- log.debug("|fzfx.general - ProviderSwitch:provide| 6")
    vim.fn.writefile({ metajson }, self.metafile)
    -- log.debug("|fzfx.general - ProviderSwitch:provide| 7")
    if provider_type == ProviderTypeEnum.PLAIN then
        -- log.debug("|fzfx.general - ProviderSwitch:provide| 8")
        log.ensure(
            provider == nil or type(provider) == "string",
            "|fzfx.general - ProviderSwitch:provide| plain provider must be string or nil! self:%s, provider:%s",
            vim.inspect(self),
            vim.inspect(provider)
        )
        -- log.debug("|fzfx.general - ProviderSwitch:provide| 9")
        if provider == nil then
            -- log.debug(
            --     "|fzfx.general - ProviderSwitch:provide| plain nil provider-before, resultfile:%s",
            --     self.resultfile
            -- )
            vim.fn.writefile({ "" }, self.resultfile)
            -- log.debug(
            --     "|fzfx.general - ProviderSwitch:provide| plain nil provider-after, resultfile:%s",
            --     self.resultfile
            -- )
        else
            vim.fn.writefile({ provider }, self.resultfile)
            -- log.debug(
            --     "|fzfx.general - ProviderSwitch:provide| plain not-null provider, resultfile:%s",
            --     self.resultfile
            -- )
        end
    elseif provider_type == ProviderTypeEnum.COMMAND then
        -- log.debug("|fzfx.general - ProviderSwitch:provide| 10")
        local result = provider(query, context)
        -- log.debug("|fzfx.general - ProviderSwitch:provide| 11")
        log.ensure(
            result == nil or type(result) == "string",
            "|fzfx.general - ProviderSwitch:provide| command provider result must be string! self:%s, result:%s",
            vim.inspect(self),
            vim.inspect(result)
        )
        -- log.debug("|fzfx.general - ProviderSwitch:provide| 12")
        if result == nil then
            -- log.debug(
            --     "|fzfx.general - ProviderSwitch:provide| command provider nil result-before, result:%s",
            --     vim.inspect(result)
            -- )
            vim.fn.writefile({ "" }, self.resultfile)
            -- log.debug(
            --     "|fzfx.general - ProviderSwitch:provide| command provider nil result-after, result:%s",
            --     vim.inspect(result)
            -- )
        else
            -- log.debug(
            --     "|fzfx.general - ProviderSwitch:provide| command provider not-null result-before, result:%s",
            --     vim.inspect(result)
            -- )
            vim.fn.writefile({ result }, self.resultfile)
            -- log.debug(
            --     "|fzfx.general - ProviderSwitch:provide| command provider not-null result-after, result:%s",
            --     vim.inspect(result)
            -- )
        end
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
            result == nil or type(result) == "string",
            "|fzfx.general - PreviewerSwitch:preview| command previewer result must be string! self:%s, result:%s",
            vim.inspect(self),
            vim.inspect(result)
        )
        if result == nil then
            vim.fn.writefile({ "" }, self.resultfile)
        else
            vim.fn.writefile({ result }, self.resultfile)
        end
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

-- header switch {

--- @class HeaderSwitch
--- @field headers table<PipelineName, string[]>?
local HeaderSwitch = {
    headers = nil,
}

--- @param provider_configs Configs
--- @return HeaderSwitch
function HeaderSwitch:new(provider_configs)
    local headers_map = {}
    for provider_name, provider_opts in pairs(provider_configs) do
        local switch_help = {}
        for provider_name2, provider_opts2 in pairs(provider_configs) do
            local switch_key2 = string.lower(provider_opts2.key)
            if provider_name2 ~= provider_name then
                table.insert(
                    switch_help,
                    color.render(
                        "%s to "
                            .. table.concat(
                                vim.fn.split(provider_name2, "_"),
                                " "
                            ),
                        color.magenta,
                        string.upper(switch_key2)
                    )
                )
            end
        end
        headers_map[provider_name] = switch_help
    end
    return vim.tbl_deep_extend("force", vim.deepcopy(HeaderSwitch), {
        headers = headers_map,
    })
end

--- @param pipeline PipelineName
--- @return FzfOpt?
function HeaderSwitch:get_header(pipeline)
    log.ensure(
        type(self.headers[pipeline]) == "table",
        "|fzfx.general - HeaderSwitch:get_header| pipeline (%s) must exists in headers! %s",
        vim.inspect(pipeline),
        vim.inspect(self)
    )
    local switch_help = self.headers[pipeline]
    return string.format(":: Press %s", table.concat(switch_help, ", "))
end

-- header switch }

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
        log.debug(
            "|fzfx.general - general.provide_rpc| query_params:%s, context:%s",
            vim.inspect(query_params),
            vim.inspect(context)
        )
        provider_switch:provide(query_params, context)
    end

    --- @param line_params string
    local function preview_rpc(line_params)
        log.debug(
            "|fzfx.general - general.preview_rpc| line_params:%s, context:%s",
            vim.inspect(line_params),
            vim.inspect(context)
        )
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

    local header_switch = HeaderSwitch:new(pipeline_configs.providers)
    local switch_rpc_registries = {}

    -- when only have 1 pipeline, no need to add help for switch keys
    if pipeline_size > 1 then
        local header = header_switch:get_header(default_pipeline)
        table.insert(fzf_opts, {
            "--header",
            header,
        })

        for pipeline, provider_opts in pairs(pipeline_configs.providers) do
            local switch_key = string.lower(provider_opts.key)

            local function switch_rpc()
                provider_switch:switch(pipeline)
                previewer_switch:switch(pipeline)
            end

            local switch_rpc_registry_id =
                server.get_global_rpc_server():register(switch_rpc)
            table.insert(switch_rpc_registries, switch_rpc_registry_id)

            local switch_pipeline_command = string.format(
                "%s %s",
                shell.make_lua_command("rpc", "client.lua"),
                switch_rpc_registry_id
            )
            local bind_builder = string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+reload(%s)",
                switch_key,
                switch_key,
                switch_pipeline_command,
                header_switch:get_header(pipeline),
                reload_query_command
            )
            for pipeline2, provider_opts2 in pairs(pipeline_configs.providers) do
                if pipeline2 ~= pipeline then
                    local switch_key2 = string.lower(provider_opts2.key)
                    bind_builder = bind_builder
                        .. string.format("+rebind(%s)", switch_key2)
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
            server.get_global_rpc_server():unregister(provide_rpc_registry_id)
            server.get_global_rpc_server():unregister(preview_rpc_registry_id)
            for _, switch_registry_id in ipairs(switch_rpc_registries) do
                server.get_global_rpc_server():unregister(switch_registry_id)
            end
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
