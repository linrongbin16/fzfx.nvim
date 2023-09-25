local log = require("fzfx.log")
local Popup = require("fzfx.popup").Popup
local helpers = require("fzfx.helpers")
local server = require("fzfx.server")
local color = require("fzfx.color")
local utils = require("fzfx.utils")
local env = require("fzfx.env")
local path = require("fzfx.path")
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local clazz = require("fzfx.clazz")
local ProviderConfig = require("fzfx.schema").ProviderConfig
local PreviewerConfig = require("fzfx.schema").PreviewerConfig
local CommandConfig = require("fzfx.schema").CommandConfig

local DEFAULT_PIPELINE = "default"

-- provider switch {

--- @class ProviderSwitch
--- @field pipeline PipelineName
--- @field provider_configs table<PipelineName, ProviderConfig>
--- @field metafile string
--- @field resultfile string
local ProviderSwitch = {}

--- @param name string
--- @param pipeline PipelineName
--- @param provider_configs Configs
--- @return ProviderSwitch
function ProviderSwitch:new(name, pipeline, provider_configs)
    local provider_configs_map = {}
    if clazz.instanceof(provider_configs, ProviderConfig) then
        provider_configs_map[DEFAULT_PIPELINE] = provider_configs
    else
        provider_configs_map = provider_configs
    end

    local o = {
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
    }
    setmetatable(o, self)
    self.__index = self
    return o
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
        "|fzfx.general - ProviderSwitch:provide| pipeline:%s, provider_config:%s, context:%s",
        vim.inspect(self.pipeline),
        vim.inspect(provider_config),
        vim.inspect(context)
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
            or type(provider_config.provider) == "table"
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

    --- @class ProviderMetaOpts
    --- @field pipeline PipelineName
    --- @field provider_type ProviderType
    --- @field prepend_icon_by_ft boolean?
    --- @field prepend_icon_path_delimiter string?
    --- @field prepend_icon_path_position integer?

    --- @type ProviderMetaOpts
    local meta_opts = {
        pipeline = self.pipeline,
        provider_type = provider_config.provider_type,
    }
    if
        type(provider_config.line_type) == "string"
        and provider_config.line_type == "file"
    then
        meta_opts.prepend_icon_by_ft = true
    elseif
        type(provider_config.line_opts) == "table"
        and provider_config.line_opts.prepend_icon_by_ft ~= nil
    then
        meta_opts.prepend_icon_by_ft =
            provider_config.line_opts.prepend_icon_by_ft
    end
    if
        type(provider_config.line_delimiter) == "string"
        and string.len(provider_config.line_delimiter) > 0
    then
        meta_opts.prepend_icon_path_delimiter = provider_config.line_delimiter
    elseif
        type(provider_config.line_opts) == "table"
        and type(provider_config.line_opts.prepend_icon_path_delimiter) == "string"
        and string.len(
                provider_config.line_opts.prepend_icon_path_delimiter
            )
            > 0
    then
        meta_opts.prepend_icon_path_delimiter =
            provider_config.line_opts.prepend_icon_path_delimiter
    end
    if type(provider_config.line_pos) == "number" then
        meta_opts.prepend_icon_path_position = provider_config.line_pos
    elseif
        type(provider_config.line_opts) == "table"
        and type(provider_config.line_opts.prepend_icon_path_position)
            == "number"
    then
        meta_opts.prepend_icon_path_position =
            provider_config.line_opts.prepend_icon_path_position
    end

    local metajson = vim.fn.json_encode(meta_opts) --[[@as string]]
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
            or vim.tbl_isempty(provider_config.provider --[[@as table]])
        then
            vim.fn.writefile({ "" }, self.resultfile)
        else
            vim.fn.writefile(
                { vim.fn.json_encode(provider_config.provider) },
                self.resultfile
            )
        end
    elseif provider_config.provider_type == ProviderTypeEnum.COMMAND then
        local ok, result =
            pcall(provider_config.provider --[[@as function]], query, context)
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
        local ok, result =
            pcall(provider_config.provider --[[@as function]], query, context)
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
            if result == nil or vim.tbl_isempty(result) then
                vim.fn.writefile({ "" }, self.resultfile)
            else
                vim.fn.writefile(
                    { vim.fn.json_encode(result) },
                    self.resultfile
                )
            end
        end
    elseif provider_config.provider_type == ProviderTypeEnum.LIST then
        local ok, result =
            pcall(provider_config.provider --[[@as function]], query, context)
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
            if result == nil or vim.tbl_isempty(result) then
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
--- @field pipeline PipelineName
--- @field previewers table<PipelineName, Previewer>
--- @field previewer_types table<PipelineName, PreviewerType>
--- @field metafile string
--- @field resultfile string
local PreviewerSwitch = {}

--- @param name string
--- @param pipeline PipelineName
--- @param previewer_configs Configs
--- @return PreviewerSwitch
function PreviewerSwitch:new(name, pipeline, previewer_configs)
    local previewers_map = {}
    local previewer_types_map = {}
    if clazz.instanceof(previewer_configs, PreviewerConfig) then
        previewers_map[DEFAULT_PIPELINE] = previewer_configs.previewer
        previewer_types_map[DEFAULT_PIPELINE] = previewer_configs.previewer_type
    else
        for previewer_name, previewer_opts in pairs(previewer_configs) do
            previewers_map[previewer_name] = previewer_opts.previewer
            previewer_types_map[previewer_name] = previewer_opts.previewer_type
        end
    end

    local o = {
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
    }
    setmetatable(o, self)
    self.__index = self
    return o
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
            or previewer_type == PreviewerTypeEnum.COMMAND_LIST
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
    elseif previewer_type == PreviewerTypeEnum.COMMAND_LIST then
        local ok, result = pcall(previewer, line, context)
        log.debug(
            "|fzfx.general - PreviewerSwitch:preview| pcall command_list previewer, ok:%s, result:%s",
            vim.inspect(ok),
            vim.inspect(result)
        )
        if not ok then
            vim.fn.writefile({ "" }, self.resultfile)
            log.err(
                "failed to call pipeline %s command_list previewer %s! line:%s, context:%s, error:%s",
                vim.inspect(name),
                vim.inspect(previewer),
                vim.inspect(line),
                vim.inspect(context),
                vim.inspect(result)
            )
        else
            log.ensure(
                result == nil or type(result) == "table",
                "|fzfx.general - PreviewerSwitch:preview| command_list previewer result must be string! self:%s, result:%s",
                vim.inspect(self),
                vim.inspect(result)
            )
            ---@diagnostic disable-next-line: param-type-mismatch
            if result == nil or vim.tbl_isempty(result) then
                vim.fn.writefile({ "" }, self.resultfile)
            else
                vim.fn.writefile(
                    { vim.fn.json_encode(result) },
                    self.resultfile
                )
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
--- @field headers table<PipelineName, string[]>
local HeaderSwitch = {}

--- @param provider_configs Configs
--- @param interaction_configs Configs
--- @return HeaderSwitch
function HeaderSwitch:new(provider_configs, interaction_configs)
    local headers_map = {}
    if clazz.instanceof(provider_configs, ProviderConfig) then
        local help_builder = {}
        local provider_name = DEFAULT_PIPELINE
        if type(interaction_configs) == "table" then
            for interaction_name, interaction_opts in pairs(interaction_configs) do
                local action_key = interaction_opts.key
                table.insert(
                    help_builder,
                    color.render(
                        color.magenta,
                        "Special",
                        "%s to "
                            .. table.concat(
                                vim.fn.split(interaction_name, "_"),
                                " "
                            ),
                        string.upper(action_key)
                    )
                )
            end
        end
        headers_map[provider_name] = help_builder
    else
        log.debug(
            "|fzfx.general - HeaderSwitch:new| provider_configs:%s",
            vim.inspect(provider_configs)
        )
        for provider_name, provider_opts in pairs(provider_configs) do
            local help_builder = {}
            for provider_name2, provider_opts2 in pairs(provider_configs) do
                local switch_key2 = string.lower(provider_opts2.key)
                if provider_name2 ~= provider_name then
                    table.insert(
                        help_builder,
                        color.render(
                            color.magenta,
                            "Special",
                            "%s to "
                                .. table.concat(
                                    vim.fn.split(provider_name2, "_"),
                                    " "
                                ),
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
                            color.magenta,
                            "Special",
                            "%s to "
                                .. table.concat(
                                    vim.fn.split(interaction_name, "_"),
                                    " "
                                ),
                            string.upper(action_key)
                        )
                    )
                end
            end
            headers_map[provider_name] = help_builder
        end
    end

    local o = {
        headers = headers_map,
    }
    setmetatable(o, self)
    self.__index = self
    return o
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
        if clazz.instanceof(pipeline_configs.providers, ProviderConfig) then
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
    local pipeline_size = get_pipeline_size(pipeline_configs)

    local default_provider_key = nil
    if default_pipeline == nil then
        local pipeline = nil
        local provider_opts = nil
        if clazz.instanceof(pipeline_configs.providers, ProviderConfig) then
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

    --- @type PipelineContext
    local default_context = {
        bufnr = vim.api.nvim_get_current_buf(),
        winnr = vim.api.nvim_get_current_win(),
        tabnr = vim.api.nvim_get_current_tabpage(),
    }
    local pipeline_contexts_map = {}
    if clazz.instanceof(pipeline_configs.providers, ProviderConfig) then
        if type(pipeline_configs.providers.context_maker) == "function" then
            pipeline_contexts_map[DEFAULT_PIPELINE] =
                pipeline_configs.providers.context_maker()
        end
    else
        for provider_name, provider_opts in pairs(pipeline_configs.providers) do
            if type(provider_opts.context_maker) == "function" then
                pipeline_contexts_map[provider_name] =
                    provider_opts.context_maker()
            end
        end
    end

    --- @param query_params string
    local function provide_rpc(query_params)
        provider_switch:provide(
            name,
            query_params,
            pipeline_contexts_map[provider_switch.pipeline] or default_context
        )
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
        helpers.make_lua_command("general", "provider.lua"),
        provide_rpc_registry_id,
        provider_switch.metafile,
        provider_switch.resultfile,
        utils.shellescape(query)
    )
    local reload_query_command = string.format(
        "%s %s %s %s {q}",
        helpers.make_lua_command("general", "provider.lua"),
        provide_rpc_registry_id,
        provider_switch.metafile,
        provider_switch.resultfile
    )
    local preview_command = string.format(
        "%s %s %s %s {}",
        helpers.make_lua_command("general", "previewer.lua"),
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
                helpers.make_lua_command("rpc", "client.lua"),
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
                helpers.make_lua_command("rpc", "client.lua"),
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
    if
        type(pipeline_configs.other_opts) == "table"
        and pipeline_configs.other_opts.reload_on_change
    then
        table.insert(fzf_opts, {
            "--bind",
            string.format("change:reload:%s", reload_query_command),
        })
    end

    fzf_opts =
        vim.list_extend(fzf_opts, vim.deepcopy(pipeline_configs.fzf_opts))
    fzf_opts = helpers.preprocess_fzf_opts(fzf_opts)
    local actions = pipeline_configs.actions
    local win_opts = nil
    if
        type(pipeline_configs.win_opts) == "table"
        and not vim.tbl_isempty(pipeline_configs.win_opts)
    then
        win_opts = vim.tbl_deep_extend(
            "force",
            vim.deepcopy(win_opts or {}),
            pipeline_configs.win_opts
        )
    end
    if bang then
        win_opts = vim.tbl_deep_extend(
            "force",
            vim.deepcopy(win_opts or {}),
            { height = 1, width = 1, row = 0, col = 0 }
        )
    end
    local p = Popup:new(
        win_opts or {},
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
    if clazz.instanceof(pipeline_configs.commands, CommandConfig) then
        vim.api.nvim_create_user_command(
            pipeline_configs.commands.name,
            function(opts)
                local query = helpers.get_command_feed(
                    opts,
                    pipeline_configs.commands.feed
                )
                return general(
                    name,
                    query,
                    opts.bang,
                    pipeline_configs,
                    pipeline_configs.commands.default_provider
                )
            end,
            pipeline_configs.commands.opts
        )
    else
        for _, command_configs in pairs(pipeline_configs.commands) do
            vim.api.nvim_create_user_command(
                command_configs.name,
                function(opts)
                    local query =
                        helpers.get_command_feed(opts, command_configs.feed)
                    return general(
                        name,
                        query,
                        opts.bang,
                        pipeline_configs,
                        command_configs.default_provider
                    )
                end,
                command_configs.opts
            )
        end
    end
end

local M = {
    setup = setup,
    ProviderSwitch = ProviderSwitch,
    PreviewerSwitch = PreviewerSwitch,
    HeaderSwitch = HeaderSwitch,
}

return M
