local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")
local cmds = require("fzfx.lib.commands")
local paths = require("fzfx.lib.paths")
local tbls = require("fzfx.lib.tables")
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

M.INVALID_BUFFER_ERROR = "invalid buffer(%s)."

M.commands = {
  -- normal
  {
    name = "FzfxLiveGrep",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "*",
      desc = "Live grep",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxLiveGrepU",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "*",
      desc = "Live grep unrestricted",
    },
    default_provider = "unrestricted_mode",
  },
  {
    name = "FzfxLiveGrepB",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "*",
      desc = "Live grep on current buffer",
    },
    default_provider = "buffer_mode",
  },
  -- visual
  {
    name = "FzfxLiveGrepV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Live grep by visual select",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxLiveGrepUV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Live grep unrestricted by visual select",
    },
    default_provider = "unrestricted_mode",
  },
  {
    name = "FzfxLiveGrepBV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Live grep on current buffer by visual select",
    },
    default_provider = "buffer_mode",
  },
  -- cword
  {
    name = "FzfxLiveGrepW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Live grep by cursor word",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxLiveGrepUW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Live grep unrestricted by cursor word",
    },
    default_provider = "unrestricted_mode",
  },
  {
    name = "FzfxLiveGrepBW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Live grep on current buffer by cursor word",
    },
    default_provider = "buffer_mode",
  },
  -- put
  {
    name = "FzfxLiveGrepP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Live grep by yank text",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxLiveGrepUP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Live grep unrestricted by yank text",
    },
    default_provider = "unrestricted_mode",
  },
  {
    name = "FzfxLiveGrepBP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Live grep on current buffer by yank text",
    },
    default_provider = "buffer_mode",
  },
  -- resume
  {
    name = "FzfxLiveGrepR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Live grep by resume last",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxLiveGrepUR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Live grep unrestricted by resume last",
    },
    default_provider = "unrestricted_mode",
  },
  {
    name = "FzfxLiveGrepBR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Live grep on current buffer by resume last",
    },
    default_provider = "buffer_mode",
  },
}

--- @param bufnr integer
--- @return string?
M._get_buf_path = function(bufnr)
  local bufpath = nvims.buf_is_valid(bufnr)
      and paths.reduce(vim.api.nvim_buf_get_name(bufnr))
    or nil
  if strs.empty(bufpath) then
    log.echo(LogLevels.INFO, M.INVALID_BUFFER_ERROR, vim.inspect(bufnr))
    return nil
  end
  return bufpath
end

--- @param args_list string[]
--- @param option string?
--- @return string[]
M._append_options = function(args_list, option)
  assert(type(args_list) == "table")
  if strs.not_empty(option) then
    local option_splits = strs.split(option --[[@as string]], " ")
    for _, o in ipairs(option_splits) do
      if strs.not_empty(o) then
        table.insert(args_list, o)
      end
    end
  end

  return args_list
end

--- @param opts {unrestricted:boolean?,buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
M._make_provider_rg = function(opts)
  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local parsed = queries_helper.parse_flagged(query or "")
    local payload = parsed.payload
    local option = parsed.option

    local args = nil
    if tbls.tbl_get(opts, "unrestricted") or tbls.tbl_get(opts, "buffer") then
      args = vim.deepcopy(providers_helper.UNRESTRICTED_RG)
    else
      args = vim.deepcopy(providers_helper.RESTRICTED_RG)
    end
    args = M._append_options(args, option)

    if tbls.tbl_get(opts, "buffer") then
      local bufpath = M._get_buf_path(context.bufnr)
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
    local parsed = queries_helper.parse_flagged(query or "")
    local payload = parsed.payload
    local option = parsed.option

    local args = nil
    if tbls.tbl_get(opts, "unrestricted") or tbls.tbl_get(opts, "buffer") then
      args = vim.deepcopy(providers_helper.UNRESTRICTED_GREP)
    else
      args = vim.deepcopy(providers_helper.RESTRICTED_GREP)
    end
    args = M._append_options(args, option)

    if tbls.tbl_get(opts, "buffer") then
      local bufpath = M._get_buf_path(context.bufnr)
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
  if consts.HAS_RG then
    return M._make_provider_rg(opts)
  elseif consts.HAS_GREP then
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
    provider_decorator = { module = "prepend_icon_grep", builtin = true },
  },
  unrestricted_mode = {
    key = "ctrl-u",
    provider = unrestricted_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
    provider_decorator = { module = "prepend_icon_grep", builtin = true },
  },
  buffer_mode = {
    key = "ctrl-o",
    provider = buffer_provider,
    provider_type = ProviderTypeEnum.COMMAND_LIST,
    provider_decorator = { module = "prepend_icon_grep", builtin = true },
  },
}

M.previewers = {
  restricted_mode = {
    previewer = previewers_helper.preview_files_grep,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = consts.HAS_RG and labels_helper.label_rg
      or labels_helper.label_grep,
  },
  unrestricted_mode = {
    previewer = previewers_helper.preview_files_grep,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = consts.HAS_RG and labels_helper.label_rg
      or labels_helper.label_grep,
  },
  buffer_mode = {
    previewer = previewers_helper.preview_files_grep,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = consts.HAS_RG and labels_helper.label_rg
      or labels_helper.label_grep,
  },
}

local edit = consts.HAS_RG and actions_helper.edit_rg
  or actions_helper.edit_grep
local setqflist = consts.HAS_RG and actions_helper.setqflist_rg
  or actions_helper.setqflist_grep

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = edit,
  ["double-click"] = edit,
  ["ctrl-q"] = setqflist,
}

M.fzf_opts = {
  consts.FZF_OPTS.MULTI,
  consts.FZF_OPTS.DISABLED,
  consts.FZF_OPTS.DELIMITER,
  consts.FZF_OPTS.GREP_PREVIEW_WINDOW,
  { "--prompt", "Live Grep > " },
}

M.other_opts = {
  reload_on_change = true,
}

return M
