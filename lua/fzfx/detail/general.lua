local tables = require("fzfx.commons.tables")
local paths = require("fzfx.commons.paths")
local jsons = require("fzfx.commons.jsons")
local strings = require("fzfx.commons.strings")
local termcolors = require("fzfx.commons.termcolors")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")
local uv = require("fzfx.commons.uv")
local numbers = require("fzfx.commons.numbers")

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
local function _buffer_previewer_focused_file()
  return _make_cache_filename("buffer", "previewer", "focused", "file")
end

--- @return string
local function _buffer_previewer_actions_file()
  return _make_cache_filename("buffer", "previewer", "actions", "file")
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
function PreviewerSwitch:current()
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

  self:_preview_label(line, context)

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
function PreviewerSwitch:_preview_label(line, context)
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
  local buffer_previewer_focused_file = _buffer_previewer_focused_file()
  local buffer_previewer_focused_fsevent, buffer_previewer_focused_fsevent_err
  local buffer_previewer_actions_file = _buffer_previewer_actions_file()
  local buffer_previewer_actions_fsevent, buffer_previewer_actions_fsevent_err

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
  local use_buffer_previewer = previewer_switch:current().previewer_type
    == PreviewerTypeEnum.BUFFER_FILE

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

  local provide_rpc_id =
    rpcserver.get_instance():register(provide_rpc, "provide_rpc")
  table.insert(rpc_registries, provide_rpc_id)

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

  local fzf_opts = vim.deepcopy(config.get().fzf_opts)
  fzf_opts = vim.list_extend(
    fzf_opts,
    { "--print-query", "--listen", { "--query", query } }
  )

  --- @param line_params string
  local function preview_rpc(line_params)
    previewer_switch:preview(line_params, context)
  end

  if not use_buffer_previewer then
    local preview_rpc_id =
      rpcserver.get_instance():register(preview_rpc, "preview_rpc")
    table.insert(rpc_registries, preview_rpc_id)
    local preview_command = string.format(
      "%s %s %s %s {}",
      fzf_helpers.make_lua_command("general", "previewer.lua"),
      preview_rpc_id,
      previewer_switch.metafile,
      previewer_switch.resultfile
    )
    log.debug("|general| preview_command:%s", vim.inspect(preview_command))
    table.insert(fzf_opts, {
      "--preview",
      preview_command,
    })
  end

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

  -- buffer previewer use local file cache to detect fzf pointer movement
  --- @type {previewer_config:fzfx.PreviewerConfig,focused_line:string?,job_id:integer}[]
  local buffer_preview_files_queue = {}
  local buffer_preview_job_id = numbers.auto_incremental_id()

  local function buffer_preview_files_queue_empty()
    return #buffer_preview_files_queue == 0
  end

  local function buffer_preview_files_queue_last()
    return buffer_preview_files_queue[#buffer_preview_files_queue]
  end

  local function buffer_preview_files_queue_clear()
    buffer_preview_files_queue = {}
  end

  local fzf_focus_binder = nil
  local fzf_load_binder = nil
  if use_buffer_previewer then
    local dump_focused_line_command = nil
    if consts.IS_WINDOWS then
      dump_focused_line_command =
        string.format("cmd.exe /C echo {}>%s", buffer_previewer_focused_file)
    else
      dump_focused_line_command =
        string.format("echo {}>%s", buffer_previewer_focused_file)
    end
    fzf_focus_binder = fzf_helpers.FzfOptEventBinder:new("focus")
    fzf_focus_binder:append(
      string.format("execute-silent(%s)", dump_focused_line_command)
    )
    fzf_load_binder = fzf_helpers.FzfOptEventBinder:new("load")
    fzf_load_binder:append(
      string.format("execute-silent(%s)", dump_focused_line_command)
    )

    -- buffer_previewer_focused_file {
    fileios.writefile(buffer_previewer_focused_file, "")
    buffer_previewer_focused_fsevent, buffer_previewer_focused_fsevent_err =
      uv.new_fs_event() --[[@as uv_fs_event_t]]
    log.ensure(
      buffer_previewer_focused_fsevent ~= nil,
      string.format(
        "|general| failed to create new fsevent for %s (buffer_previewer_focused_file:%s), error: %s",
        vim.inspect(name),
        vim.inspect(buffer_previewer_focused_file),
        vim.inspect(buffer_previewer_focused_fsevent_err)
      )
    )
    local focused_fsevent_start_result, focused_fsevent_start_err = buffer_previewer_focused_fsevent:start(
      buffer_previewer_focused_file,
      {},
      function(focused_fsevent_start_complete_err, focused_file, events)
        -- log.debug(
        --   "|general - buffer_previewer_focused_fsevent:start| failed to complete fsevent, fsevent_file:%s, events:%s, focused_file:%s, error:%s",
        --   vim.inspect(fsevent_file),
        --   vim.inspect(events),
        --   vim.inspect(buffer_previewer_focused_file),
        --   vim.inspect(fsevent_start_complete_err)
        -- )
        if focused_fsevent_start_complete_err then
          log.err(
            "|general - buffer_previewer_focused_fsevent:start| failed to trigger fsevent on focused_file %s, error:%s",
            vim.inspect(buffer_previewer_focused_file),
            vim.inspect(focused_fsevent_start_complete_err)
          )
          return
        end
        if not strings.find(buffer_previewer_focused_file, focused_file) then
          return
        end

        buffer_preview_job_id = numbers.auto_incremental_id()
        popup.popup_window:set_preview_file_job_id(buffer_preview_job_id)
        -- log.debug(
        --   "|general - buffer_previewer_focused_fsevent:start| start read focused_file:%s",
        --   vim.inspect(fsevent_file)
        -- )
        fileios.asyncreadfile(
          buffer_previewer_focused_file,
          function(focused_data)
            -- log.debug(
            --   "|general - buffer_previewer_focused_fsevent:start| complete read focused_file:%s, data:%s, queue:%s",
            --   vim.inspect(fsevent_file),
            --   vim.inspect(focused_data),
            --   vim.inspect(buffer_preview_files_queue)
            -- )
            if not popup.popup_window:is_valid() then
              return
            end
            if consts.IS_WINDOWS then
              if strings.startswith(focused_data, '"') then
                focused_data = string.sub(focused_data, 2)
              end
              if strings.endswith(focused_data, '"') then
                focused_data = string.sub(focused_data, 1, #focused_data - 1)
              end
            end

            table.insert(buffer_preview_files_queue, {
              previewer_config = previewer_switch:current(),
              focused_line = focused_data,
              job_id = buffer_preview_job_id,
            })
            vim.defer_fn(function()
              if not popup.popup_window:is_valid() then
                return
              end
              if buffer_preview_files_queue_empty() then
                return
              end
              local last_preview_job = buffer_preview_files_queue_last()
              buffer_preview_files_queue_clear()
              if last_preview_job.job_id < buffer_preview_job_id then
                return
              end

              popup.popup_window:set_preview_file_job_id(
                last_preview_job.job_id
              )

              local previewer_config = last_preview_job.previewer_config
              local focused_line = last_preview_job.focused_line
              local last_preview_job_id = last_preview_job.job_id
              local previewer_ok, previewer_result =
                pcall(previewer_config.previewer, focused_line, context)
              -- log.debug(
              --     "|fzfx.general - PreviewerSwitch:preview| pcall command previewer, ok:%s, result:%s",
              --     vim.inspect(ok),
              --     vim.inspect(result)
              -- )
              if not previewer_ok then
                log.err(
                  "failed to call pipeline %s buffer previewer %s! line:%s, context:%s, error:%s",
                  vim.inspect(previewer_config.pipeline),
                  vim.inspect(previewer_config.previewer),
                  vim.inspect(focused_line),
                  vim.inspect(context),
                  vim.inspect(previewer_result)
                )
              else
                log.ensure(
                  previewer_result == nil or type(previewer_result) == "table",
                  "|general - buffer_previewer_focused_fsevent.asyncreadfile| buffer previewer result must be table! previewer_config:%s, result:%s",
                  vim.inspect(previewer_config),
                  vim.inspect(previewer_result)
                )
                local previewer_label_ok
                local previewer_label_result
                if type(previewer_config.previewer_label) == "string" then
                  previewer_label_ok = true
                  previewer_label_result = previewer_config.previewer_label
                elseif type(previewer_config.previewer_label) == "function" then
                  previewer_label_ok, previewer_label_result = pcall(
                    previewer_config.previewer_label --[[@as function]],
                    focused_line,
                    context
                  )
                  if not previewer_label_ok then
                    log.err(
                      "failed to call previewer label(%s) on buffer previewer! focused_line:%s, context:%s, error:%s",
                      vim.inspect(previewer_config),
                      vim.inspect(focused_line),
                      vim.inspect(context),
                      vim.inspect(previewer_label_result)
                    )
                    previewer_label_result = nil
                  end
                end
                if previewer_result then
                  popup.popup_window:preview_file(
                    last_preview_job_id,
                    previewer_result --[[@as fzfx.BufferFilePreviewerResult]],
                    previewer_label_result --[[@as string?]]
                  )
                end
              end
            end, 50)
          end,
          { trim = true }
        )
      end
    )
    log.ensure(
      focused_fsevent_start_result ~= nil,
      "failed to start watching fsevent on %s, error: %s",
      vim.inspect(buffer_previewer_focused_file),
      vim.inspect(focused_fsevent_start_err)
    )
    -- buffer_previewer_focused_file }

    -- buffer_previewer_actions_file {
    fileios.writefile(buffer_previewer_actions_file, "")
    buffer_previewer_actions_fsevent, buffer_previewer_actions_fsevent_err =
      uv.new_fs_event() --[[@as uv_fs_event_t]]
    log.ensure(
      buffer_previewer_actions_fsevent ~= nil,
      string.format(
        "|general| failed to create new fsevent for %s(buffer_previewer_actions_file:%s), error: %s",
        vim.inspect(name),
        vim.inspect(buffer_previewer_actions_fsevent),
        vim.inspect(buffer_previewer_actions_fsevent_err)
      )
    )
    local actions_fsevent_start_result, actions_fsevent_start_err = buffer_previewer_actions_fsevent:start(
      buffer_previewer_focused_file,
      {},
      function(actions_fsevent_start_complete_err, actions_file, events)
        if actions_fsevent_start_complete_err then
          log.err(
            "|general - buffer_previewer_actions_fsevent:start| failed to trigger fsevent on actions_file %s, error:%s",
            vim.inspect(buffer_previewer_actions_file),
            vim.inspect(actions_fsevent_start_complete_err)
          )
          return
        end
        if not strings.find(buffer_previewer_actions_file, actions_file) then
          return
        end
        fileios.asyncreadfile(
          buffer_previewer_actions_file,
          function(actions_data)
            if not popup.popup_window:is_valid() then
              return
            end
            if consts.IS_WINDOWS then
              if strings.startswith(actions_data, '"') then
                actions_data = string.sub(actions_data, 2)
              end
              if strings.endswith(actions_data, '"') then
                actions_data = string.sub(actions_data, 1, #actions_data - 1)
              end
            end
            popup.popup_window:preview_action(actions_data)
          end,
          { trim = true }
        )
      end
    )
    log.ensure(
      actions_fsevent_start_result ~= nil,
      "failed to start watching fsevent on %s, error: %s",
      vim.inspect(buffer_previewer_actions_file),
      vim.inspect(actions_fsevent_start_err)
    )
    -- buffer_previewer_actions_file }
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
  if fzf_load_binder then
    table.insert(fzf_opts, fzf_load_binder:build())
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

  --- @type fzfx.FzfPreviewWindowOpts
  local buffer_previewer_fzf_preview_window_opts =
    fzf_helpers.parse_fzf_preview_window_opts({
      {
        "--preview-window",
        "right,50%",
      },
    })
  local buffer_previewer_fzf_border_opts = fzf_helpers.FZF_DEFAULT_BORDER_OPTS
  if use_buffer_previewer then
    local fzf_pw_opts = {}
    local base_config_fzf_opts =
      fzf_helpers.preprocess_fzf_opts(vim.deepcopy(config.get().fzf_opts or {}))
    for _, o in ipairs(base_config_fzf_opts) do
      if
        type(o) == "table"
        and strings.not_empty(o[1])
        and strings.startswith(o[1], "--border")
      then
        buffer_previewer_fzf_border_opts = o[2]
      elseif
        strings.not_empty(o)
        and strings.startswith(o --[[@as string]], "--border")
      then
        buffer_previewer_fzf_border_opts =
          string.sub(o --[[@as string]], string.len("--border") + 2)
      end
    end
    for _, o in ipairs(fzf_opts) do
      if
        type(o) == "table"
        and strings.not_empty(o[1])
        and strings.startswith(o[1], "--preview-window")
      then
        table.insert(fzf_pw_opts, o)
      elseif
        strings.not_empty(o)
        and strings.startswith(o --[[@as string]], "--preview-window")
      then
        table.insert(fzf_pw_opts, o)
      end
      if
        type(o) == "table"
        and strings.not_empty(o[1])
        and strings.startswith(o[1], "--border")
      then
        buffer_previewer_fzf_border_opts = o[2]
      elseif
        strings.not_empty(o)
        and strings.startswith(o --[[@as string]], "--border")
      then
        buffer_previewer_fzf_border_opts =
          string.sub(o --[[@as string]], string.len("--border") + 2)
      end
    end
    log.debug(
      "|general| extract fzf_pw_opts:%s, fzf_border_opts:%s, fzf_opts:%s",
      vim.inspect(fzf_pw_opts),
      vim.inspect(buffer_previewer_fzf_border_opts),
      vim.inspect(fzf_opts)
    )
    if #fzf_pw_opts > 0 then
      buffer_previewer_fzf_preview_window_opts =
        fzf_helpers.parse_fzf_preview_window_opts(fzf_pw_opts)
    end

    table.insert(fzf_opts, { "--preview-window", "hidden" })
    table.insert(fzf_opts, "--border=none")

    -- local removed_preview_keys_fzf_opts = {}
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
      if buffer_previewer_focused_fsevent then
        buffer_previewer_focused_fsevent:stop()
        buffer_previewer_focused_fsevent = nil
      end
    end,
    use_buffer_previewer,
    {
      fzf_preview_window_opts = buffer_previewer_fzf_preview_window_opts,
      fzf_border_opts = buffer_previewer_fzf_border_opts,
    }
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
  _buffer_previewer_focused_file = _buffer_previewer_focused_file,
  _buffer_previewer_actions_file = _buffer_previewer_actions_file,
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
