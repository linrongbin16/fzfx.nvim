local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")

local constants = require("fzfx.lib.constants")
local switches = require("fzfx.lib.switches")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local _grep = require("fzfx.cfg._grep")
local _decorator = require("fzfx.cfg._decorator")

local M = {}

M.command = {
  name = "FzfxLiveGrep",
  desc = "Live grep",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "restricted_mode",
  },
  {
    name = "unres_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "unrestricted_mode",
  },
  {
    name = "buf_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "buffer_mode",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "restricted_mode",
  },
  {
    name = "unres_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "unrestricted_mode",
  },
  {
    name = "buf_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "buffer_mode",
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "restricted_mode",
  },
  {
    name = "unres_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "unrestricted_mode",
  },
  {
    name = "buf_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "buffer_mode",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "restricted_mode",
  },
  {
    name = "unres_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "unrestricted_mode",
  },
  {
    name = "buf_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "buffer_mode",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "restricted_mode",
  },
  {
    name = "unres_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "unrestricted_mode",
  },
  {
    name = "buf_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "buffer_mode",
  },
}

--- @param opts {unrestricted:boolean?,buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
M._make_provider_rg = function(opts)
  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local parsed = _grep.parse_query(query or "")
    local payload = parsed.payload
    local option = parsed.option

    local args = nil
    if tbl.tbl_get(opts, "unrestricted") or tbl.tbl_get(opts, "buffer") then
      args = vim.deepcopy(_grep.UNRESTRICTED_RG)
    else
      args = vim.deepcopy(_grep.RESTRICTED_RG)
    end
    args = _grep.append_options(args, option)

    if tbl.tbl_get(opts, "buffer") then
      local bufpath = _grep.buf_path(context.bufnr)
      if not bufpath then
        return nil
      end
      table.insert(args, payload)
      table.insert(args, bufpath)
    else
      table.insert(args, payload)
    end
    return args
  end
  return impl
end

--- @param opts {unrestricted:boolean?,buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
M._make_provider_grep = function(opts)
  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local parsed = _grep.parse_query(query or "")
    local payload = parsed.payload
    local option = parsed.option

    local args = nil
    if tbl.tbl_get(opts, "unrestricted") or tbl.tbl_get(opts, "buffer") then
      args = vim.deepcopy(_grep.UNRESTRICTED_GREP)
    else
      args = vim.deepcopy(_grep.RESTRICTED_GREP)
    end
    args = _grep.append_options(args, option)

    if tbl.tbl_get(opts, "buffer") then
      local bufpath = _grep.buf_path(context.bufnr)
      if not bufpath then
        return nil
      end
      table.insert(args, payload)
      table.insert(args, bufpath)
    else
      table.insert(args, payload)
    end
    return args
  end
  return impl
end

--- @param opts {unrestricted:boolean?,buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
M._make_provider = function(opts)
  if constants.HAS_RG then
    return M._make_provider_rg(opts)
  elseif constants.HAS_GREP then
    return M._make_provider_grep(opts)
  else
    --- @return nil
    local function impl()
      log.echo(LogLevels.INFO, "no rg/grep command found.")
      return nil
    end
    return impl
  end
end

local restricted_provider = M._make_provider()
local unrestricted_provider = M._make_provider({ unrestricted = true })
local buffer_provider = M._make_provider({ buffer = true })

M.providers = {
  restricted_mode = {
    key = "ctrl-r",
    provider = restricted_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
    provider_decorator = { module = _decorator.PREPEND_ICON_GREP },
  },
  unrestricted_mode = {
    key = "ctrl-u",
    provider = unrestricted_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
    provider_decorator = { module = _decorator.PREPEND_ICON_GREP },
  },
  buffer_mode = {
    key = "ctrl-o",
    provider = buffer_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
    provider_decorator = { module = _decorator.PREPEND_ICON_GREP },
  },
}

local previewer
local previewer_type
if switches.buffer_previewer_disabled() then
  previewer = previewers_helper.fzf_preview_find
  previewer_type = PreviewerTypeEnum.COMMAND_LIST
else
  previewer = previewers_helper.buffer_preview_find
  previewer_type = PreviewerTypeEnum.BUFFER_FILE
end

M.previewers = {
  restricted_mode = {
    previewer = previewer,
    previewer_type = previewer_type,
    previewer_label = constants.HAS_RG and labels_helper.label_rg or labels_helper.label_grep,
  },
  unrestricted_mode = {
    previewer = previewer,
    previewer_type = previewer_type,
    previewer_label = constants.HAS_RG and labels_helper.label_rg or labels_helper.label_grep,
  },
  buffer_mode = {
    previewer = previewer,
    previewer_type = previewer_type,
    previewer_label = constants.HAS_RG and labels_helper.label_rg or labels_helper.label_grep,
  },
}

local edit = constants.HAS_RG and actions_helper.edit_rg or actions_helper.edit_grep
local setqflist = constants.HAS_RG and actions_helper.setqflist_rg or actions_helper.setqflist_grep

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = edit,
  ["double-click"] = edit,
  ["ctrl-q"] = setqflist,
}

M.fzf_opts = {
  "--multi",
  "--disabled",
  { "--delimiter", ":" },
  { "--preview-window", "+{2}-/2" },
  { "--prompt", "Live Grep > " },
}

M.other_opts = {
  reload_on_change = true,
}

return M
