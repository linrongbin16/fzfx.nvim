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
          "echo %s && %s %s --color=always --header -- %s",
          shells.shellescape(cwd),
          consts.LSD,
          args,
          shells.shellescape(cwd)
        )
      or string.format(
        "%s %s --color=always --header -- %s",
        consts.LSD,
        args,
        shells.shellescape(cwd)
      )
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
          "echo %s && %s --color=always %s %s",
          shells.shellescape(cwd),
          consts.LS,
          args,
          shells.shellescape(cwd)
        )
      or string.format("%s --color=always %s %s", consts.LS, args, shells.shellescape(cwd))
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

M._DIRECTORY_PREVIEWER_LSD = {
  consts.LSD,
  "--color=always",
  "-lha",
  "--header",
  "--",
}

M._DIRECTORY_PREVIEWER_EZA = {
  consts.EZA,
  "--color=always",
  "-lha",
  "--",
}

M._DIRECTORY_PREVIEWER_LS = {
  consts.LS,
  "--color=always",
  "-lha",
  "--",
}

--- @param opts {lsd:boolean?,eza:boolean?,ls:boolean?}?
--- @return fun(filename:string):string[]
M._make_directory_previewer = function(opts)
  opts = opts or {}

  local args
  if opts.lsd then
    args = vim.deepcopy(M._DIRECTORY_PREVIEWER_LSD)
  elseif opts.eza then
    args = vim.deepcopy(M._DIRECTORY_PREVIEWER_EZA)
  elseif opts.ls then
    args = vim.deepcopy(M._DIRECTORY_PREVIEWER_LS)
  end

  --- @param filename string
  --- @return string[]
  local function impl(filename)
    table.insert(args, filename)
    return args
  end

  return impl
end

--- @param filename string
--- @return string[]|nil
M._directory_previewer = function(filename)
  local f

  if consts.HAS_LSD then
    f = M._make_directory_previewer({ lsd = true })
  elseif consts.HAS_EZA then
    f = M._make_directory_previewer({ eza = true })
  elseif consts.HAS_LS then
    f = M._make_directory_previewer({ ls = true })
  else
    log.echo(LogLevels.INFO, "no ls/eza/exa command found.")
    return nil
  end

  return f(filename)
end

local parser
if consts.HAS_LSD then
  parser = parsers_helper.parse_lsd
elseif consts.HAS_EZA then
  parser = parsers_helper.parse_eza
else
  parser = parsers_helper.parse_ls
end

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
--- @return string[]|nil
M._previewer = function(line, context)
  local parsed = parser(line, context)

  if path.isfile(parsed.filename) then
    return previewers_helper.preview_files(parsed.filename)
  elseif path.isdir(parsed.filename) then
    return M._directory_previewer(parsed.filename)
  else
    return nil
  end
end

local previewer_label
if consts.HAS_LSD then
  previewer_label = labels_helper.label_lsd
elseif consts.HAS_EZA then
  previewer_label = labels_helper.label_eza
else
  previewer_label = labels_helper.label_ls
end

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
M._cd = function(line, context)
  local parsed = parser(line, context)

  if path.isdir(parsed.filename) then
    fileio.writefile(context.cwd, parsed.filename)
  end
end

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
M._upper = function(line, context)
  -- log.debug(
  --   string.format(
  --     "|_upper_file_explorer| line:%s, context:%s",
  --     vim.inspect(line),
  --     vim.inspect(context)
  --   )
  -- )
  local cwd = fileio.readfile(context.cwd) --[[@as string]]
  -- log.debug("|_upper_file_explorer| cwd:" .. vim.inspect(cwd))
  local target = vim.fn.fnamemodify(cwd, ":h") --[[@as string]]
  -- log.debug("|_upper_file_explorer| target:" .. vim.inspect(target))
  -- Windows root folder: `C:\`
  -- Unix/linux root folder: `/`
  local root_dir_len = consts.IS_WINDOWS and 3 or 1
  if path.isdir(target) and string.len(target) > root_dir_len then
    fileio.writefile(context.cwd, target)
  end
end

M.interactions = {
  cd = {
    key = "ctrl-l",
    interaction = M._cd,
    reload_after_execute = true,
  },
  upper = {
    key = "ctrl-h",
    interaction = M._upper,
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
