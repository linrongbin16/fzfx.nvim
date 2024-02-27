local tables = require("fzfx.commons.tables")
local strings = require("fzfx.commons.strings")
local paths = require("fzfx.commons.paths")

local constants = require("fzfx.lib.constants")
local bufs = require("fzfx.lib.bufs")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local queries_helper = require("fzfx.helper.queries")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local providers_helper = require("fzfx.helper.providers")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.command = {
  name = "FzfxBufLiveGrep",
  desc = "Live grep on current buffer",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "restricted_mode",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "restricted_mode",
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "restricted_mode",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "restricted_mode",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "restricted_mode",
  },
}

--- @param bufnr integer
--- @return string?
M._get_buf_path = function(bufnr)
  local bufpath = bufs.buf_is_valid(bufnr) and paths.reduce(vim.api.nvim_buf_get_name(bufnr)) or nil
  if strings.empty(bufpath) then
    log.echo(LogLevels.INFO, "invalid buffer(%s).", vim.inspect(bufnr))
    return nil
  end
  return bufpath
end

--- @param args_list string[]
--- @param option string?
--- @return string[]
M._append_options = function(args_list, option)
  assert(type(args_list) == "table")
  if strings.not_empty(option) then
    local option_splits = strings.split(option --[[@as string]], " ")
    for _, o in ipairs(option_splits) do
      if strings.not_empty(o) then
        table.insert(args_list, o)
      end
    end
  end

  return args_list
end

--- @param query string
--- @param context fzfx.PipelineContext
--- @return string[]|nil
M._provider_rg = function(query, context)
  local parsed = queries_helper.parse_flagged(query or "")
  local payload = parsed.payload
  local option = parsed.option

  local bufpath = M._get_buf_path(context.bufnr)
  if not bufpath then
    return nil
  end

  local args = vim.deepcopy(providers_helper.UNRESTRICTED_RG)
  args = M._append_options(args, option)

  table.insert(args, "-I")
  table.insert(args, payload)
  table.insert(args, bufpath)
  return args
end

--- @param query string
--- @param context fzfx.PipelineContext
--- @return string[]|nil
M._provider_grep = function(query, context)
  local parsed = queries_helper.parse_flagged(query or "")
  local payload = parsed.payload
  local option = parsed.option

  local bufpath = M._get_buf_path(context.bufnr)
  if not bufpath then
    return nil
  end

  local args = vim.deepcopy(providers_helper.UNRESTRICTED_GREP)
  args = M._append_options(args, option)

  table.insert(args, "-h")
  table.insert(args, payload)
  table.insert(args, bufpath)
  return args
end

--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
M._make_provider = function()
  if constants.HAS_RG then
    return M._provider_rg
  elseif constants.HAS_GREP then
    return M._provider_grep
  else
    --- @return nil
    local function impl()
      log.echo(LogLevels.INFO, "no rg/grep command found.")
      return nil
    end
    return impl
  end
end

M.providers = {
  key = "default",
  provider = M._make_provider(),
  provider_type = ProviderTypeEnum.COMMAND_LIST,
}

--- @param line string
--- @param context fzfx.PipelineContext
--- @return string?
M._make_previewer_label = function(line, context) end

M.previewers = {
  previewer = previewers_helper.preview_files_grep,
  previewer_type = PreviewerTypeEnum.COMMAND_LIST,
  previewer_label = constants.HAS_RG and labels_helper.label_rg or labels_helper.label_grep,
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
