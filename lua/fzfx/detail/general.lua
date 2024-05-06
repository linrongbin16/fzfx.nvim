local tbl = require("fzfx.commons.tbl")
local path = require("fzfx.commons.path")
local json = require("fzfx.commons.json")
local str = require("fzfx.commons.str")
local num = require("fzfx.commons.num")
local term_color = require("fzfx.commons.color.term")
local fileio = require("fzfx.commons.fileio")
local spawn = require("fzfx.commons.spawn")
local uv = require("fzfx.commons.uv")

local constants = require("fzfx.lib.constants")
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
    local confs = config.get()
    return path.join(confs.cache.dir, table.concat({ ... }, "_"))
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
  -- return _make_cache_filename("fzf", "port", "file")
  return vim.fn.tempname() --[[@as string]]
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
  if tbl.tbl_get(provider_config, "provider_decorator") then
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
    provider_configs.provider_type = schema.get_provider_type_or_default(provider_configs)
    provider_configs_map[DEFAULT_PIPELINE] = provider_configs
  else
    for provider_name, provider_opts in pairs(provider_configs) do
      log.ensure(
        schema.is_provider_config(provider_opts),
        string.format(
          "%s (%s) is not a valid provider! %s",
          vim.inspect(provider_name),
          vim.inspect(name),
          vim.inspect(provider_opts)
        )
      )
      provider_opts.provider_type = schema.get_provider_type_or_default(provider_opts)
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
    string.format(
      "invalid provider config in %s! provider config: %s",
      vim.inspect(self.pipeline),
      vim.inspect(provider_config)
    )
  )
  log.ensure(
    type(provider_config.provider) == "table"
      or type(provider_config.provider) == "string"
      or type(provider_config.provider) == "function",
    string.format(
      "invalid provider in %s! provider: %s",
      vim.inspect(self.pipeline),
      vim.inspect(provider_config)
    )
  )
  log.ensure(
    provider_config.provider_type == ProviderTypeEnum.PLAIN
      or provider_config.provider_type == ProviderTypeEnum.PLAIN_LIST
      or provider_config.provider_type == ProviderTypeEnum.COMMAND
      or provider_config.provider_type == ProviderTypeEnum.COMMAND_LIST
      or provider_config.provider_type == ProviderTypeEnum.LIST,
    string.format(
      "invalid provider type in %s! provider type: %s",
      vim.inspect(self.pipeline),
      vim.inspect(provider_config)
    )
  )

  local metaopts = make_provider_meta_opts(self.pipeline, provider_config)
  local metajson = json.encode(metaopts) --[[@as string]]
  fileio.writefile(self.metafile, metajson)

  if provider_config.provider_type == ProviderTypeEnum.PLAIN then
    log.ensure(
      provider_config.provider == nil or type(provider_config.provider) == "string",
      string.format(
        "|ProviderSwitch:provide| plain provider must be string or nil! self:%s, provider:%s",
        vim.inspect(self),
        vim.inspect(provider_config)
      )
    )
    if provider_config.provider == nil then
      fileio.writefile(self.resultfile, "")
    else
      fileio.writefile(self.resultfile, provider_config.provider --[[@as string]])
    end
  elseif provider_config.provider_type == ProviderTypeEnum.PLAIN_LIST then
    log.ensure(
      provider_config.provider == nil or type(provider_config.provider) == "table",
      string.format(
        "|ProviderSwitch:provide| plain_list provider must be string or nil! self:%s, provider:%s",
        vim.inspect(self),
        vim.inspect(provider_config)
      )
    )
    if tbl.tbl_empty(provider_config.provider) then
      fileio.writefile(self.resultfile, "")
    else
      fileio.writefile(
        self.resultfile,
        json.encode(provider_config.provider --[[@as table]]) --[[@as string]]
      )
    end
  elseif provider_config.provider_type == ProviderTypeEnum.COMMAND then
    local ok, result = pcall(provider_config.provider --[[@as function]], query, context)
    -- log.debug(
    --     "|fzfx.general - ProviderSwitch:provide| pcall command provider, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    log.ensure(
      result == nil or type(result) == "string",
      string.format(
        "|ProviderSwitch:provide| command provider result must be string! self:%s, result:%s",
        vim.inspect(self),
        vim.inspect(result)
      )
    )
    if not ok then
      fileio.writefile(self.resultfile, "")
      log.err(
        string.format(
          "failed to call pipeline %s command provider %s! query:%s, context:%s, error:%s",
          vim.inspect(self.pipeline),
          vim.inspect(provider_config),
          vim.inspect(query),
          vim.inspect(context),
          vim.inspect(result)
        )
      )
    else
      if result == nil then
        fileio.writefile(self.resultfile, "")
      else
        fileio.writefile(self.resultfile, result)
      end
    end
  elseif provider_config.provider_type == ProviderTypeEnum.COMMAND_LIST then
    local ok, result = pcall(provider_config.provider --[[@as function]], query, context)
    -- log.debug(
    --     "|fzfx.general - ProviderSwitch:provide| pcall command_list provider, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    log.ensure(
      result == nil or type(result) == "table",
      string.format(
        "|ProviderSwitch:provide| command_list provider result must be string! self:%s, result:%s",
        vim.inspect(self),
        vim.inspect(result)
      )
    )
    if not ok then
      fileio.writefile(self.resultfile, "")
      log.err(
        string.format(
          "failed to call pipeline %s command_list provider %s! query:%s, context:%s, error:%s",
          vim.inspect(self.pipeline),
          vim.inspect(provider_config),
          vim.inspect(query),
          vim.inspect(context),
          vim.inspect(result)
        )
      )
    else
      if tbl.tbl_empty(result) then
        fileio.writefile(self.resultfile, "")
      else
        fileio.writefile(self.resultfile, json.encode(result) --[[@as string]])
      end
    end
  elseif provider_config.provider_type == ProviderTypeEnum.LIST then
    local ok, result = pcall(provider_config.provider --[[@as function]], query, context)
    -- log.debug(
    --     "|fzfx.general - ProviderSwitch:provide| pcall list provider, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    if not ok then
      fileio.writefile(self.resultfile, "")
      log.err(
        string.format(
          "failed to call pipeline %s list provider %s! query:%s, context:%s, error:%s",
          vim.inspect(self.pipeline),
          vim.inspect(provider_config),
          vim.inspect(query),
          vim.inspect(context),
          vim.inspect(result)
        )
      )
    else
      log.ensure(
        result == nil or type(result) == "table",
        string.format(
          "|ProviderSwitch:provide| list provider result must be array! self:%s, result:%s",
          vim.inspect(self),
          vim.inspect(result)
        )
      )
      if tbl.tbl_empty(result) then
        fileio.writefile(self.resultfile, "")
      else
        fileio.writelines(self.resultfile, result)
      end
    end
  else
    log.throw(
      string.format("|ProviderSwitch:provide| invalid provider type! %s", vim.inspect(self))
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
--- @field fzf_port_reader commons.CachedFileReader
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
    previewer_configs.previewer_type =
      schema.get_previewer_type_or_default(previewer_configs --[[@as fzfx.PreviewerConfig]])
    previewer_configs_map[DEFAULT_PIPELINE] = previewer_configs
  else
    for previewer_name, previewer_opts in pairs(previewer_configs) do
      log.ensure(
        schema.is_previewer_config(previewer_opts --[[@as fzfx.PreviewerConfig]]),
        string.format(
          "%s (%s) is not a valid previewer! %s",
          vim.inspect(previewer_name),
          vim.inspect(name),
          vim.inspect(previewer_opts)
        )
      )
      previewer_opts.previewer_type =
        schema.get_previewer_type_or_default(previewer_opts --[[@as fzfx.PreviewerConfig]])
      previewer_configs_map[previewer_name] = previewer_opts
    end
  end

  local o = {
    pipeline = pipeline,
    previewer_configs = previewer_configs_map,
    previewer_labels_queue = {},
    metafile = _previewer_metafile(),
    resultfile = _previewer_resultfile(),
    fzf_port_reader = fileio.CachedFileReader:open(fzf_port_file),
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
    string.format(
      "invalid previewer config in %s! previewer config: %s",
      vim.inspect(self.pipeline),
      vim.inspect(previewer_config)
    )
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
    string.format(
      "invalid previewer config in %s! previewer config: %s",
      vim.inspect(self.pipeline),
      vim.inspect(previewer_config)
    )
  )
  log.ensure(
    type(previewer_config.previewer) == "function",
    string.format(
      "invalid previewer in %s! previewer: %s",
      vim.inspect(self.pipeline),
      vim.inspect(previewer_config)
    )
  )
  log.ensure(
    previewer_config.previewer_type == PreviewerTypeEnum.COMMAND
      or previewer_config.previewer_type == PreviewerTypeEnum.COMMAND_LIST
      or previewer_config.previewer_type == PreviewerTypeEnum.LIST,
    string.format(
      "invalid previewer type in %s! previewer type: %s",
      vim.inspect(self.pipeline),
      vim.inspect(previewer_config)
    )
  )

  local metaopts = make_previewer_meta_opts(self.pipeline, previewer_config)
  local metajson = json.encode(metaopts) --[[@as string]]
  fileio.writefile(self.metafile, metajson)

  if previewer_config.previewer_type == PreviewerTypeEnum.COMMAND then
    local ok, result = pcall(previewer_config.previewer, line, context)
    -- log.debug(
    --     "|fzfx.general - PreviewerSwitch:preview| pcall command previewer, ok:%s, result:%s",
    --     vim.inspect(ok),
    --     vim.inspect(result)
    -- )
    if not ok then
      fileio.writefile(self.resultfile, "")
      log.err(
        string.format(
          "failed to call pipeline %s command previewer %s! line:%s, context:%s, error:%s",
          vim.inspect(self.pipeline),
          vim.inspect(previewer_config.previewer),
          vim.inspect(line),
          vim.inspect(context),
          vim.inspect(result)
        )
      )
    else
      log.ensure(
        result == nil or type(result) == "string",
        string.format(
          "|PreviewerSwitch:preview| command previewer result must be string! self:%s, result:%s",
          vim.inspect(self),
          vim.inspect(result)
        )
      )
      if result == nil then
        fileio.writefile(self.resultfile, "")
      else
        fileio.writefile(self.resultfile, result --[[@as string]])
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
      fileio.writefile(self.resultfile, "")
      log.err(
        string.format(
          "failed to call pipeline %s command_list previewer %s! line:%s, context:%s, error:%s",
          vim.inspect(self.pipeline),
          vim.inspect(previewer_config.previewer),
          vim.inspect(line),
          vim.inspect(context),
          vim.inspect(result)
        )
      )
    else
      log.ensure(
        result == nil or type(result) == "table",
        string.format(
          "|PreviewerSwitch:preview| command_list previewer result must be string! self:%s, result:%s",
          vim.inspect(self),
          vim.inspect(result)
        )
      )
      if tbl.tbl_empty(result) then
        fileio.writefile(self.resultfile, "")
      else
        fileio.writefile(self.resultfile, json.encode(result --[[@as table]]) --[[@as string]])
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
      fileio.writefile(self.resultfile, "")
      log.err(
        string.format(
          "failed to call pipeline %s list previewer %s! line:%s, context:%s, error:%s",
          vim.inspect(self.pipeline),
          vim.inspect(previewer_config.previewer),
          vim.inspect(line),
          vim.inspect(context),
          vim.inspect(result)
        )
      )
    else
      log.ensure(
        type(result) == "table",
        string.format(
          "|PreviewerSwitch:preview| list previewer result must be array! self:%s, result:%s",
          vim.inspect(self),
          vim.inspect(result)
        )
      )
      fileio.writelines(self.resultfile, result --[[@as table]])
    end
  else
    log.throw(
      string.format("|PreviewerSwitch:preview| invalid previewer type! %s", vim.inspect(self))
    )
  end

  self:_preview_label(line, context)

  return previewer_config.previewer_type
end

--- @param port string
--- @param body string
local function _send_http_post(port, body)
  spawn.system({
    "curl",
    "-s",
    "-S",
    "-q",
    "-Z",
    "--parallel-immediate",
    "--noproxy",
    "*",
    "-XPOST",
    string.format("127.0.0.1:%s", vim.trim(port)),
    "-d",
    body,
  }, { text = true }, function(completed) end)
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
    string.format(
      "invalid previewer config in %s! previewer config: %s",
      vim.inspect(self.pipeline),
      vim.inspect(previewer_config)
    )
  )
  log.ensure(
    type(previewer_config.previewer_label) == "function"
      or previewer_config.previewer_label == nil
      or type(previewer_config.previewer_label) == "boolean"
      or type(previewer_config.previewer_label) == "string",
    string.format(
      "invalid previewer label in %s! previewer: %s",
      vim.inspect(self.pipeline),
      vim.inspect(previewer_config)
    )
  )

  if not constants.HAS_CURL then
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
    -- log.debug(
    --   "|PreviewerSwitch:preview_label| line:%s, label:%s",
    --   vim.inspect(line),
    --   vim.inspect(label)
    -- )
    if type(label) ~= "string" then
      return
    end
    table.insert(self.previewer_labels_queue, label)

    -- do later
    vim.defer_fn(function()
      if #self.previewer_labels_queue == 0 then
        return
      end
      local last_label = self.previewer_labels_queue[#self.previewer_labels_queue]
      self.previewer_labels_queue = {}
      if type(last_label) ~= "string" then
        return
      end
      local fzf_port = self.fzf_port_reader:read({ trim = true }) --[[@as string]]
      if str.not_empty(fzf_port) then
        _send_http_post(fzf_port, string.format("change-preview-label(%s)", vim.trim(last_label)))
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
  return term_color.magenta(string.upper(action), "Special")
    .. " to "
    .. table.concat(str.split(name, "_"), " ")
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
      local help_builder = _make_help_doc(provider_configs, {}, { provider_name })
      headers_map[provider_name] = _make_help_doc(interaction_configs, help_builder)
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
    string.format(
      "|HeaderSwitch:get_header| pipeline (%s) must exists in headers! %s",
      vim.inspect(pipeline),
      vim.inspect(self)
    )
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

--- @param action_name string
--- @param action_file string
--- @return string
local function dump_action_command(action_name, action_file)
  if constants.IS_WINDOWS then
    return string.format("execute-silent(cmd.exe /C echo %s>%s)", action_name, action_file)
  else
    return string.format("execute-silent(echo %s>%s)", action_name, action_file)
  end
end

--- @param fzf_opts fzfx.FzfOpt[]
--- @param fzf_action_file string
--- @return fzfx.FzfOpt[], fzfx.BufferFilePreviewerOpts
local function mock_buffer_previewer_fzf_opts(fzf_opts, fzf_action_file)
  local new_fzf_opts = {}
  local border_opts = fzf_helpers.FZF_DEFAULT_BORDER_OPTS
  local pw_opts = {}
  for _, o in ipairs(fzf_opts) do
    local mocked = false

    if type(o) == "table" and str.not_empty(o[1]) and str.startswith(o[1], "--preview-window") then
      table.insert(pw_opts, o)
      mocked = true
    elseif
      str.not_empty(o) and str.startswith(o --[[@as string]], "--preview-window")
    then
      table.insert(pw_opts, o)
      mocked = true
    end

    if type(o) == "table" and str.not_empty(o[1]) and str.startswith(o[1], "--border") then
      border_opts = o[2]
      mocked = true
    elseif
      str.not_empty(o) and str.startswith(o --[[@as string]], "--border")
    then
      border_opts = string.sub(o --[[@as string]], string.len("--border") + 2)
      mocked = true
    end

    -- preview actions
    local split_o = nil
    for action_name, _ in pairs(fzf_helpers.FZF_PREVIEW_ACTIONS) do
      if type(o) == "table" and str.not_empty(o[2]) then
        if str.find(o[2], action_name) then
          split_o = o
        end
      elseif str.not_empty(o) then
        if
          str.find(o --[[@as string]], action_name)
        then
          local split_pos = str.find(o --[[@as string]], "=")
          if not split_pos then
            split_pos = str.find(o --[[@as string]], " ")
          end
          if type(split_pos) == "number" and split_pos > 1 then
            split_o = {}
            local o1 = str.trim(string.sub(o --[[@as string]], 1, split_pos - 1))
            -- log.debug(
            --   "|general - use_buffer_previewer| o:%s, split_pos:%s, o1:%s",
            --   vim.inspect(o),
            --   vim.inspect(split_pos),
            --   vim.inspect(o1)
            -- )
            local o2 = str.trim(string.sub(o --[[@as string]], split_pos + 1))
            -- log.debug(
            --   "|general - use_buffer_previewer| o:%s, split_pos:%s, o2:%s",
            --   vim.inspect(o),
            --   vim.inspect(split_pos),
            --   vim.inspect(o2)
            -- )
            table.insert(split_o, o1)
            table.insert(split_o, o2)
          end
        end
      end

      if type(split_o) == "table" and #split_o == 2 then
        if str.find(split_o[2], action_name) then
          local new_o2 =
            str.replace(split_o[2], action_name, dump_action_command(action_name, fzf_action_file))
          table.insert(new_fzf_opts, { split_o[1], new_o2 })
          mocked = true
        end
      end

      split_o = nil
    end

    if not mocked then
      table.insert(new_fzf_opts, o)
    end
  end

  local preview_window_opts =
    fzf_helpers.parse_fzf_preview_window_opts(#pw_opts > 0 and pw_opts or {
      {
        "--preview-window",
        "right,50%",
      },
    })

  return new_fzf_opts,
    {
      fzf_border_opts = border_opts,
      fzf_preview_window_opts = preview_window_opts,
    }
end

--- @param fzf_opts fzfx.FzfOpt[]
--- @return fzfx.FzfOpt[], string
local function mock_non_buffer_previewer_fzf_border_opts(fzf_opts)
  local new_fzf_opts = {}
  local border_opts = fzf_helpers.FZF_DEFAULT_BORDER_OPTS
  for _, o in ipairs(fzf_opts) do
    local mocked = false
    if type(o) == "table" and str.not_empty(o[1]) and str.startswith(o[1], "--border") then
      border_opts = o[2]
      mocked = true
    elseif
      str.not_empty(o) and str.startswith(o --[[@as string]], "--border")
    then
      border_opts = string.sub(o --[[@as string]], string.len("--border") + 2)
      mocked = true
    end
    if not mocked then
      table.insert(new_fzf_opts, o)
    end
  end

  return new_fzf_opts, border_opts
end

--- @param name string
--- @param query string
--- @param bang boolean
--- @param pipeline_configs fzfx.Options
--- @param default_pipeline fzfx.PipelineName?
local function general(name, query, bang, pipeline_configs, default_pipeline)
  local pipeline_size = get_pipeline_size(pipeline_configs)

  --- cache files
  local fzf_port_file = _fzf_port_file()
  local buffer_previewer_actions_file = _buffer_previewer_actions_file()
  local buffer_previewer_actions_fsevent, buffer_previewer_actions_fsevent_err
  local buffer_previewer_query_fzf_status_start = false

  --- @type fzfx.Popup
  local popup = nil

  local default_provider_action_key = nil
  if default_pipeline == nil or pipeline_configs.providers[default_pipeline] == nil then
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
  local provider_switch = ProviderSwitch:new(name, default_pipeline, pipeline_configs.providers)

  --- @type fzfx.PreviewerSwitch
  local previewer_switch =
    PreviewerSwitch:new(name, default_pipeline, pipeline_configs.previewers, fzf_port_file)
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

  local provide_rpc_id = rpcserver.get_instance():register(provide_rpc, "provide_rpc")
  table.insert(rpc_registries, provide_rpc_id)

  local query_command = string.format(
    "%s %s %s %s %s",
    fzf_helpers.make_lua_command("provider.lua"),
    provide_rpc_id,
    provider_switch.metafile,
    provider_switch.resultfile,
    shells.shellescape(query)
  )
  -- log.debug("|general| query_command:%s", vim.inspect(query_command))
  local reload_query_command = string.format(
    "%s %s %s %s {q}",
    fzf_helpers.make_lua_command("provider.lua"),
    provide_rpc_id,
    provider_switch.metafile,
    provider_switch.resultfile
  )
  -- log.debug(
  --   "|general| reload_query_command:%s",
  --   vim.inspect(reload_query_command)
  -- )

  local fzf_opts = vim.deepcopy(config.get().fzf_opts)
  fzf_opts = vim.list_extend(fzf_opts, { "--print-query", "--listen", { "--query", query } })

  --- @param line_params string
  local function preview_rpc(line_params)
    previewer_switch:preview(line_params, context)
  end

  if not use_buffer_previewer then
    local preview_rpc_id = rpcserver.get_instance():register(preview_rpc, "preview_rpc")
    table.insert(rpc_registries, preview_rpc_id)
    local preview_command = string.format(
      "%s %s %s %s {}",
      fzf_helpers.make_lua_command("previewer.lua"),
      preview_rpc_id,
      previewer_switch.metafile,
      previewer_switch.resultfile
    )
    -- log.debug("|general| preview_command:%s", vim.inspect(preview_command))
    table.insert(fzf_opts, {
      "--preview",
      preview_command,
    })
  end

  local dump_fzf_port_command = nil
  if constants.IS_WINDOWS then
    dump_fzf_port_command = string.format("cmd.exe /C echo %%FZF_PORT%%>%s", fzf_port_file)
  else
    dump_fzf_port_command = string.format("echo $FZF_PORT>%s", fzf_port_file)
  end
  local fzf_start_binder = fzf_helpers.FzfOptEventBinder:new("start")
  fzf_start_binder:append(string.format("execute-silent(%s)", dump_fzf_port_command))

  if use_buffer_previewer then
    -- listen fzf actions {
    fileio.writefile(buffer_previewer_actions_file, "")
    buffer_previewer_actions_fsevent, buffer_previewer_actions_fsevent_err = uv.new_fs_event()
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
      buffer_previewer_actions_file,
      {},
      function(actions_fsevent_start_complete_err, actions_file, events)
        -- log.debug(
        --   string.format(
        --     "|general - buffer_previewer_actions_fsevent:start| complete actions fsevent, actions_file:%s, events:%s, buffer_previewer_actions_file:%s, actions_fsevent_start_complete_err:%s",
        --     vim.inspect(actions_file),
        --     vim.inspect(events),
        --     vim.inspect(buffer_previewer_actions_file),
        --     vim.inspect(actions_fsevent_start_complete_err)
        --   )
        -- )
        if actions_fsevent_start_complete_err then
          log.err(
            string.format(
              "|general - buffer_previewer_actions_fsevent:start| failed to trigger fsevent on actions_file %s, error:%s",
              vim.inspect(buffer_previewer_actions_file),
              vim.inspect(actions_fsevent_start_complete_err)
            )
          )
          return
        end
        if not str.find(buffer_previewer_actions_file, actions_file) then
          return
        end
        if not popup or not popup:provider_is_valid() then
          return
        end

        fileio.asyncreadfile(buffer_previewer_actions_file, function(actions_data)
          -- log.debug(
          --   string.format(
          --     "|general - buffer_previewer_actions_fsevent:start| complete read actions_file:%s, actions_data:%s",
          --     vim.inspect(actions_file),
          --     vim.inspect(actions_data)
          --   )
          -- )
          if not popup or not popup:provider_is_valid() then
            return
          end
          if constants.IS_WINDOWS then
            if str.startswith(actions_data, '"') then
              actions_data = string.sub(actions_data, 2)
            end
            if str.endswith(actions_data, '"') then
              actions_data = string.sub(actions_data, 1, #actions_data - 1)
            end
          end

          vim.schedule(function()
            if not popup or not popup:provider_is_valid() then
              return
            end
            popup.popup_window:preview_action(actions_data)
          end)
        end, { trim = true })
      end
    )
    log.ensure(
      actions_fsevent_start_result ~= nil,
      string.format(
        "failed to start watching fsevent on %s, error: %s",
        vim.inspect(buffer_previewer_actions_file),
        vim.inspect(actions_fsevent_start_err)
      )
    )
    -- listen fzf actions }

    -- query fzf status {
    local fzf_port_reader = fileio.CachedFileReader:open(fzf_port_file)
    local QUERY_FZF_CURRENT_STATUS_INTERVAL = 150
    buffer_previewer_query_fzf_status_start = true

    local buffer_previewer_focused_line = nil
    local buffer_previewer_file_job_id = num.auto_incremental_id()
    if popup and popup.popup_window then
      popup.popup_window:set_current_previewing_file_job_id(buffer_previewer_file_job_id)
    end

    local function query_fzf_status()
      if not buffer_previewer_query_fzf_status_start then
        return
      end

      -- local fzf_status_data = {}
      spawn.system({
        "curl",
        "-s",
        "-S",
        "-q",
        "-Z",
        "--parallel-immediate",
        "--noproxy",
        "*",
        string.format("127.0.0.1:%s?limit=0", fzf_port_reader:read({ trim = true })),
      }, {
        text = true,
      }, function(completed)
        -- log.debug(
        --   string.format(
        --     "|general - use_buffer_previewer - query_fzf_status| completed:%s",
        --     vim.inspect(completed)
        --   )
        -- )

        if buffer_previewer_query_fzf_status_start then
          vim.defer_fn(query_fzf_status, QUERY_FZF_CURRENT_STATUS_INTERVAL)
        end

        vim.schedule(function()
          if str.not_empty(tbl.tbl_get(completed, "stdout")) then
            local parse_ok, parse_status = pcall(json.decode, completed.stdout) --[[@as boolean, table]]
            if parse_ok and str.not_empty(tbl.tbl_get(parse_status, "current", "text")) then
              local focused_line = parse_status["current"]["text"]

              if focused_line == buffer_previewer_focused_line then
                return
              end

              buffer_previewer_focused_line = focused_line

              if not popup or not popup:provider_is_valid() then
                return
              end

              -- trigger buffer previewer {

              buffer_previewer_file_job_id = num.auto_incremental_id()
              popup.popup_window:set_current_previewing_file_job_id(buffer_previewer_file_job_id)

              local previewer_config = previewer_switch:current()

              local previewer_ok, previewer_result =
                pcall(previewer_config.previewer, focused_line, context)
              log.debug(
                string.format(
                  "|fzfx.general - use_buffer_previewer - asyncreadfile| pcall command previewer, previewer_ok:%s, previewer_result:%s",
                  vim.inspect(previewer_ok),
                  vim.inspect(previewer_result)
                )
              )
              if not previewer_ok then
                log.err(
                  string.format(
                    "failed to call buffer previewer %s! line:%s, context:%s, error:%s",
                    vim.inspect(previewer_config.previewer),
                    vim.inspect(focused_line),
                    vim.inspect(context),
                    vim.inspect(previewer_result)
                  )
                )
              else
                log.ensure(
                  previewer_result == nil or type(previewer_result) == "table",
                  string.format(
                    "|general - use_buffer_previewer - query_fzf_status| buffer previewer result must be table! previewer_config:%s, result:%s",
                    vim.inspect(previewer_config),
                    vim.inspect(previewer_result)
                  )
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
                      string.format(
                        "failed to call previewer label(%s) on buffer previewer! focused_line:%s, context:%s, error:%s",
                        vim.inspect(previewer_config),
                        vim.inspect(focused_line),
                        vim.inspect(context),
                        vim.inspect(previewer_label_result)
                      )
                    )
                    previewer_label_result = nil
                  end
                end
                if previewer_result then
                  popup.popup_window:preview_file(
                    buffer_previewer_file_job_id,
                    previewer_result --[[@as fzfx.BufferFilePreviewerResult]],
                    previewer_label_result --[[@as string?]]
                  )
                end
              end
              -- trigger buffer previewer }
            end
          end
        end)
      end)
    end

    vim.defer_fn(query_fzf_status, QUERY_FZF_CURRENT_STATUS_INTERVAL - 50)

    -- query fzf status }
  end

  local header_switch = HeaderSwitch:new(pipeline_configs.providers, pipeline_configs.interactions)

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
        -- log.debug("|general.interaction_rpc| line_params:%s", vim.inspect(line_params))
        action(line_params, context)
      end

      local interaction_rpc_id =
        rpcserver.get_instance():register(interaction_rpc, "interaction_rpc")
      table.insert(rpc_registries, interaction_rpc_id)

      local action_command = string.format(
        "%s %s {}",
        fzf_helpers.make_lua_command("rpcrequest.lua"),
        interaction_rpc_id
      )
      local bind_builder = string.format("%s:execute-silent(%s)", action_key, action_command)
      if interaction_opts.reload_after_execute then
        bind_builder = bind_builder .. string.format("+reload(%s)", reload_query_command)
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

      local switch_rpc_id = rpcserver.get_instance():register(switch_rpc, "switch_rpc")
      table.insert(rpc_registries, switch_rpc_id)

      local switch_command =
        string.format("%s %s", fzf_helpers.make_lua_command("rpcrequest.lua"), switch_rpc_id)
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
          bind_builder = bind_builder .. string.format("+rebind(%s)", switch_key2)
        end
      end
      table.insert(fzf_opts, {
        "--bind",
        bind_builder,
      })
    end
    fzf_start_binder:append(string.format("unbind(%s)", default_provider_action_key))
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

  -- fzf_opts
  fzf_opts = vim.list_extend(fzf_opts, vim.deepcopy(pipeline_configs.fzf_opts))
  fzf_opts = vim.list_extend(fzf_opts, vim.deepcopy(config.get().override_fzf_opts or {}))
  fzf_opts = fzf_helpers.preprocess_fzf_opts(fzf_opts)

  -- actions
  local actions = pipeline_configs.actions

  -- win_opts
  local config_win_opts = tbl.tbl_get(config.get(), "popup", "win_opts")
  local win_opts = nil
  if type(config_win_opts) == "function" then
    win_opts = vim.deepcopy(tbl.tbl_get(config.get_defaults(), "popup", "win_opts"))
    win_opts = vim.tbl_deep_extend("force", vim.deepcopy(win_opts or {}), config_win_opts() or {})
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
    win_opts = vim.tbl_deep_extend("force", vim.deepcopy(win_opts or {}), pipeline_win_opts)
  end
  if bang then
    win_opts = vim.tbl_deep_extend(
      "force",
      vim.deepcopy(win_opts or {}),
      { height = 1, width = 1, row = 0, col = 0 }
    )
  end

  local previewer_opts = {}
  local non_buffer_previewer_border_opts = nil
  if use_buffer_previewer then
    fzf_opts, previewer_opts =
      mock_buffer_previewer_fzf_opts(fzf_opts, buffer_previewer_actions_file)
  else
    fzf_opts, non_buffer_previewer_border_opts = mock_non_buffer_previewer_fzf_border_opts(fzf_opts)
    previewer_opts.fzf_border_opts = non_buffer_previewer_border_opts
  end

  popup = Popup:new(win_opts or {}, query_command, fzf_opts, actions, context, function(last_query)
    for _, rpc_id in ipairs(rpc_registries) do
      rpcserver.get_instance():unregister(rpc_id)
    end
    local last_query_cache = fzf_helpers.last_query_cache_name(name)
    fzf_helpers.save_last_query_cache(name, last_query, provider_switch.pipeline)
    local content = json.encode({
      default_provider = provider_switch.pipeline,
      query = last_query,
    }) --[[@as string]]
    fileio.asyncwritefile(last_query_cache, content, function(bytes)
      -- log.debug("|general| dump last query:%s", vim.inspect(bytes))
    end)
    if buffer_previewer_actions_fsevent then
      buffer_previewer_actions_fsevent:stop()
      buffer_previewer_actions_fsevent = nil
    end
    buffer_previewer_query_fzf_status_start = false
  end, use_buffer_previewer, previewer_opts)
end

--- @param name string
--- @param command_config fzfx.CommandConfig
--- @param variant_configs fzfx.VariantConfig[]
--- @param group_config fzfx.GroupConfig
local function _make_user_command(name, command_config, variant_configs, group_config)
  local command_name = command_config.name
  local command_desc = command_config.desc

  vim.api.nvim_create_user_command(command_name, function(opts)
    -- log.debug(
    --   "|_make_user_command| command_name:%s, opts:%s",
    --   vim.inspect(command_name),
    --   vim.inspect(opts)
    -- )
    local input_args = str.trim(opts.args or "")
    if str.empty(input_args) then
      input_args = variant_configs[1].name
    end
    log.ensure(
      str.not_empty(input_args),
      string.format(
        "missing args in command: %s",
        vim.inspect(command_name),
        vim.inspect(input_args)
      )
    )

    --- @type fzfx.VariantConfig
    local varcfg = nil
    local first_space_pos = str.find(input_args, " ")
    local first_arg = first_space_pos ~= nil and string.sub(input_args, 1, first_space_pos - 1)
      or input_args
    for i, variant in ipairs(variant_configs) do
      if first_arg == variant.name then
        varcfg = variant
        break
      end
    end
    log.ensure(
      varcfg ~= nil,
      string.format(
        "unknown command (%s) variant: %s",
        vim.inspect(command_name),
        vim.inspect(input_args)
      )
    )

    local other_args = first_space_pos ~= nil and str.trim(string.sub(input_args, first_space_pos))
      or ""
    local feed_obj = fzf_helpers.get_command_feed(varcfg.feed, other_args, name) or { query = "" }

    local default_provider = feed_obj.default_provider or varcfg.default_provider

    return general(name, feed_obj.query, opts.bang, group_config, default_provider)
  end, {
    nargs = "*",
    range = true,
    bang = true,
    desc = command_desc,
    complete = function(ArgLead, CmdLine, CursorPos)
      local sub_commands = {}
      for i, variant in ipairs(variant_configs) do
        if str.not_empty(variant.name) then
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
    schema.is_variant_config(pipeline_configs.variants) and { pipeline_configs.variants }
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
  dump_action_command = dump_action_command,
  mock_buffer_previewer_fzf_opts = mock_buffer_previewer_fzf_opts,
}

return M
