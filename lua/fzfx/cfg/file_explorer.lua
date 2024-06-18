local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")
local fileio = require("fzfx.commons.fileio")

local consts = require("fzfx.lib.constants")
local shells = require("fzfx.lib.shells")
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
  name = "FzfxFileExplorer",
  desc = "File explorer (ls -l)",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "filter_hidden",
  },
  {
    name = "hidden_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "include_hidden",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "filter_hidden",
  },
  {
    name = "hidden_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "include_hidden",
  },
  -- word
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "filter_hidden",
  },
  {
    name = "hidden_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "include_hidden",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "filter_hidden",
  },
  {
    name = "hidden_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "include_hidden",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "filter_hidden",
  },
  {
    name = "hidden_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "include_hidden",
  },
}

--- @param opts {include_hidden:boolean?}?
--- @return "-lh"|"-lha"
M._parse_opts = function(opts)
  opts = opts or {}
  local include_hidden = opts.include_hidden or false
  return include_hidden and "-lha" or "-lh"
end

--- @param opts {include_hidden:boolean?}?
--- @return fun(query:string, context:fzfx.FileExplorerPipelineContext):string?
M._make_provider_lsd = function(opts)
  local args = M._parse_opts(opts)

  --- @param query string
  --- @param context fzfx.FileExplorerPipelineContext
  --- @return string?
  local function impl(query, context)
    local cwd = fileio.readfile(context.cwd) --[[@as string]]
    return consts.HAS_ECHO
        and string.format(
          "echo %s && lsd %s --color=always --header -- %s",
          shells.shellescape(cwd),
          args,
          shells.shellescape(cwd)
        )
      or string.format("lsd %s --color=always --header -- %s", args, shells.shellescape(cwd))
  end

  return impl
end

--- @param opts {include_hidden:boolean?}?
--- @return fun(query:string, context:fzfx.FileExplorerPipelineContext):string?
M._make_provider_eza = function(opts)
  local args = M._parse_opts(opts)

  --- @param query string
  --- @param context fzfx.FileExplorerPipelineContext
  --- @return string?
  local function impl(query, context)
    local cwd = fileio.readfile(context.cwd) --[[@as string]]
    if str.endswith(args, "a") then
      -- eza need double 'a' to show '.' and '..' directories
      args = args .. "a"
    end
    return consts.HAS_ECHO
        and string.format(
          "echo %s && %s --color=always %s -- %s",
          shells.shellescape(cwd),
          consts.EZA,
          args,
          shells.shellescape(cwd)
        )
      or string.format("%s --color=always %s -- %s", consts.EZA, args, shells.shellescape(cwd))
  end

  return impl
end

--- @param opts {include_hidden:boolean?}?
--- @return fun(query:string, context:fzfx.FileExplorerPipelineContext):string?
M._make_provider_ls = function(opts)
  local args = M._parse_opts(opts)

  --- @param query string
  --- @param context fzfx.FileExplorerPipelineContext
  --- @return string?
  local function impl(query, context)
    local cwd = fileio.readfile(context.cwd) --[[@as string]]
    return consts.HAS_ECHO
        and string.format(
          "echo %s && ls --color=always %s %s",
          shells.shellescape(cwd),
          args,
          shells.shellescape(cwd)
        )
      or string.format("ls --color=always %s %s", args, shells.shellescape(cwd))
  end

  return impl
end

--- @return fun(query:string, context:fzfx.FileExplorerPipelineContext):string?
M._make_provider_dummy = function()
  --- @param query string
  --- @param context fzfx.FileExplorerPipelineContext
  --- @return string?
  local function impl(query, context)
    log.echo(LogLevels.INFO, "no ls/eza/exa command found.")
    return nil
  end

  return impl
end

--- @param opts {include_hidden:boolean?}?
--- @return fun(query:string, context:fzfx.FileExplorerPipelineContext):string?
M._make_provider = function(opts)
  if consts.HAS_LSD then
    return M._make_provider_lsd(opts)
  elseif consts.HAS_EZA then
    return M._make_provider_eza(opts)
  elseif consts.HAS_LS then
    return M._make_provider_ls(opts)
  else
    return M._make_provider_dummy()
  end
end

