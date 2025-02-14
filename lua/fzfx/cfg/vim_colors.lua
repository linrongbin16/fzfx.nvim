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

--- @param query string
--- @param context fzfx.VimColorsPipelineContext
--- @return string[]|nil
local function _provider(query, context)
  local colorfiles = M._get_colorscheme_filenames()
  -- Convert color filenames to color names.
  local colornames = tbl.List
    :move(colorfiles)
    :filter(function(c)
      return str.not_empty(c)
    end)
    :map(function(c)
      -- Normalize filepath.
      return path.normalize(c, { double_backslash = true })
    end)
    :filter(function(c)
      return str.not_empty(c)
    end)
    :map(function(c)
      -- Get the tail of filename.
      return vim.fn.fnamemodify(c, ":t")
    end)
    :filter(function(c)
      -- Detect if color filename ends with '.vim' extension.
      return str.not_empty(c) and string.len(c) >= 4 and str.endswith(c, ".vim")
    end)
    :map(function(c)
      -- Remove '.vim' extension and get the color name.
      return string.sub(c, 1, string.len(c) - 4)
    end)
    :filter(function(c)
      -- Don't show current colorscheme here.
      return c ~= context.saved_color
    end)
    :data()

  -- Show current colorscheme at top line.
  table.insert(colornames, 1, context.saved_color)

  return colornames
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
      vim.cmd(string.format([[color %s]], parsed.colorname))
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
  function()
    if str.not_empty(vim.g.colors_name) then
      return "--header-lines=1"
    end
    return nil
  end,
}

--- @alias fzfx.VimColorsPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,saved_color:string,colors:string[],cancelled:boolean?}
--- @return fzfx.VimColorsPipelineContext
M._context_maker = function()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
    saved_color = vim.g.colors_name,
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
        vim.cmd(string.format([[color %s]], context.saved_color))
      end
    end)
  end
end

M.other_opts = {
  context_maker = M._context_maker,
  context_shutdown = M._context_shutdown,
}

M.win_opts = function()
  local editor_height = vim.o.lines
  local height = math.max(15, math.floor(editor_height * 0.4))
  local editor_width = vim.o.columns
  local width = math.max(40, math.floor(editor_width * 0.5))

  return {
    height = height,
    width = width,
  }
end

return M
