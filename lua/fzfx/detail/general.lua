local tables = require("fzfx.commons.tables")
local paths = require("fzfx.commons.paths")
local jsons = require("fzfx.commons.jsons")
local strings = require("fzfx.commons.strings")
local termcolors = require("fzfx.commons.termcolors")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")
local uv = require("fzfx.commons.uv")
local apis = require("fzfx.commons.apis")

local consts = require("fzfx.lib.constants")
local env = require("fzfx.lib.env")
local log = require("fzfx.lib.log")
local shells = require("fzfx.lib.shells")
local config = require("fzfx.config")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local schema = require("fzfx.schema")

local Popup = require("fzfx.detail.popup").Popup
local rpcserver = require("fzfx.detail.rpcserver")
local fzf_helpers = require("fzfx.detail.fzf_helpers")

local DEFAULT_PIPELINE = "default"

--- @param ... string
--- @return string
local function _make_cache_filename(...)
  if env.debug_enabled() then
    return paths.join(config.get().cache.dir, table.concat({ ... }, "_"))
  else
    return vim.fn.tempname() --[[@as string]]
  end
end

--- @return string
local function _provider_metafile()
  return _make_cache_filename("provider", "metafile")
end

--- @return string
local function _provider_resultfile()
  return _make_cache_filename("provider", "resultfile")
end

--- @return string
local function _previewer_metafile()
  return _make_cache_filename("previewer", "metafile")
end

--- @return string
local function _previewer_resultfile()
  return _make_cache_filename("previewer", "resultfile")
end

--- @return string
local function _fzf_port_file()
  return _make_cache_filename("fzf", "port", "file")
end

--- @return string
local function _focused_line_file()
  return _make_cache_filename("focused", "line", "file")
end

--- @class fzfx.ProviderMetaOpts
--- @field pipeline fzfx.PipelineName
--- @field provider_type fzfx.ProviderType
--- @field provider_decorator fzfx.ProviderDecorator?

--- @param pipeline string
--- @param provider_config fzfx.ProviderConfig
--- @return fzfx.ProviderMetaOpts
local function make_provider_meta_opts(pipeline, provider_config)
  local o = {
    pipeline = pipeline,
    provider_type = provider_config.provider_type,
  }

  -- provider_decorator
  if tables.tbl_get(provider_config, "provider_decorator") then
    o.provider_decorator = vim.deepcopy(provider_config.provider_decorator)
    if o.provider_decorator.builtin then
      o.provider_decorator.module = "fzfx.helper.provider_decorators."
        .. o.provider_decorator.module
    end
  end

  return o
end

--- @class fzfx.PreviewerMetaOpts
--- @field pipeline fzfx.PipelineName
--- @field previewer_type fzfx.PreviewerType

--- @param pipeline string
--- @param previewer_config fzfx.PreviewerConfig
--- @return fzfx.PreviewerMetaOpts
local function make_previewer_meta_opts(pipeline, previewer_config)
  local o = {
    pipeline = pipeline,
    previewer_type = previewer_config.previewer_type,
  }
  return o
end

