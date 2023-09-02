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
local Clazz = require("fzfx.clazz").Clazz
local ProviderConfig = require("fzfx.schema").ProviderConfig
local PreviewerConfig = require("fzfx.schema").PreviewerConfig

local DEFAULT_PIPELINE = "default"

-- provider switch {

--- @class ProviderSwitch
--- @field pipeline PipelineName?
--- @field provider_configs table<PipelineName, ProviderConfig>?
--- @field metafile string?
--- @field resultfile string?
local ProviderSwitch = {
    pipeline = nil,
    provider_configs = nil,
    metafile = nil,
    resultfile = nil,
}

--- @param name string
--- @param pipeline PipelineName
--- @param provider_configs Configs
--- @return ProviderSwitch
function ProviderSwitch:new(name, pipeline, provider_configs)
    local provider_configs_map = {}
    if Clazz:instanceof(provider_configs, ProviderConfig) then
        provider_configs.provider_type = provider_configs.provider_type
            or (
                type(provider_configs.provider) == "string"
                    and ProviderTypeEnum.PLAIN
                or ProviderTypeEnum.PLAIN_LIST
            )
        provider_configs_map[DEFAULT_PIPELINE] = provider_configs
    else
        for _, provider_opts in pairs(provider_configs) do
            provider_opts.provider_type = provider_opts.provider_type
                or (
                    type(provider_opts.provider) == "string"
                        and ProviderTypeEnum.PLAIN
                    or ProviderTypeEnum.PLAIN_LIST
                )
        end
        provider_configs_map = provider_configs
    end
    return vim.tbl_deep_extend("force", vim.deepcopy(ProviderSwitch), {
        pipeline = pipeline,
        provider_configs = provider_configs_map,
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

--- @param name string
--- @param query string?
--- @param context PipelineContext?
function ProviderSwitch:provide(name, query, context)
    local provider_config = self.provider_configs[self.pipeline]
    log.debug(
        "|fzfx.general - ProviderSwitch:provide| pipeline:%s, provider_config:%s",
        vim.inspect(self.pipeline),
        vim.inspect(provider_config)
    )
    log.ensure(
        type(provider_config) == "table",
        "invalid provider config in %s! pipeline: %s, provider config: %s",
        vim.inspect(name),
        vim.inspect(self.pipeline),
        vim.inspect(provider_config)
    )
    log.ensure(
        provider_config.provider == nil
            or type(provider_config.provider) == "string"
            or type(provider_config.provider) == "function",
        "invalid provider in %s! pipeline: %s, provider: %s",
        vim.inspect(name),
        vim.inspect(self.pipeline),
        vim.inspect(provider_config)
    )
    log.ensure(
        provider_config.provider_type == ProviderTypeEnum.PLAIN
            or provider_config.provider_type == ProviderTypeEnum.PLAIN_LIST
            or provider_config.provider_type == ProviderTypeEnum.COMMAND
            or provider_config.provider_type == ProviderTypeEnum.COMMAND_LIST
            or provider_config.provider_type == ProviderTypeEnum.LIST,
        "invalid provider type in %s! pipeline: %s, provider type: %s",
        vim.inspect(name),
        vim.inspect(self.pipeline),
        vim.inspect(provider_config)
    )

    --- @class ProviderMetaJson
    --- @field pipeline PipelineName
    --- @field provider_type ProviderType
    --- @field provider_line_type ProviderLineType?
    --- @field provider_line_delimiter string?
    --- @field provider_line_pos integer?

    local metajson = vim.fn.json_encode({
        pipeline = self.pipeline,
        provider_type = provider_config.provider_type,
        provider_line_type = provider_config.line_type,
        provider_line_delimiter = provider_config.line_delimiter,
        provider_line_pos = provider_config.line_pos,
    } --[[@as ProviderMetaJson ]])
    vim.fn.writefile({ metajson }, self.metafile)

    if provider_config.provider_type == ProviderTypeEnum.PLAIN then
        log.ensure(
            provider_config.provider == nil
                or type(provider_config.provider) == "string",
            "|fzfx.general - ProviderSwitch:provide| plain provider must be string or nil! self:%s, provider:%s",
            vim.inspect(self),
            vim.inspect(provider_config)
        )
        if provider_config.provider == nil then
            vim.fn.writefile({ "" }, self.resultfile)
        else
            vim.fn.writefile({ provider_config.provider }, self.resultfile)
        end
    elseif provider_config.provider_type == ProviderTypeEnum.PLAIN_LIST then
        log.ensure(
            provider_config.provider == nil
                or type(provider_config.provider) == "table",
            "|fzfx.general - ProviderSwitch:provide| plain_list provider must be string or nil! self:%s, provider:%s",
            vim.inspect(self),
            vim.inspect(provider_config)
        )
        if
            provider_config.provider == nil
            or #provider_config.provider == 0
        then
            vim.fn.writefile({ "" }, self.resultfile)
        else
            vim.fn.writefile(provider_config.provider, self.resultfile)
        end
    elseif provider_config.provider_type == ProviderTypeEnum.COMMAND then
        local ok, result = pcall(provider_config.provider, query, context)
        log.debug(
            "|fzfx.general - ProviderSwitch:provide| pcall command provider, ok:%s, result:%s",
            vim.inspect(ok),
            vim.inspect(result)
        )
        log.ensure(
            result == nil or type(result) == "string",
            "|fzfx.general - ProviderSwitch:provide| command provider result must be string! self:%s, result:%s",
            vim.inspect(self),
            vim.inspect(result)
        )
        if not ok then
            vim.fn.writefile({ "" }, self.resultfile)
            log.err(
                "failed to call pipeline %s command provider %s! query:%s, context:%s, error:%s",
                vim.inspect(name),
                vim.inspect(provider_config),
                vim.inspect(query),
                vim.inspect(context),
                vim.inspect(result)
            )
        else
            if result == nil then
                vim.fn.writefile({ "" }, self.resultfile)
            else
                vim.fn.writefile({ result }, self.resultfile)
            end
        end
    elseif provider_config.provider_type == ProviderTypeEnum.COMMAND_LIST then
        local ok, result = pcall(provider_config.provider, query, context)
        log.debug(
            "|fzfx.general - ProviderSwitch:provide| pcall command_list provider, ok:%s, result:%s",
            vim.inspect(ok),
            vim.inspect(result)
        )
        log.ensure(
            result == nil or type(result) == "table",
            "|fzfx.general - ProviderSwitch:provide| command_list provider result must be string! self:%s, result:%s",
            vim.inspect(self),
            vim.inspect(result)
        )
        if not ok then
            vim.fn.writefile({ "" }, self.resultfile)
            log.err(
                "failed to call pipeline %s command_list provider %s! query:%s, context:%s, error:%s",
                vim.inspect(name),
                vim.inspect(provider_config),
                vim.inspect(query),
                vim.inspect(context),
                vim.inspect(result)
            )
        else
            if result == nil or #result == 0 then
                vim.fn.writefile({ "" }, self.resultfile)
            else
                vim.fn.writefile(result, self.resultfile)
            end
        end
    elseif provider_config.provider_type == ProviderTypeEnum.LIST then
        local ok, result = pcall(provider_config.provider, query, context)
        log.debug(
            "|fzfx.general - ProviderSwitch:provide| pcall list provider, ok:%s, result:%s",
            vim.inspect(ok),
            vim.inspect(result)
        )
        if not ok then
            vim.fn.writefile({ "" }, self.resultfile)
            log.err(
                "failed to call pipeline %s list provider %s! query:%s, context:%s, error:%s",
                vim.inspect(name),
                vim.inspect(provider_config),
                vim.inspect(query),
                vim.inspect(context),
                vim.inspect(result)
            )
        else
            log.ensure(
                result == nil or type(result) == "table",
                "|fzfx.general - ProviderSwitch:provide| list provider result must be array! self:%s, result:%s",
                vim.inspect(self),
                vim.inspect(result)
            )
            if utils.list_empty(result) then
                vim.fn.writefile({ "" }, self.resultfile)
            else
                vim.fn.writefile(result, self.resultfile)
            end
        end
    else
        log.throw(
            "|fzfx.general - ProviderSwitch:provide| error! invalid provider type! %s",
            vim.inspect(self)
        )
    end
    ---@diagnostic disable-next-line: need-check-nil
    return provider_config.provider_type
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
    if Clazz:instanceof(previewer_configs, PreviewerConfig) then
        local previewer_name = DEFAULT_PIPELINE
        local previewer_opts = previewer_configs
        local previewer = previewer_opts.previewer
        local previewer_type = previewer_opts.previewer_type
        previewers_map[previewer_name] = previewer
        previewer_types_map[previewer_name] = previewer_type
    else
        for previewer_name, previewer_opts in pairs(previewer_configs) do
            local previewer = previewer_opts.previewer
            local previewer_type = previewer_opts.previewer_type
            previewers_map[previewer_name] = previewer
            previewer_types_map[previewer_name] = previewer_type
        end
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

--- @param name string
--- @param line string
--- @param context PipelineContext?
--- @return PreviewerType
function PreviewerSwitch:preview(name, line, context)
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
        local ok, result = pcall(previewer, line, context)
        log.debug(
            "|fzfx.general - PreviewerSwitch:preview| pcall command previewer, ok:%s, result:%s",
            vim.inspect(ok),
            vim.inspect(result)
        )
        if not ok then
            vim.fn.writefile({ "" }, self.resultfile)
            log.err(
                "failed to call pipeline %s command previewer %s! line:%s, context:%s, error:%s",
                vim.inspect(name),
                vim.inspect(previewer),
                vim.inspect(line),
                vim.inspect(context),
                vim.inspect(result)
            )
        else
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
        end
    elseif previewer_type == PreviewerTypeEnum.LIST then
        local ok, result = pcall(previewer, line, context)
        log.debug(
            "|fzfx.general - PreviewerSwitch:preview| pcall list previewer, ok:%s, result:%s",
            vim.inspect(ok),
            vim.inspect(result)
        )
        if not ok then
            vim.fn.writefile({ "" }, self.resultfile)
            log.err(
                "failed to call pipeline %s list previewer %s! line:%s, context:%s, error:%s",
                vim.inspect(name),
                vim.inspect(previewer),
                vim.inspect(line),
                vim.inspect(context),
                vim.inspect(result)
            )
        else
            log.ensure(
                type(result) == "table",
                "|fzfx.general - PreviewerSwitch:preview| list previewer result must be array! self:%s, result:%s",
                vim.inspect(self),
                vim.inspect(result)
            )
            vim.fn.writefile(result, self.resultfile)
        end
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
--- @param interaction_configs Configs
--- @return HeaderSwitch
function HeaderSwitch:new(provider_configs, interaction_configs)
    local headers_map = {}
    if Clazz:instanceof(provider_configs, ProviderConfig) then
        local help_builder = {}
        local provider_name = DEFAULT_PIPELINE
        if type(interaction_configs) == "table" then
            for interaction_name, interaction_opts in pairs(interaction_configs) do
                local action_key = interaction_opts.key
                table.insert(
                    help_builder,
                    color.render(
                        "%s to "
                            .. table.concat(
                                vim.fn.split(interaction_name, "_"),
                                " "
                            ),
                        color.magenta,
                        string.upper(action_key)
                    )
                )
            end
        end
        headers_map[provider_name] = help_builder
    else
        for provider_name, provider_opts in pairs(provider_configs) do
            local help_builder = {}
            for provider_name2, provider_opts2 in pairs(provider_configs) do
                local switch_key2 = string.lower(provider_opts2.key)
                if provider_name2 ~= provider_name then
                    table.insert(
                        help_builder,
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
            if type(interaction_configs) == "table" then
                for interaction_name, interaction_opts in
                    pairs(interaction_configs)
                do
                    local action_key = interaction_opts.key
                    table.insert(
                        help_builder,
                        color.render(
                            "%s to "
                                .. table.concat(
                                    vim.fn.split(interaction_name, "_"),
                                    " "
                                ),
                            color.magenta,
                            string.upper(action_key)
                        )
                    )
                end
            end
            headers_map[provider_name] = help_builder
        end
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
        if Clazz:instanceof(pipeline_configs.providers, ProviderConfig) then
            return 1
        end
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
        local pipeline = nil
        local provider_opts = nil
        if Clazz:instanceof(pipeline_configs.providers, ProviderConfig) then
            log.debug(
                "|fzfx.general - general| providers instanceof ProviderConfig, providers:%s, ProviderConfig:%s",
                vim.inspect(pipeline_configs.providers),
                vim.inspect(ProviderConfig)
            )
            pipeline = DEFAULT_PIPELINE
            provider_opts = pipeline_configs.providers
        else
            log.debug(
                "|fzfx.general - general| providers not instanceof ProviderConfig, providers:%s, ProviderConfig:%s",
                vim.inspect(pipeline_configs.providers),
                vim.inspect(ProviderConfig)
            )
            pipeline, provider_opts = next(pipeline_configs.providers)
        end
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
        provider_switch:provide(name, query_params, context)
    end

    --- @param line_params string
    local function preview_rpc(line_params)
        previewer_switch:preview(name, line_params)
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

    local header_switch = HeaderSwitch:new(
        pipeline_configs.providers,
        pipeline_configs.interactions
    )

    -- have interactions or pipelines >= 2
    if type(pipeline_configs.interactions) == "table" or pipeline_size > 1 then
        local header = header_switch:get_header(default_pipeline)
        table.insert(fzf_opts, {
            "--header",
            header,
        })
    end

    local interaction_rpc_registries = {}
    -- when no interactions, no need to add help
    if type(pipeline_configs.interactions) == "table" then
        for _, interaction_opts in pairs(pipeline_configs.interactions) do
            local action_key = string.lower(interaction_opts.key)
            local action = interaction_opts.interaction

            local function interaction_rpc(line_params)
                log.debug(
                    "|fzfx.general - general.interaction_rpc| line_params:%s",
                    vim.inspect(line_params)
                )
                action(line_params)
            end

            local interaction_rpc_registry_id =
                server.get_global_rpc_server():register(interaction_rpc)
            table.insert(
                interaction_rpc_registries,
                interaction_rpc_registry_id
            )

            local action_command = string.format(
                "%s %s {}",
                shell.make_lua_command("rpc", "client.lua"),
                interaction_rpc_registry_id
            )
            local bind_builder = string.format(
                "%s:execute-silent(%s)",
                action_key,
                action_command
            )
            if interaction_opts.reload_after_execute then
                bind_builder = bind_builder
                    .. string.format("+reload(%s)", reload_query_command)
            end
            table.insert(fzf_opts, {
                "--bind",
                bind_builder,
            })
        end
    end

    local switch_rpc_registries = {}

    -- when only have 1 pipeline, no need to add help for switch keys
    if pipeline_size > 1 then
        for pipeline, provider_opts in pairs(pipeline_configs.providers) do
            local switch_key = string.lower(provider_opts.key)

            local function switch_rpc()
                provider_switch:switch(pipeline)
                previewer_switch:switch(pipeline)
            end

            local switch_rpc_registry_id =
                server.get_global_rpc_server():register(switch_rpc)
            table.insert(switch_rpc_registries, switch_rpc_registry_id)

            local switch_command = string.format(
                "%s %s",
                shell.make_lua_command("rpc", "client.lua"),
                switch_rpc_registry_id
            )
            local bind_builder = string.format(
                "%s:unbind(%s)+execute-silent(%s)+change-header(%s)+reload(%s)",
                switch_key,
                switch_key,
                switch_command,
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

    -- log.debug(
    --     "|fzfx.general - setup| pipeline_configs:%s",
    --     vim.inspect(pipeline_configs)
    -- )
    -- User commands
    for _, command_configs in pairs(pipeline_configs.commands) do
        vim.api.nvim_create_user_command(command_configs.name, function(opts)
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
    ProviderSwitch = ProviderSwitch,
    PreviewerSwitch = PreviewerSwitch,
    HeaderSwitch = HeaderSwitch,
}

return M
