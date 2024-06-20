local str = require("fzfx.commons.str")
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

local _decorator = require("fzfx.cfg._decorator")

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

--- @param query string
--- @param context fzfx.PipelineContext
--- @return string[]|nil
M._provider = function(query, context)
  local bufnrs = vim.api.nvim_list_bufs()
  local results = {}

  local current_path = bufs.buf_is_valid(context.bufnr)
      and path.reduce(vim.api.nvim_buf_get_name(context.bufnr))
    or nil
  if str.not_empty(current_path) then
    table.insert(results, current_path)
  end

  for _, bufnr in ipairs(bufnrs) do
    local bufpath = path.reduce(vim.api.nvim_buf_get_name(bufnr))
    if bufs.buf_is_valid(bufnr) and bufpath ~= current_path then
      table.insert(results, bufpath)
    end
  end
  return results
end

M.providers = {
  key = "default",
  provider = M._provider,
  provider_type = ProviderTypeEnum.LIST,
  provider_decorator = { module = _decorator.PREPEND_ICON_FIND },
}

-- If you want to use fzf-builtin previewer with bat, please use below configs:
--
-- ```
-- previewer = previewers_helper.preview_files_find
-- previewer_type = PreviewerTypeEnum.COMMAND_LIST
-- ```
--
-- If you want to use nvim buffer previewer, please use below configs:
--
-- ```
-- previewer = previewers_helper.buffer_preview_files_find
-- previewer_type = PreviewerTypeEnum.BUFFER_FILE
-- ```

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
  local filename_to_bufnr_map = {}

  local bufnrs = vim.api.nvim_list_bufs()
  for _, bufnr in ipairs(bufnrs) do
    local bufpath = path.reduce(vim.api.nvim_buf_get_name(bufnr))
    bufpath = path.normalize(bufpath, { double_backslash = true, expand = true })
    filename_to_bufnr_map[bufpath] = bufnr
  end
  if str.not_empty(line) then
    local parsed = parsers_helper.parse_find(line)
    local bufnr = filename_to_bufnr_map[parsed.filename]
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
}

return M
