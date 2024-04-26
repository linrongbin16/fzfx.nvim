local str = require("fzfx.commons.str")
local api = require("fzfx.commons.api")
local path = require("fzfx.commons.path")

local bufs = require("fzfx.lib.bufs")
local switches = require("fzfx.lib.switches")

local parsers_helper = require("fzfx.helper.parsers")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.command = {
  name = "FzfxBuffers",
  desc = "Find buffers",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
  },
}

--- @param bufnr integer
--- @return boolean
M._buf_valid = function(bufnr)
  local exclude_filetypes = {
    ["qf"] = true,
    ["neo-tree"] = true,
  }
  local ok, ft_or_err = pcall(api.get_buf_option, bufnr, "filetype")
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
      and path.reduce(vim.api.nvim_buf_get_name(context.bufnr))
    or nil
  if str.not_empty(current_path) then
    table.insert(bufpaths, current_path)
  end

  for _, bufnr in ipairs(bufnrs) do
    local bufpath = path.reduce(vim.api.nvim_buf_get_name(bufnr))
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

-- if you want to use fzf-builtin previewer with bat, please use below configs:
--
-- previewer = previewers_helper.preview_files_find
-- previewer_type = PreviewerTypeEnum.COMMAND_LIST

-- if you want to use nvim buffer previewer, please use below configs:
--
-- previewer = previewers_helper.buffer_preview_files_find
-- previewer_type = PreviewerTypeEnum.BUFFER_FILE

local previewer = switches.buffer_previewer_disabled() and previewers_helper.preview_files_find
  or previewers_helper.buffer_preview_files_find
local previewer_type = switches.buffer_previewer_disabled() and PreviewerTypeEnum.COMMAND_LIST
  or PreviewerTypeEnum.BUFFER_FILE

M.previewers = {
  previewer = previewer,
  previewer_type = previewer_type,
  previewer_label = labels_helper.label_find,
}

--- @param line string
M._delete_buffer = function(line)
  local bufnrs = vim.api.nvim_list_bufs()
  local filenames = {}
  for _, bufnr in ipairs(bufnrs) do
    local bufpath = path.reduce(vim.api.nvim_buf_get_name(bufnr))
    bufpath = path.normalize(bufpath, { double_backslash = true, expand = true })
    filenames[bufpath] = bufnr
  end
  if str.not_empty(line) then
    local parsed = parsers_helper.parse_find(line)
    local bufnr = filenames[parsed.filename]
    -- log.debug(
    --   "|_delete_buffer| parsed:%s, filenames:%s",
    --   vim.inspect(parsed.filename),
    --   vim.inspect(filenames)
    -- )
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
  "--multi",
  { "--prompt", "Buffers > " },
  function()
    local current_bufnr = vim.api.nvim_get_current_buf()
    return bufs.buf_is_valid(current_bufnr) and "--header-lines=1" or nil
  end,
  "--preview-window=hidden",
}

return M
