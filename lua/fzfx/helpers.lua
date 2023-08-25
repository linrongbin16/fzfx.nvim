local log = require("fzfx.log")
local env = require("fzfx.env")
local path = require("fzfx.path")
local color = require("fzfx.color")
local conf = require("fzfx.config")
local yank_history = require("fzfx.yank_history")
local utils = require("fzfx.utils")

-- visual select {

--- @param mode string
--- @return string
local function get_visual_lines(mode)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local line_start = start_pos[2]
    local column_start = start_pos[3]
    local line_end = end_pos[2]
    local column_end = end_pos[3]
    line_start = math.min(line_start, line_end)
    line_end = math.max(line_start, line_end)
    column_start = math.min(column_start, column_end)
    column_end = math.max(column_start, column_end)
    log.debug(
        "|fzfx.helpers - get_visual_lines| mode:%s, start_pos:%s, end_pos:%s",
        vim.inspect(mode),
        vim.inspect(start_pos),
        vim.inspect(end_pos)
    )
    log.debug(
        "|fzfx.helper - get_visual_lines| line_start:%s, line_end:%s, column_start:%s, column_end:%s",
        vim.inspect(line_start),
        vim.inspect(line_end),
        vim.inspect(column_start),
        vim.inspect(column_end)
    )

    local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
    if #lines == 0 then
        log.debug("|fzfx.helpers - get_visual_lines| empty lines")
        return ""
    end

    local cursor_pos = vim.fn.getpos(".")
    local cursor_line = cursor_pos[2]
    local cursor_column = cursor_pos[3]
    log.debug(
        "|fzfx.helpers - get_visual_lines| cursor_pos:%s, cursor_line:%s, cursor_column:%s",
        vim.inspect(cursor_pos),
        vim.inspect(cursor_line),
        vim.inspect(cursor_column)
    )
    if mode == "v" or mode == "\22" then
        local offset = string.lower(vim.o.selection) == "inclusive" and 1 or 2
        lines[#lines] = string.sub(lines[#lines], 1, column_end - offset + 1)
        lines[1] = string.sub(lines[1], column_start)
        log.debug(
            "|fzfx.helpers - get_visual_lines| v or \\22, lines:%s",
            vim.inspect(lines)
        )
    elseif mode == "V" then
        if #lines == 1 then
            lines[1] = vim.fn.trim(lines[1])
        end
        log.debug(
            "|fzfx.helpers - get_visual_lines| V, lines:%s",
            vim.inspect(lines)
        )
    end
    return table.concat(lines, "\n")
end

--- @return string
local function visual_select()
    vim.cmd([[ execute "normal! \<ESC>" ]])
    local mode = vim.fn.visualmode()
    if mode == "v" or mode == "V" or mode == "\22" then
        return get_visual_lines(mode)
    end
    return ""
end

-- visual select }

--- @param opts Configs
--- @param feed_type "args"|"visual"|"cword"|"put"
--- @return string
local function get_command_feed(opts, feed_type)
    feed_type = string.lower(feed_type)
    if feed_type == "args" then
        return opts.args
    elseif feed_type == "visual" then
        return visual_select()
    elseif feed_type == "cword" then
        return vim.fn.expand("<cword>")
    elseif feed_type == "put" then
        local y = yank_history.get_yank()
        return (y ~= nil and type(y.regtext) == "string") and y.regtext or ""
    else
        log.throw(
            "|fzfx.helpers - get_command_feed| error! invalid command feed type! %s",
            vim.inspect(feed_type)
        )
        return ""
    end
end

-- fzf opts {

--- @return FzfOpt[]
local function generate_fzf_color_opts()
    if type(conf.get_config().fzf_color_opts) ~= "table" then
        return {}
    end
    local fzf_colors = conf.get_config().fzf_color_opts
    local builder = {}
    for name, opts in pairs(fzf_colors) do
        for i = 2, #opts do
            local c = color.get_color(opts[1], opts[i])
            if type(c) == "string" and string.len(c) > 0 then
                table.insert(builder, string.format("%s:%s", name, c))
                break
            end
        end
    end
    log.debug(
        "|fzfx.helpers - make_fzf_color_opts| builder:%s",
        vim.inspect(builder)
    )
    return { { "--color", table.concat(builder, ",") } }
end

--- @return FzfOpt[]
local function generate_fzf_icon_opts()
    if type(conf.get_config().icons) ~= "table" then
        return {}
    end
    local icon_configs = conf.get_config().icons
    return {
        { "--pointer", icon_configs.fzf_pointer },
        { "--marker", icon_configs.fzf_marker },
    }
end

--- @param opts FzfOpt[]
--- @param o FzfOpt?
--- @return FzfOpt[]
local function append_fzf_opt(opts, o)
    if type(o) == "string" and string.len(o) > 0 then
        table.insert(opts, o)
    elseif type(o) == "table" and #o == 2 then
        local k = o[1]
        local v = o[2]
        table.insert(opts, string.format("%s %s", k, utils.shellescape(v)))
    else
        log.throw(
            "|fzfx.helpers - append_fzf_opt| invalid fzf opt: %s",
            vim.inspect(o)
        )
    end
    return opts
end

--- @param opts FzfOpt[]
--- @return FzfOpt[]
local function preprocess_fzf_opts(opts)
    if opts == nil or #opts == 0 then
        return {}
    end
    local result = {}
    for _, o in ipairs(opts) do
        if o == nil then
            -- pass
        elseif type(o) == "function" then
            local result_o = o()
            if result_o ~= nil then
                table.insert(result, result_o)
            end
        else
            table.insert(result, o)
        end
    end
    return result
end

--- @param opts FzfOpt[]
--- @return string?
local function make_fzf_opts(opts)
    if opts == nil or #opts == 0 then
        return nil
    end
    local result = {}
    for _, o in ipairs(opts) do
        append_fzf_opt(result, o)
    end
    return table.concat(result, " ")
end

--- @return string?
local function make_fzf_default_opts()
    local opts = conf.get_config().fzf_opts
    local result = {}
    if type(opts) == "table" and #opts > 0 then
        for _, o in ipairs(opts) do
            append_fzf_opt(result, o)
        end
    end
    local color_opts = generate_fzf_color_opts()
    if type(color_opts) == "table" and #color_opts > 0 then
        for _, o in ipairs(color_opts) do
            append_fzf_opt(result, o)
        end
    end
    local icon_opts = generate_fzf_icon_opts()
    if type(icon_opts) == "table" and #icon_opts > 0 then
        for _, o in ipairs(icon_opts) do
            append_fzf_opt(result, o)
        end
    end
    return table.concat(result, " ")
end

-- fzf opts }

-- provider switch {

--- @class Switch
--- @field name string|nil
--- @field current string|nil
--- @field next string|nil
--- @field tempfile string|nil
local Switch = {
    name = nil,
    current = nil,
    next = nil,
    tempfile = nil,
}

--- @param name string
--- @param current string
--- @param next string
--- @return Switch
function Switch:new(name, current, next)
    local switch = vim.tbl_deep_extend("force", vim.deepcopy(Switch), {
        name = name,
        current = current,
        next = next,
        tempfile = env.debug_enable() and path.join(
            vim.fn.stdpath("data"),
            "fzfx.nvim",
            "switch_" .. name
        ) or vim.fn.tempname(),
    })
    vim.fn.writefile({ switch.current }, switch.tempfile, "b")
    log.debug("|fzfx.helpers - Switch:new| switch:%s", vim.inspect(switch))
    return switch
end

function Switch:switch()
    local tmp = self.next
    self.next = self.current
    self.current = tmp
    vim.fn.writefile({ self.current }, self.tempfile, "b")
end

-- provider switch }

-- multiple provider switch {

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

-- multiple provider switch }

-- multiple previewer switch {

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

-- multiple previewer switch }

local M = {
    get_command_feed = get_command_feed,
    preprocess_fzf_opts = preprocess_fzf_opts,
    make_fzf_opts = make_fzf_opts,
    make_fzf_default_opts = make_fzf_default_opts,
    Switch = Switch,
    ProviderSwitch = ProviderSwitch,
    PreviewerSwitch = PreviewerSwitch,
}

return M
