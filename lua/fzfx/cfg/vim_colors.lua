local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")
local fio = require("fzfx.commons.fio")
local uv = require("fzfx.commons.uv")

local consts = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.command = {
  name = "FzfxColors",
  desc = "Search colorschemes",
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

--- @return string[]
M._get_colorscheme_filenames = function()
  local colors = vim.fn.split(vim.fn.globpath(vim.o.runtimepath, "colors/*.vim"), "\n")
  if vim.fn.has("packages") > 0 then
    local package_colors =
      vim.fn.split(vim.fn.globpath(vim.o.packpath, "pack/*/opt/*/colors/*.vim"), "\n")
    if tbl.list_not_empty(package_colors) then
      for _, c in ipairs(package_colors) do
        if str.not_empty(c) then
          table.insert(colors, c)
        end
      end
    end
  end

  return colors
end

--- @param colorfile string?
--- @return string?
M._convert_filename_to_colorname = function(colorfile)
  if str.empty(colorfile) then
    return nil
  end
  local normalized = path.normalize(
    colorfile --[[@as string]],
    { double_backslash = true, expand = true, resolve = true }
  )
  if str.empty(normalized) then
    return nil
  end
  local lastpart = vim.fn.fnamemodify(normalized, ":t")
  if str.empty(lastpart) then
    return nil
  end
  local n = string.len(lastpart)
  if n >= 4 and str.endswith(lastpart, ".vim") then
    return string.sub(lastpart, 1, n - 4)
  end
  return nil
end

--- @param query string
--- @param context fzfx.VimColorsPipelineContext
--- @return string[]|nil
local function _provider(query, context)
  local colorfiles = M._get_colorscheme_filenames()
  local colornames = tbl.List
    :move(colorfiles)
    :filter(function(c)
      return str.not_empty(c)
    end)
    :map(function(c)
      return path.normalize(c, { double_backslash = true })
    end)
    :filter(function(c)
      return str.not_empty(c)
    end)
    :map(function(c)
      return vim.fn.fnamemodify(c, ":t")
    end)
    :filter(function(c)
      return str.not_empty(c) and string.len(c) >= 4 and str.endswith(c, ".vim")
    end)
    :map(function(c)
      return string.sub(c, 1, string.len(c) - 4)
    end)
    :data()
  if tbl.list_not_empty(colornames) then
    return colornames
  else
    return nil
  end
end

M.providers = {
  key = "default",
  provider = _provider,
  provider_type = ProviderTypeEnum.DIRECT,
}

M.previewers = {
  previewer = function() end,
  previewer_type = PreviewerTypeEnum.COMMAND_ARRAY,
}

--- @param lines string[]
--- @param context fzfx.VimColorsPipelineContext
M._cancel_action = function(lines, context)
  context.cancelled = true
end

M.actions = {
  ["esc"] = M._cancel_action,
  ["enter"] = actions_helper.feed_vim_color,
  ["double-click"] = actions_helper.feed_vim_color,
}

local colorscheme_is_applying = false

--- @param line string
--- @param context fzfx.VimColorsPipelineContext
M._try_color = function(line, context)
  if colorscheme_is_applying then
    return
  end

  local parsed = parsers_helper.parse_vim_color(line, context)

  if str.not_empty(parsed.colorname) then
    vim.schedule(function()
      colorscheme_is_applying = true
      vim.cmd(string.format([[colorscheme %s]], parsed.colorname))
      vim.schedule(function()
        colorscheme_is_applying = false
      end)
    end)
  end
end

M.interactions = {
  try_color = {
    key = "ctrl-l",
    interaction = M._try_color,
  },
}

M.fzf_opts = {
  "--no-multi",
  { "--preview-window", "hidden" },
  { "--prompt", "Colors > " },
}

--- @alias fzfx.VimColorsPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,saved_color:string,colors:string[],cancelled:boolean?}
--- @return fzfx.VimColorsPipelineContext
M._context_maker = function()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
    saved_color = vim.g.colors_name,
    cancelled = nil,
  }

  return ctx
end

--- @param context fzfx.VimColorsPipelineContext
M._context_shutdown = function(context)
  -- If action is cancelled, and current color is not the saved color,
  -- then we need to revert back to user's original color.
  if context.cancelled then
    vim.schedule(function()
      if str.not_empty(context.saved_color) and vim.g.colors_name ~= context.saved_color then
        vim.cmd(string.format([[colorscheme %s]], context.saved_color))
      end
    end)
  end
end

M.other_opts = {
  context_maker = M._context_maker,
  context_shutdown = M._context_shutdown,
}

return M