M.providers = {
  filter_hidden = {
    key = "ctrl-r",
    provider = M._make_provider(),
    provider_type = ProviderTypeEnum.COMMAND,
  },
  include_hidden = {
    key = "ctrl-u",
    provider = M._make_provider({ include_hidden = true }),
    provider_type = ProviderTypeEnum.COMMAND,
  },
}

--- @param filename string
--- @return string[]|nil
M._directory_previewer = function(filename)
  if consts.HAS_LSD then
    return {
      "lsd",
      "--color=always",
      "-lha",
      "--header",
      "--",
      filename,
    }
  elseif consts.HAS_EZA then
    return {
      consts.EZA,
      "--color=always",
      "-lha",
      "--",
      filename,
    }
  elseif consts.HAS_LS then
    return { "ls", "--color=always", "-lha", "--", filename }
  else
    log.echo(LogLevels.INFO, "no ls/eza/exa command found.")
    return nil
  end
end

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
--- @return string[]|nil
M._previewer = function(line, context)
  local parsed = consts.HAS_LSD and parsers_helper.parse_lsd(line, context)
    or (
      consts.HAS_EZA and parsers_helper.parse_eza(line, context)
      or parsers_helper.parse_ls(line, context)
    )
  if vim.fn.filereadable(parsed.filename) > 0 then
    return previewers_helper.preview_files(parsed.filename)
  elseif vim.fn.isdirectory(parsed.filename) > 0 then
    return M._directory_previewer(parsed.filename)
  else
    return nil
  end
end

local previewer_label = consts.HAS_LSD and labels_helper.label_lsd
  or (consts.HAS_EZA and labels_helper.label_eza or labels_helper.label_ls)

M.previewers = {
  filter_hidden = {
    previewer = M._previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = previewer_label,
  },
  include_hidden = {
    previewer = M._previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = previewer_label,
  },
}

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
M._cd_file_explorer = function(line, context)
  local parsed = consts.HAS_LSD and parsers_helper.parse_lsd(line, context)
    or (
      consts.HAS_EZA and parsers_helper.parse_eza(line, context)
      or parsers_helper.parse_ls(line, context)
    )
  if vim.fn.isdirectory(parsed.filename) > 0 then
    fileio.writefile(context.cwd, parsed.filename)
  end
end

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
M._upper_file_explorer = function(line, context)
  log.debug(
    string.format(
      "|_upper_file_explorer| line:%s, context:%s",
      vim.inspect(line),
      vim.inspect(context)
    )
  )
  local cwd = fileio.readfile(context.cwd) --[[@as string]]
  log.debug("|_upper_file_explorer| cwd:" .. vim.inspect(cwd))
  local target = vim.fn.fnamemodify(cwd, ":h") --[[@as string]]
  log.debug("|_upper_file_explorer| target:" .. vim.inspect(target))
  -- Windows root folder: `C:\`
  -- Unix/linux root folder: `/`
  local root_len = consts.IS_WINDOWS and 3 or 1
  if vim.fn.isdirectory(target) > 0 and string.len(target) > root_len then
    fileio.writefile(context.cwd, target)
  end
end

M.interactions = {
  cd = {
    key = "ctrl-l",
    interaction = M._cd_file_explorer,
    reload_after_execute = true,
  },
  upper = {
    key = "ctrl-h",
    interaction = M._upper_file_explorer,
    reload_after_execute = true,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_ls,
  ["double-click"] = actions_helper.edit_ls,
}

M.fzf_opts = {
  "--multi",
  { "--prompt", path.shorten() .. " > " },
  function()
    local n = 0
    if consts.HAS_ECHO then
      n = n + 1
    end
    if consts.HAS_LSD or consts.HAS_EZA or consts.HAS_LS then
      n = n + 1
    end
    return n > 0 and string.format("--header-lines=%d", n) or nil
  end,
}

--- @alias fzfx.FileExplorerPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,cwd:string}
--- @return fzfx.FileExplorerPipelineContext
M._context_maker = function()
  local temp = vim.fn.tempname()
  fileio.writefile(temp --[[@as string]], vim.fn.getcwd() --[[@as string]])
  local context = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
    cwd = temp,
  }
  return context
end

M.other_opts = {
  context_maker = M._context_maker,
}

return M
