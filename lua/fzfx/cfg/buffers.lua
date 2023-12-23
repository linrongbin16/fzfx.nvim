local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")
local apis = require("fzfx.commons.apis")
local bufs = require("fzfx.lib.bufs")
local cmds = require("fzfx.lib.commands")
local paths = require("fzfx.commons.paths")
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

M.commands = {
  -- normal
  {
    name = "FzfxBuffers",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "file",
      desc = "Find buffers",
    },
  },
  -- visual
  {
    name = "FzfxBuffersV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find buffers by visual select",
    },
  },
  -- cword
  {
    name = "FzfxBuffersW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find buffers by cursor word",
    },
  },
  -- put
  {
    name = "FzfxBuffersP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find buffers by yank text",
    },
  },
  -- resume
  {
    name = "FzfxBuffersR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find buffers by resume last",
    },
  },
}

--- @param bufnr integer
--- @return boolean
M._buf_valid = function(bufnr)
  local exclude_filetypes = {
    ["qf"] = true,
    ["neo-tree"] = true,
  }
  local ok, ft_or_err = pcall(apis.get_buf_option, bufnr, "filetype")
  if not ok then
    return false
  end
  return bufs.buf_is_valid(bufnr) and not exclude_filetypes[ft_or_err]
end

--- @param query string
--- @param context fzfx.PipelineContext
--- @return string[]|nil
M._buffers_provider = function(query, context)
  local bufnrs = vim.api.nvim_list_bufs()
  local bufpaths = {}

  local current_path = M._buf_valid(context.bufnr)
      and paths.reduce(vim.api.nvim_buf_get_name(context.bufnr))
    or nil
  if strs.not_empty(current_path) then
    table.insert(bufpaths, current_path)
  end

  for _, bufnr in ipairs(bufnrs) do
    local bufpath = paths.reduce(vim.api.nvim_buf_get_name(bufnr))
    if M._buf_valid(bufnr) and bufpath ~= current_path then
      table.insert(bufpaths, bufpath)
    end
  end
  return bufpaths
end

M.providers = {
  key = "default",
  provider = M._buffers_provider,
  provider_type = ProviderTypeEnum.LIST,
  provider_decorator = { module = "prepend_icon_find", builtin = true },
}

M.previewers = {
  previewer = previewers_helper.preview_files_find,
  previewer_type = PreviewerTypeEnum.COMMAND_LIST,
  previewer_label = labels_helper.label_find,
}

--- @param line string
M._delete_buffer = function(line)
  local bufnrs = vim.api.nvim_list_bufs()
  local filenames = {}
  for _, bufnr in ipairs(bufnrs) do
    local bufpath = paths.reduce(vim.api.nvim_buf_get_name(bufnr))
    filenames[bufpath] = bufnr
  end
  if strs.not_empty(line) then
    local parsed = parsers_helper.parse_find(line)
    local bufnr = filenames[parsed.filename]
    if type(bufnr) == "number" and bufs.buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, {})
    end
  end
end

M.interactions = {
  delete_buffer = {
    key = "ctrl-d",
    interaction = M._delete_buffer,
    reload_after_execute = true,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_find,
  ["double-click"] = actions_helper.edit_find,
  ["ctrl-q"] = actions_helper.setqflist_find,
}

M.fzf_opts = {
  consts.FZF_OPTS.MULTI,
  { "--prompt", "Buffers > " },
  function()
    local current_bufnr = vim.api.nvim_get_current_buf()
    return bufs.buf_is_valid(current_bufnr) and "--header-lines=1" or nil
  end,
}

return M