-- provider switch {

--- @class fzfx.ProviderSwitch
--- @field pipeline fzfx.PipelineName
--- @field provider_configs fzfx.ProviderConfig|table<fzfx.PipelineName, fzfx.ProviderConfig>
--- @field metafile string
--- @field resultfile string
local ProviderSwitch = {}

--- @param name string
--- @param pipeline fzfx.PipelineName
--- @param provider_configs fzfx.Options
--- @return fzfx.ProviderSwitch
function ProviderSwitch:new(name, pipeline, provider_configs)
  local provider_configs_map = {}
  if schema.is_provider_config(provider_configs) then
    provider_configs.provider_type =
      schema.get_provider_type_or_default(provider_configs)
    provider_configs_map[DEFAULT_PIPELINE] = provider_configs
  else
    for provider_name, provider_opts in pairs(provider_configs) do
      log.ensure(
        schema.is_provider_config(provider_opts),
        "%s (%s) is not a valid provider! %s",
        vim.inspect(provider_name),
        vim.inspect(name),
        vim.inspect(provider_opts)
      )
      provider_opts.provider_type =
        schema.get_provider_type_or_default(provider_opts)
      provider_configs_map[provider_name] = provider_opts
    end
  end

  local o = {
    pipeline = pipeline,
    provider_configs = provider_configs_map,
    metafile = _provider_metafile(),
    resultfile = _provider_resultfile(),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param next_pipeline fzfx.PipelineName
--- @return nil
function ProviderSwitch:switch(next_pipeline)
  self.pipeline = next_pipeline
end

--- @param query string?
--- @param context fzfx.PipelineContext?
function ProviderSwitch:provide(query, context)
  local provider_config = self.provider_configs[self.pipeline] --[[@as fzfx.ProviderConfig]]
  -- log.debug(
  --     "|fzfx.general - ProviderSwitch:provide| pipeline:%s, provider_config:%s, context:%s",
  --     vim.inspect(self.pipeline),
  --     vim.inspect(provider_config),
  --     vim.inspect(context)
  -- )
  log.ensure(
    type(provider_config) == "table",
    "invalid provider config in %s! provider config: %s",
    vim.inspect(self.pipeline),
    vim.inspect(provider_config)
  )
  log.ensure(
    type(provider_config.provider) == "table"
      or type(provider_config.provider) == "string"
      or type(provider_config.provider) == "function",
    "invalid provider in %s! provider: %s",
    vim.inspect(self.pipeline),
    vim.inspect(provider_config)
  )
  log.ensure(
    provider_config.provider_type == ProviderTypeEnum.PLAIN
      or provider_config.provider_type == ProviderTypeEnum.PLAIN_LIST
      or provider_config.provider_type == ProviderTypeEnum.COMMAND
      or provider_config.provider_type == ProviderTypeEnum.COMMAND_LIST
      or provider_config.provider_type == ProviderTypeEnum.LIST,
    "invalid provider type in %s! provider type: %s",
    vim.inspect(self.pipeline),
    vim.inspect(provider_config)
  )

  local metaopts = make_provider_meta_opts(self.pipeline, provider_config)
  local metajson = jsons.encode(metaopts) --[[@as string]]
  fileios.writefile(self.metafile, metajson)

  if provider_config.provider_type == ProviderTypeEnum.PLAIN then
    log.ensure(
      provider_config.provider == nil
        or type(provider_config.provider) == "string",
      "|ProviderSwitch:provide| plain provider must be string or nil! self:%s, provider:%s",
      vim.inspect(self),
      vim.inspect(provider_config)
    )
    if provider_config.provider == nil then
      fileios.writefile(self.resultfile, "")
    else
      fileios.writefile(
        self.resultfile,
        provider_config.provider --[[@as string]]
      )
    end
  elseif provider_config.provider_type == ProviderTypeEnum.PLAIN_LIST then
    log.ensure(
      provider_config.provider == nil
        or type(provider_config.provider) == "table",
      "|ProviderSwitch:provide| plain_list provider must be string or nil! self:%s, provider:%s",
      vim.inspect(self),
      vim.inspect(provider_config)
    )
    if tables.tbl_empty(provider_config.provider) then
      fileios.writefile(self.resultfile, "")
    else
      fileios.writefile(
        self.resultfile,
        jsons.encode(provider_config.provider --[[@as table]]) --[[@as string]]
      )
    end
  elseif provider_config.provider_type == ProviderTypeEnum.COMMAND then
    local ok, result =
      pcall(provider_config.provider --[[@as function]], query, context)
    -- log.debug(
    --     "|fzfx.general - ProviderSwitch:provide| pcall command provider, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    log.ensure(
      result == nil or type(result) == "string",
      "|ProviderSwitch:provide| command provider result must be string! self:%s, result:%s",
      vim.inspect(self),
      vim.inspect(result)
    )
    if not ok then
      fileios.writefile(self.resultfile, "")
      log.err(
        "failed to call pipeline %s command provider %s! query:%s, context:%s, error:%s",
        vim.inspect(self.pipeline),
        vim.inspect(provider_config),
        vim.inspect(query),
        vim.inspect(context),
        vim.inspect(result)
      )
    else
      if result == nil then
        fileios.writefile(self.resultfile, "")
      else
        fileios.writefile(self.resultfile, result)
      end
    end
  elseif provider_config.provider_type == ProviderTypeEnum.COMMAND_LIST then
    local ok, result =
      pcall(provider_config.provider --[[@as function]], query, context)
    -- log.debug(
    --     "|fzfx.general - ProviderSwitch:provide| pcall command_list provider, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    log.ensure(
      result == nil or type(result) == "table",
      "|ProviderSwitch:provide| command_list provider result must be string! self:%s, result:%s",
      vim.inspect(self),
      vim.inspect(result)
    )
    if not ok then
      fileios.writefile(self.resultfile, "")
      log.err(
        "failed to call pipeline %s command_list provider %s! query:%s, context:%s, error:%s",
        vim.inspect(self.pipeline),
        vim.inspect(provider_config),
        vim.inspect(query),
        vim.inspect(context),
        vim.inspect(result)
      )
    else
      if tables.tbl_empty(result) then
        fileios.writefile(self.resultfile, "")
      else
        fileios.writefile(
          self.resultfile,
          jsons.encode(result) --[[@as string]]
        )
      end
    end
  elseif provider_config.provider_type == ProviderTypeEnum.LIST then
    local ok, result =
      pcall(provider_config.provider --[[@as function]], query, context)
    -- log.debug(
    --     "|fzfx.general - ProviderSwitch:provide| pcall list provider, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    if not ok then
      fileios.writefile(self.resultfile, "")
      log.err(
        "failed to call pipeline %s list provider %s! query:%s, context:%s, error:%s",
        vim.inspect(self.pipeline),
        vim.inspect(provider_config),
        vim.inspect(query),
        vim.inspect(context),
        vim.inspect(result)
      )
    else
      log.ensure(
        result == nil or type(result) == "table",
        "|ProviderSwitch:provide| list provider result must be array! self:%s, result:%s",
        vim.inspect(self),
        vim.inspect(result)
      )
      if tables.tbl_empty(result) then
        fileios.writefile(self.resultfile, "")
      else
        fileios.writelines(self.resultfile, result)
      end
    end
  else
    log.throw(
      "|ProviderSwitch:provide| invalid provider type! %s",
      vim.inspect(self)
    )
  end
  ---@diagnostic disable-next-line: need-check-nil
  return provider_config.provider_type
end

-- provider switch }

-- previewer switch {

--- @class fzfx.PreviewerSwitch
--- @field pipeline fzfx.PipelineName
--- @field previewer_configs table<fzfx.PipelineName, fzfx.PreviewerConfig>
--- @field previewer_labels_queue string[]
--- @field metafile string
--- @field resultfile string
--- @field fzf_port_file string
--- @field fzf_port string
local PreviewerSwitch = {}

--- @param name string
--- @param pipeline fzfx.PipelineName
--- @param previewer_configs fzfx.PreviewerConfig|table<fzfx.PipelineName, fzfx.PreviewerConfig>
--- @param fzf_port_file string
--- @return fzfx.PreviewerSwitch
function PreviewerSwitch:new(name, pipeline, previewer_configs, fzf_port_file)
  local previewer_configs_map = {}
  if
    schema.is_previewer_config(previewer_configs --[[@as fzfx.PreviewerConfig]])
  then
    previewer_configs.previewer_type = schema.get_previewer_type_or_default(
      previewer_configs --[[@as fzfx.PreviewerConfig]]
    )
    previewer_configs_map[DEFAULT_PIPELINE] = previewer_configs
  else
    for previewer_name, previewer_opts in pairs(previewer_configs) do
      log.ensure(
        schema.is_previewer_config(
          previewer_opts --[[@as fzfx.PreviewerConfig]]
        ),
        "%s (%s) is not a valid previewer! %s",
        vim.inspect(previewer_name),
        vim.inspect(name),
        vim.inspect(previewer_opts)
      )
      previewer_opts.previewer_type = schema.get_previewer_type_or_default(
        previewer_opts --[[@as fzfx.PreviewerConfig]]
      )
      previewer_configs_map[previewer_name] = previewer_opts
    end
  end

  local o = {
    pipeline = pipeline,
    previewer_configs = previewer_configs_map,
    previewer_labels_queue = {},
    metafile = _previewer_metafile(),
    resultfile = _previewer_resultfile(),
    fzf_port_file = fzf_port_file,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return fzfx.PreviewerConfig
function PreviewerSwitch:current_previewer_config()
  local previewer_config = self.previewer_configs[self.pipeline]
  log.ensure(
    type(previewer_config) == "table",
    "invalid previewer config in %s! previewer config: %s",
    vim.inspect(self.pipeline),
    vim.inspect(previewer_config)
  )
  return previewer_config
end

--- @param next_pipeline fzfx.PipelineName
--- @return nil
function PreviewerSwitch:switch(next_pipeline)
  self.pipeline = next_pipeline
end

--- @param line string?
--- @param context fzfx.PipelineContext
--- @return fzfx.PreviewerType
function PreviewerSwitch:preview(line, context)
  local previewer_config = self.previewer_configs[self.pipeline]
  -- log.debug(
  --     "|fzfx.general - PreviewerSwitch:preview| pipeline:%s, previewer_config:%s, context:%s",
  --     vim.inspect(self.pipeline),
  --     vim.inspect(previewer_config),
  --     vim.inspect(context)
  -- )
  log.ensure(
    type(previewer_config) == "table",
    "invalid previewer config in %s! previewer config: %s",
    vim.inspect(self.pipeline),
    vim.inspect(previewer_config)
  )
  log.ensure(
    type(previewer_config.previewer) == "function",
    "invalid previewer in %s! previewer: %s",
    vim.inspect(self.pipeline),
    vim.inspect(previewer_config)
  )
  log.ensure(
    previewer_config.previewer_type == PreviewerTypeEnum.COMMAND
      or previewer_config.previewer_type == PreviewerTypeEnum.COMMAND_LIST
      or previewer_config.previewer_type == PreviewerTypeEnum.LIST,
    "invalid previewer type in %s! previewer type: %s",
    vim.inspect(self.pipeline),
    vim.inspect(previewer_config)
  )

  local metaopts = make_previewer_meta_opts(self.pipeline, previewer_config)
  local metajson = jsons.encode(metaopts) --[[@as string]]
  fileios.writefile(self.metafile, metajson)

  if previewer_config.previewer_type == PreviewerTypeEnum.COMMAND then
    local ok, result = pcall(previewer_config.previewer, line, context)
    -- log.debug(
    --     "|fzfx.general - PreviewerSwitch:preview| pcall command previewer, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    if not ok then
      fileios.writefile(self.resultfile, "")
      log.err(
        "failed to call pipeline %s command previewer %s! line:%s, context:%s, error:%s",
        vim.inspect(self.pipeline),
        vim.inspect(previewer_config.previewer),
        vim.inspect(line),
        vim.inspect(context),
        vim.inspect(result)
      )
    else
      log.ensure(
        result == nil or type(result) == "string",
        "|PreviewerSwitch:preview| command previewer result must be string! self:%s, result:%s",
        vim.inspect(self),
        vim.inspect(result)
      )
      if result == nil then
        fileios.writefile(self.resultfile, "")
      else
        fileios.writefile(self.resultfile, result --[[@as string]])
      end
    end
  elseif previewer_config.previewer_type == PreviewerTypeEnum.COMMAND_LIST then
    local ok, result = pcall(previewer_config.previewer, line, context)
    -- log.debug(
    --     "|fzfx.general - PreviewerSwitch:preview| pcall command_list previewer, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    if not ok then
      fileios.writefile(self.resultfile, "")
      log.err(
        "failed to call pipeline %s command_list previewer %s! line:%s, context:%s, error:%s",
        vim.inspect(self.pipeline),
        vim.inspect(previewer_config.previewer),
        vim.inspect(line),
        vim.inspect(context),
        vim.inspect(result)
      )
    else
      log.ensure(
        result == nil or type(result) == "table",
        "|PreviewerSwitch:preview| command_list previewer result must be string! self:%s, result:%s",
        vim.inspect(self),
        vim.inspect(result)
      )
      if tables.tbl_empty(result) then
        fileios.writefile(self.resultfile, "")
      else
        fileios.writefile(
          self.resultfile,
          jsons.encode(result --[[@as table]]) --[[@as string]]
        )
      end
    end
  elseif previewer_config.previewer_type == PreviewerTypeEnum.LIST then
    local ok, result = pcall(previewer_config.previewer, line, context)
    -- log.debug(
    --     "|fzfx.general - PreviewerSwitch:preview| pcall list previewer, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    if not ok then
      fileios.writefile(self.resultfile, "")
      log.err(
        "failed to call pipeline %s list previewer %s! line:%s, context:%s, error:%s",
        vim.inspect(self.pipeline),
        vim.inspect(previewer_config.previewer),
        vim.inspect(line),
        vim.inspect(context),
        vim.inspect(result)
      )
    else
      log.ensure(
        type(result) == "table",
        "|PreviewerSwitch:preview| list previewer result must be array! self:%s, result:%s",
        vim.inspect(self),
        vim.inspect(result)
      )
      fileios.writelines(self.resultfile, result --[[@as table]])
    end
  else
    log.throw(
      "|PreviewerSwitch:preview| invalid previewer type! %s",
      vim.inspect(self)
    )
  end

  self:preview_label(line, context)

  return previewer_config.previewer_type
end

--- @param port string
--- @param body string
local function _send_http_post(port, body)
  spawn.run({
    "curl",
    "-s",
    "-S",
    "-q",
    "-Z",
    "--parallel-immediate",
    "--http2",
    "--retry",
    "0",
    "--connect-timeout",
    "1",
    "-m",
    "1",
    "--noproxy",
    "*",
    "-XPOST",
    string.format("127.0.0.1:%s", vim.trim(port)),
    "-d",
    body,
  }, {
    on_stdout = function(line)
      -- log.debug(
      --     "|fzfx.general - send_http_post| stdout:%s",
      --     vim.inspect(line)
      -- )
    end,
    on_stderr = function(line)
      -- log.debug(
      --     "|fzfx.general - send_http_post| stderr:%s",
      --     vim.inspect(line)
      -- )
    end,
    function(completed) end,
  })
end

--- @param line string?
--- @param context fzfx.PipelineContext
--- @return string?
function PreviewerSwitch:preview_label(line, context)
  local previewer_config = self.previewer_configs[self.pipeline]
  -- log.debug(
  --     "|fzfx.general - PreviewerSwitch:preview_label| pipeline:%s, previewer_config:%s, context:%s",
  --     vim.inspect(self.pipeline),
  --     vim.inspect(previewer_config),
  --     vim.inspect(context)
  -- )
  log.ensure(
    type(previewer_config) == "table",
    "invalid previewer config in %s! previewer config: %s",
    vim.inspect(self.pipeline),
    vim.inspect(previewer_config)
  )
  log.ensure(
    type(previewer_config.previewer_label) == "function"
      or previewer_config.previewer_label == nil
      or type(previewer_config.previewer_label) == "boolean"
      or type(previewer_config.previewer_label) == "string",
    "invalid previewer label in %s! previewer: %s",
    vim.inspect(self.pipeline),
    vim.inspect(previewer_config)
  )

  if not consts.HAS_CURL then
    return
  end
  if
    type(previewer_config.previewer_label) ~= "function"
    and type(previewer_config.previewer_label) ~= "string"
  then
    return
  end

  vim.schedule(function()
    local label = type(previewer_config.previewer_label) == "function"
        and previewer_config.previewer_label(line, context)
      or previewer_config.previewer_label
    log.debug(
      "|PreviewerSwitch:preview_label| line:%s, label:%s",
      vim.inspect(line),
      vim.inspect(label)
    )
    if type(label) ~= "string" then
      return
    end
    table.insert(self.previewer_labels_queue, label)

    -- do later
    vim.defer_fn(function()
      if #self.previewer_labels_queue == 0 then
        return
      end
      local last_label =
        self.previewer_labels_queue[#self.previewer_labels_queue]
      self.previewer_labels_queue = {}
      if type(last_label) ~= "string" then
        return
      end
      self.fzf_port = strings.not_empty(self.fzf_port) and self.fzf_port
        or fileios.readfile(self.fzf_port_file, { trim = true }) --[[@as string]]
      if strings.not_empty(self.fzf_port) then
        _send_http_post(
          self.fzf_port,
          string.format("change-preview-label(%s)", vim.trim(last_label))
        )
      end
    end, 200)
  end)

  return self.pipeline
end

-- previewer switch }

-- header switch {

--- @class fzfx.HeaderSwitch
--- @field headers table<fzfx.PipelineName, string[]>
local HeaderSwitch = {}

--- @package
--- @param name string
--- @param action string
--- @return string
local function _render_help(name, action)
  return termcolors.magenta(string.upper(action), "Special")
    .. " to "
    .. table.concat(strings.split(name, "_"), " ")
end

--- @param excludes string[]|nil
--- @param s string
--- @return boolean
local function _should_skip_help(excludes, s)
  if type(excludes) ~= "table" then
    return false
  end
  for _, e in ipairs(excludes) do
    if e == s then
      return true
    end
  end
  return false
end

--- @param action_configs fzfx.Options?
--- @param builder string[]
--- @param excludes string[]|nil
--- @return string[]
local function _make_help_doc(action_configs, builder, excludes)
  if type(action_configs) == "table" then
    local action_names = {}
    for name, opts in pairs(action_configs) do
      if not _should_skip_help(excludes, name) then
        table.insert(action_names, name)
      end
    end
    table.sort(action_names)
    for _, name in ipairs(action_names) do
      local opts = action_configs[name]
      local act = opts.key
      table.insert(builder, _render_help(name, act))
    end
  end
  return builder
end

--- @param provider_configs fzfx.Options
--- @param interaction_configs fzfx.Options
--- @return fzfx.HeaderSwitch
function HeaderSwitch:new(provider_configs, interaction_configs)
  local headers_map = {}
  if schema.is_provider_config(provider_configs) then
    headers_map[DEFAULT_PIPELINE] = _make_help_doc(interaction_configs, {})
  else
    -- log.debug(
    --     "|fzfx.general - HeaderSwitch:new| provider_configs:%s",
    --     vim.inspect(provider_configs)
    -- )
    for provider_name, provider_opts in pairs(provider_configs) do
      local help_builder = _make_help_doc(
        provider_configs,
        {},
        { provider_name }
      )
      headers_map[provider_name] =
        _make_help_doc(interaction_configs, help_builder)
    end
  end

  local o = {
    headers = headers_map,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param pipeline fzfx.PipelineName
--- @return fzfx.FzfOpt?
function HeaderSwitch:get_header(pipeline)
  log.ensure(
    type(self.headers[pipeline]) == "table",
    "|HeaderSwitch:get_header| pipeline (%s) must exists in headers! %s",
    vim.inspect(pipeline),
    vim.inspect(self)
  )
  local switch_help = self.headers[pipeline]
  return string.format(":: Press %s", table.concat(switch_help, ", "))
end

-- header switch }

--- @param pipeline_configs fzfx.Options
local function get_pipeline_size(pipeline_configs)
  local n = 0
  if type(pipeline_configs) == "table" then
    if schema.is_provider_config(pipeline_configs.providers) then
      return 1
    end
    for _, _ in pairs(pipeline_configs.providers) do
      n = n + 1
    end
  end
  return n
end

--- @return fzfx.PipelineContext
local function default_context_maker()
  return {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
end

--- @param name string
--- @param query string
--- @param bang boolean
--- @param pipeline_configs fzfx.Options
--- @param default_pipeline fzfx.PipelineName?
--- @return fzfx.Popup
local function general(name, query, bang, pipeline_configs, default_pipeline)
  local pipeline_size = get_pipeline_size(pipeline_configs)

  --- cache files
  local fzf_port_file = _fzf_port_file()
  local focused_line_file = _focused_line_file()
  local focused_line_fsevent, focused_line_fsevent_err

  --- @type fzfx.Popup
  local popup = nil

  local default_provider_action_key = nil
  if
    default_pipeline == nil
    or pipeline_configs.providers[default_pipeline] == nil
  then
    local pipeline = nil
    local provider_opts = nil
    if schema.is_provider_config(pipeline_configs.providers) then
      -- log.debug(
      --     "|fzfx.general - general| providers is single config: %s",
      --     vim.inspect(pipeline_configs.providers)
      -- )
      pipeline = DEFAULT_PIPELINE
      provider_opts = pipeline_configs.providers
    else
      -- log.debug(
      --     "|fzfx.general - general| providers is multiple configs: %s",
      --     vim.inspect(pipeline_configs.providers)
      -- )
      pipeline, provider_opts = next(pipeline_configs.providers)
    end
    default_pipeline = pipeline
    default_provider_action_key = provider_opts.key
  else
    local provider_opts = pipeline_configs.providers[default_pipeline]
    default_provider_action_key = provider_opts.key
  end

  --- @type fzfx.ProviderSwitch
  local provider_switch =
    ProviderSwitch:new(name, default_pipeline, pipeline_configs.providers)

  --- @type fzfx.PreviewerSwitch
  local previewer_switch = PreviewerSwitch:new(
    name,
    default_pipeline,
    pipeline_configs.previewers,
    fzf_port_file
  )
  local use_builtin_previewer = previewer_switch:current_previewer_config().previewer_type
    == PreviewerTypeEnum.BUILTIN_FILE

  local context_maker = (
    type(pipeline_configs.other_opts) == "table"
    and type(pipeline_configs.other_opts.context_maker) == "function"
  )
      and pipeline_configs.other_opts.context_maker
    or default_context_maker

  local context = context_maker()
  local rpc_registries = {}

  --- @param query_params string
  local function provide_rpc(query_params)
    provider_switch:provide(query_params, context)
  end

  --- @param line_params string
  local function preview_rpc(line_params)
    previewer_switch:preview(line_params, context)
  end

  local provide_rpc_id =
    rpcserver.get_instance():register(provide_rpc, "provide_rpc")
  local preview_rpc_id =
    rpcserver.get_instance():register(preview_rpc, "preview_rpc")
  table.insert(rpc_registries, provide_rpc_id)
  table.insert(rpc_registries, preview_rpc_id)

  local query_command = string.format(
    "%s %s %s %s %s",
    fzf_helpers.make_lua_command("general", "provider.lua"),
    provide_rpc_id,
    provider_switch.metafile,
    provider_switch.resultfile,
    shells.shellescape(query)
  )
  log.debug("|general| query_command:%s", vim.inspect(query_command))
  local reload_query_command = string.format(
    "%s %s %s %s {q}",
    fzf_helpers.make_lua_command("general", "provider.lua"),
    provide_rpc_id,
    provider_switch.metafile,
    provider_switch.resultfile
  )
  log.debug(
    "|general| reload_query_command:%s",
    vim.inspect(reload_query_command)
  )
  local preview_command = string.format(
    "%s %s %s %s {}",
    fzf_helpers.make_lua_command("general", "previewer.lua"),
    preview_rpc_id,
    previewer_switch.metafile,
    previewer_switch.resultfile
  )
  log.debug("|general| preview_command:%s", vim.inspect(preview_command))

  local fzf_opts = {
    "--print-query",
    "--listen",
    { "--query", query },
    {
      "--preview",
      preview_command,
    },
  }

  local dump_fzf_port_command = nil
  if consts.IS_WINDOWS then
    dump_fzf_port_command =
      string.format("cmd.exe /C echo %%FZF_PORT%%>%s", fzf_port_file)
  else
    dump_fzf_port_command = string.format("echo $FZF_PORT>%s", fzf_port_file)
  end
  local fzf_start_binder = fzf_helpers.FzfOptEventBinder:new("start")
  fzf_start_binder:append(
    string.format("execute-silent(%s)", dump_fzf_port_command)
  )

  -- builtin previewer use local file cache to detect fzf pointer movement
  local builtin_previewers_queue = {}
  local builtin_previewers_results_queue = {}
  local builtin_previewers_results_lines_queue = {}
  local fzf_focus_binder = nil
  if use_builtin_previewer then
    local dump_focused_line_command = nil
    if consts.IS_WINDOWS then
      dump_focused_line_command =
        string.format("cmd.exe /C echo {}>%s", focused_line_file)
    else
      dump_focused_line_command = string.format("echo {}>%s", focused_line_file)
    end
    fileios.writefile(focused_line_file, "")
    fzf_focus_binder = fzf_helpers.FzfOptEventBinder:new("focus")
    fzf_focus_binder:append(
      string.format("execute-silent(%s)", dump_focused_line_command)
    )
    focused_line_fsevent, focused_line_fsevent_err = uv.new_fs_event() --[[@as uv_fs_event_t]]
    log.ensure(
      focused_line_fsevent ~= nil,
      string.format(
        "failed to create new fs event for %s, error: %s",
        vim.inspect(name),
        vim.inspect(focused_line_fsevent_err)
      )
    )
    local focused_line_fsevent_start_result, focused_line_fsevent_start_err = focused_line_fsevent:start(
      focused_line_file,
      {},
      function(focused_err, focused_file, events)
        log.debug(
          "|general.focused_line_fsevent:start| focused_err:%s, focused_file:%s, events:%s, focused_line_file:%s",
          vim.inspect(focused_err),
          vim.inspect(focused_file),
          vim.inspect(events),
          vim.inspect(focused_line_file)
        )
        if focused_err then
          log.err(
            "failed to trigger focused line on cache file %s, error:%s",
            vim.inspect(focused_line_file),
            vim.inspect(focused_err)
          )
          return
        end

        if not strings.find(focused_line_file, focused_file) then
          return
        end
        log.debug(
          "|general.focused_line_fsevent:start| start read focused_file:%s",
          vim.inspect(focused_file)
        )
        fileios.asyncreadfile(focused_line_file, function(focused_data)
          log.debug(
            "|general.focused_line_fsevent:start| complete read focused_file:%s, data:%s, queue:%s",
            vim.inspect(focused_file),
            vim.inspect(focused_data),
            vim.inspect(builtin_previewers_queue)
          )
          if consts.IS_WINDOWS then
            if strings.startswith(focused_data, '"') then
              focused_data = string.sub(focused_data, 2)
            end
            if strings.endswith(focused_data, '"') then
              focused_data = string.sub(focused_data, 1, #focused_data - 1)
            end
          end
          table.insert(
            builtin_previewers_queue,
            { previewer_switch:current_previewer_config(), focused_data }
          )
          vim.defer_fn(function()
            if #builtin_previewers_queue == 0 then
              return
            end
            local last_item =
              builtin_previewers_queue[#builtin_previewers_queue]
            builtin_previewers_queue = {}
            local previewer_winnr1 = tables.tbl_get(
              popup,
              "popup_window",
              "instance",
              "previewer_winnr"
            )
            local previewer_bufnr1 = tables.tbl_get(
              popup,
              "popup_window",
              "instance",
              "previewer_bufnr"
            )
            if
              type(previewer_winnr1) ~= "number"
              or type(previewer_bufnr1) ~= "number"
            then
              return
            end

            local previewer_config = last_item[1]
            local focused_line = last_item[2]
            local ok, result =
              pcall(previewer_config.previewer, focused_line, context)
            -- log.debug(
            --     "|fzfx.general - PreviewerSwitch:preview| pcall command previewer, ok:%s, result:%s",
            --     vim.inspect(ok),
            --     vim.inspect(result)
            -- )
            if not ok then
              log.err(
                "failed to call pipeline %s builtin previewer %s! line:%s, context:%s, error:%s",
                vim.inspect(previewer_config.pipeline),
                vim.inspect(previewer_config.previewer),
                vim.inspect(focused_line),
                vim.inspect(context),
                vim.inspect(result)
              )
            else
              log.ensure(
                result == nil or type(result) == "table",
                "|general.focused_line_fsevent.asyncreadfile| builtin previewer result must be table! previewer_config:%s, result:%s",
                vim.inspect(previewer_config),
                vim.inspect(result)
              )
              if result and strings.not_empty(result.filename) then
                table.insert(builtin_previewers_results_queue, result)
              end
              vim.defer_fn(function()
                if #builtin_previewers_queue > 0 then
                  return
                end
                if #builtin_previewers_results_queue == 0 then
                  return
                end
                local last_result =
                  builtin_previewers_results_queue[#builtin_previewers_results_queue]
                builtin_previewers_results_queue = {}
                local previewer_winnr2 = tables.tbl_get(
                  popup,
                  "popup_window",
                  "instance",
                  "previewer_winnr"
                )
                local previewer_bufnr2 = tables.tbl_get(
                  popup,
                  "popup_window",
                  "instance",
                  "previewer_bufnr"
                )
                if
                  type(previewer_winnr2) ~= "number"
                  or type(previewer_bufnr2) ~= "number"
                then
                  return
                end

                -- set file lines on popup's buffer
                fileios.asyncreadfile(
                  last_result.filename,
                  function(result_data)
                    local lines = {}
                    if type(result_data) == "string" then
                      result_data = result_data:gsub("\r\n", "\n")
                      lines = strings.split(result_data, "\n")
                    end
                    table.insert(
                      builtin_previewers_results_lines_queue,
                      { lines = lines, last_result = last_result }
                    )
                    vim.schedule(function()
                      local previewer_winnr = tables.tbl_get(
                        popup,
                        "popup_window",
                        "instance",
                        "previewer_winnr"
                      )
                      local previewer_bufnr = tables.tbl_get(
                        popup,
                        "popup_window",
                        "instance",
                        "previewer_bufnr"
                      )
                      if
                        type(previewer_winnr) ~= "number"
                        or type(previewer_bufnr) ~= "number"
                      then
                        return
                      end
                      if #builtin_previewers_queue > 0 then
                        return
                      end
                      if #builtin_previewers_results_queue > 0 then
                        return
                      end
                      if #builtin_previewers_results_lines_queue == 0 then
                        return
                      end
                      local last_lines_item =
                        builtin_previewers_results_lines_queue[#builtin_previewers_results_lines_queue]
                      builtin_previewers_results_lines_queue = {}

                      vim.api.nvim_buf_set_lines(
                        previewer_bufnr,
                        0,
                        -1,
                        false,
                        {}
                      )
                      vim.api.nvim_buf_set_name(
                        previewer_bufnr,
                        last_lines_item.last_result.filename
                      )
                      vim.api.nvim_buf_call(previewer_bufnr, function()
                        vim.api.nvim_command([[filetype detect]])
                      end)

                      local line_index = 1
                      local line_count = 10

                      local function set_buf_lines()
                        vim.schedule(function()
                          if #builtin_previewers_queue > 0 then
                            return
                          end
                          if #builtin_previewers_results_queue > 0 then
                            return
                          end
                          if #builtin_previewers_results_lines_queue > 0 then
                            return
                          end
                          local buf_lines = {}
                          for i = line_index, line_index + line_count do
                            if i <= #last_lines_item.lines then
                              table.insert(buf_lines, last_lines_item.lines[i])
                            end
                          end
                          vim.api.nvim_buf_set_lines(
                            previewer_bufnr,
                            line_index - 1,
                            line_index - 1 + line_count,
                            false,
                            buf_lines
                          )
                          line_index = line_index + line_count
                          if line_index <= #last_lines_item.lines then
                            set_buf_lines()
                          end
                        end)
                      end
                      set_buf_lines()
                    end)
                  end
                )
              end, 100)
              -- end
            end
          end, 100)
        end, { trim = true })
      end
    )
    log.ensure(
      focused_line_fsevent_start_result ~= nil,
      "failed to start watching fsevent on %s, error: %s",
      vim.inspect(focused_line_file),
      vim.inspect(focused_line_fsevent_start_err)
    )
  end

  local header_switch =
    HeaderSwitch:new(pipeline_configs.providers, pipeline_configs.interactions)

  -- have interactions or pipelines >= 2
  if type(pipeline_configs.interactions) == "table" or pipeline_size > 1 then
    local header = header_switch:get_header(default_pipeline)
    table.insert(fzf_opts, {
      "--header",
      header,
    })
  end

  -- when no interactions, no need to add help
  if type(pipeline_configs.interactions) == "table" then
    for _, interaction_opts in pairs(pipeline_configs.interactions) do
      local action_key = string.lower(interaction_opts.key)
      local action = interaction_opts.interaction

      local function interaction_rpc(line_params)
        log.debug(
          "|general.interaction_rpc| line_params:%s",
          vim.inspect(line_params)
        )
        action(line_params, context)
      end

      local interaction_rpc_id =
        rpcserver.get_instance():register(interaction_rpc, "interaction_rpc")
      table.insert(rpc_registries, interaction_rpc_id)

      local action_command = string.format(
        "%s %s {}",
        fzf_helpers.make_lua_command("rpc", "request.lua"),
        interaction_rpc_id
      )
      local bind_builder =
        string.format("%s:execute-silent(%s)", action_key, action_command)
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

  -- when only have 1 pipeline, no need to add help for switch keys
  if pipeline_size > 1 then
    for pipeline, provider_opts in pairs(pipeline_configs.providers) do
      local switch_key = string.lower(provider_opts.key)

      local function switch_rpc()
        provider_switch:switch(pipeline)
        previewer_switch:switch(pipeline)
      end

      local switch_rpc_id =
        rpcserver.get_instance():register(switch_rpc, "switch_rpc")
      table.insert(rpc_registries, switch_rpc_id)

      local switch_command = string.format(
        "%s %s",
        fzf_helpers.make_lua_command("rpc", "request.lua"),
        switch_rpc_id
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
    fzf_start_binder:append(
      string.format("unbind(%s)", default_provider_action_key)
    )
  end
  if
    type(pipeline_configs.other_opts) == "table"
    and pipeline_configs.other_opts.reload_on_change
  then
    table.insert(fzf_opts, {
      "--bind",
      string.format("change:reload(%s)", reload_query_command),
    })
  end
  table.insert(fzf_opts, fzf_start_binder:build())
  if fzf_focus_binder then
    table.insert(fzf_opts, fzf_focus_binder:build())
  end

  -- fzf_opts
  fzf_opts = vim.list_extend(fzf_opts, vim.deepcopy(pipeline_configs.fzf_opts))
  fzf_opts = vim.list_extend(
    fzf_opts,
    vim.deepcopy(config.get().override_fzf_opts or {})
  )
  fzf_opts = fzf_helpers.preprocess_fzf_opts(fzf_opts)

  -- actions
  local actions = pipeline_configs.actions

  -- win_opts
  local config_win_opts = tables.tbl_get(config.get(), "popup", "win_opts")
  local win_opts = nil
  if type(config_win_opts) == "function" then
    win_opts =
      vim.deepcopy(tables.tbl_get(config.get_defaults(), "popup", "win_opts"))
    win_opts = vim.tbl_deep_extend(
      "force",
      vim.deepcopy(win_opts or {}),
      config_win_opts() or {}
    )
  elseif type(config_win_opts) == "table" then
    win_opts = vim.deepcopy(config_win_opts)
  end

  if pipeline_configs.win_opts ~= nil then
    local pipeline_win_opts = nil
    if type(pipeline_configs.win_opts) == "function" then
      pipeline_win_opts = pipeline_configs.win_opts()
    elseif type(pipeline_configs.win_opts) == "table" then
      pipeline_win_opts = pipeline_configs.win_opts
    end
    win_opts = vim.tbl_deep_extend(
      "force",
      vim.deepcopy(win_opts or {}),
      pipeline_win_opts
    )
  end
  if bang then
    win_opts = vim.tbl_deep_extend(
      "force",
      vim.deepcopy(win_opts or {}),
      { height = 1, width = 1, row = 0, col = 0 }
    )
  end

  if use_builtin_previewer then
    table.insert(fzf_opts, { "--preview-window", "hidden" })
  end

  popup = Popup:new(
    win_opts or {},
    query_command,
    fzf_opts,
    actions,
    context,
    function(last_query)
      for _, rpc_id in ipairs(rpc_registries) do
        rpcserver.get_instance():unregister(rpc_id)
      end
      local last_query_cache = fzf_helpers.last_query_cache_name(name)
      fzf_helpers.save_last_query_cache(
        name,
        last_query,
        provider_switch.pipeline
      )
      local content = jsons.encode({
        default_provider = provider_switch.pipeline,
        query = last_query,
      }) --[[@as string]]
      fileios.asyncwritefile(last_query_cache, content, function(bytes)
        log.debug("|general| dump last query:%s", vim.inspect(bytes))
      end)
      if focused_line_fsevent then
        focused_line_fsevent:stop()
        focused_line_fsevent = nil
      end
    end,
    use_builtin_previewer
  )
  return popup
end

--- @param name string
--- @param command_config fzfx.CommandConfig
--- @param variant_configs fzfx.VariantConfig[]
--- @param group_config fzfx.GroupConfig
local function _make_user_command(
  name,
  command_config,
  variant_configs,
  group_config
)
  local command_name = command_config.name
  local command_desc = command_config.desc

  vim.api.nvim_create_user_command(command_name, function(opts)
    -- log.debug(
    --   "|_make_user_command| command_name:%s, opts:%s",
    --   vim.inspect(command_name),
    --   vim.inspect(opts)
    -- )
    local input_args = strings.trim(opts.args or "")
    if strings.empty(input_args) then
      input_args = variant_configs[1].name
    end
    log.ensure(
      strings.not_empty(input_args),
      "missing args in command: %s",
      vim.inspect(command_name),
      vim.inspect(input_args)
    )

    --- @type fzfx.VariantConfig
    local varcfg = nil
    local first_space_pos = strings.find(input_args, " ")
    local first_arg = first_space_pos ~= nil
        and string.sub(input_args, 1, first_space_pos - 1)
      or input_args
    for i, variant in ipairs(variant_configs) do
      if first_arg == variant.name then
        varcfg = variant
        break
      end
    end
    log.ensure(
      varcfg ~= nil,
      "unknown command (%s) variant: %s",
      vim.inspect(command_name),
      vim.inspect(input_args)
    )

    local other_args = first_space_pos ~= nil
        and strings.trim(string.sub(input_args, first_space_pos))
      or ""
    local feed_obj = fzf_helpers.get_command_feed(varcfg.feed, other_args, name)
      or { query = "" }

    local default_provider = feed_obj.default_provider
      or varcfg.default_provider

    return general(
      name,
      feed_obj.query,
      opts.bang,
      group_config,
      default_provider
    )
  end, {
    nargs = "*",
    range = true,
    bang = true,
    desc = command_desc,
    complete = function(ArgLead, CmdLine, CursorPos)
      local sub_commands = {}
      for i, variant in ipairs(variant_configs) do
        if strings.not_empty(variant.name) then
          table.insert(sub_commands, variant.name)
        end
      end
      return sub_commands
    end,
  })
end

--- @param name string
--- @param pipeline_configs fzfx.GroupConfig?
local function setup(name, pipeline_configs)
  if not pipeline_configs then
    return
  end

  -- log.debug(
  --     "|fzfx.general - setup| pipeline_configs:%s",
  --     vim.inspect(pipeline_configs)
  -- )
  _make_user_command(
    name,
    pipeline_configs.command,
    schema.is_variant_config(pipeline_configs.variants)
        and { pipeline_configs.variants }
      or pipeline_configs.variants,
    pipeline_configs
  )
end

local M = {
  setup = setup,
  _make_user_command = _make_user_command,
  _make_cache_filename = _make_cache_filename,
  _provider_metafile = _provider_metafile,
  _provider_resultfile = _provider_resultfile,
  _previewer_metafile = _previewer_metafile,
  _previewer_resultfile = _previewer_resultfile,
  _fzf_port_file = _fzf_port_file,
  make_provider_meta_opts = make_provider_meta_opts,
  make_previewer_meta_opts = make_previewer_meta_opts,
  ProviderSwitch = ProviderSwitch,
  PreviewerSwitch = PreviewerSwitch,
  _send_http_post = _send_http_post,
  _render_help = _render_help,
  _should_skip_help = _should_skip_help,
  _make_help_doc = _make_help_doc,
  HeaderSwitch = HeaderSwitch,
}

return M
