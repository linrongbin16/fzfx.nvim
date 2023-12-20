local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")
local cmds = require("fzfx.lib.commands")
local paths = require("fzfx.lib.paths")
local fileios = require("fzfx.commons.fileios")
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
    name = "FzfxFileExplorer",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "dir",
      desc = "File explorer (ls -l)",
    },
    default_provider = "filter_hidden",
  },
  {
    name = "FzfxFileExplorerU",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "dir",
      desc = "File explorer (ls -la)",
    },
    default_provider = "include_hidden",
  },
  -- visual
  {
    name = "FzfxFileExplorerV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "File explorer (ls -l) by visual select",
    },
    default_provider = "filter_hidden",
  },
  {
    name = "FzfxFileExplorerUV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "File explorer (ls -la) by visual select",
    },
    default_provider = "include_hidden",
  },
  -- word
  {
    name = "FzfxFileExplorerW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "File explorer (ls -l) by cursor word",
    },
    default_provider = "filter_hidden",
  },
  {
    name = "FzfxFileExplorerUW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "File explorer (ls -la) by cursor word",
    },
    default_provider = "include_hidden",
  },
  -- put
  {
    name = "FzfxFileExplorerP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "File explorer (ls -l) by yank text",
    },
    default_provider = "filter_hidden",
  },
  {
    name = "FzfxFileExplorerUP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "File explorer (ls -la) by yank text",
    },
    default_provider = "include_hidden",
  },
  -- resume
  {
    name = "FzfxFileExplorerR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "File explorer (ls -l) by resume last",
    },
    default_provider = "filter_hidden",
  },
  {
    name = "FzfxFileExplorerUR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "File explorer (ls -la) by resume last",
    },
    default_provider = "include_hidden",
  },
}

--- @param ls_args "-lh"|"-lha"
--- @return fun(query:string, context:fzfx.FileExplorerPipelineContext):string?
M._make_file_explorer_provider = function(ls_args)
  --- @param query string
  --- @param context fzfx.FileExplorerPipelineContext
  --- @return string?
  local function impl(query, context)
    local cwd = fileios.readfile(context.cwd)
    if consts.HAS_LSD then
      return consts.HAS_ECHO
          and string.format(
            "echo %s && lsd %s --color=always --header -- %s",
            nvims.shellescape(cwd --[[@as string]]),
            ls_args,
            nvims.shellescape(cwd --[[@as string]])
          )
        or string.format(
          "lsd %s --color=always --header -- %s",
          ls_args,
          nvims.shellescape(cwd --[[@as string]])
        )
    elseif consts.HAS_EZA then
      return consts.HAS_ECHO
          and string.format(
            "echo %s && %s --color=always %s -- %s",
            nvims.shellescape(cwd --[[@as string]]),
            consts.EZA,
            ls_args,
            nvims.shellescape(cwd --[[@as string]])
          )
        or string.format(
          "%s --color=always %s -- %s",
          consts.EZA,
          ls_args,
          nvims.shellescape(cwd --[[@as string]])
        )
    elseif consts.HAS_LS then
      return consts.HAS_ECHO
          and string.format(
            "echo %s && ls --color=always %s %s",
            nvims.shellescape(cwd --[[@as string]]),
            ls_args,
            nvims.shellescape(cwd --[[@as string]])
          )
        or string.format(
          "ls --color=always %s %s",
          ls_args,
          nvims.shellescape(cwd --[[@as string]])
        )
    else
      log.echo(LogLevels.INFO, "no ls/eza/exa command found.")
      return nil
    end
  end

  return impl
end

M.providers = {
  filter_hidden = {
    key = "ctrl-r",
    provider = M._make_file_explorer_provider("-lh"),
    provider_type = ProviderTypeEnum.COMMAND,
  },
  include_hidden = {
    key = "ctrl-u",
    provider = M._make_file_explorer_provider("-lha"),
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
  elseif vim.fn.executable("ls") > 0 then
    return { "ls", "--color=always", "-lha", "--", filename }
  else
    log.echo(LogLevels.INFO, "no ls/eza/exa command found.")
    return nil
  end
end

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
--- @return string[]|nil
M._file_explorer_previewer = function(line, context)
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
    previewer = M._file_explorer_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = previewer_label,
  },
  include_hidden = {
    previewer = M._file_explorer_previewer,
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
    fileios.writefile(context.cwd, parsed.filename)
  end
end

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
M._upper_file_explorer = function(line, context)
  local cwd = fileios.readfile(context.cwd) --[[@as string]]
  local target = vim.fn.fnamemodify(cwd, ":h") --[[@as string]]
  -- Windows root folder: `C:\`
  -- Unix/linux root folder: `/`
  local root_len = consts.IS_WINDOWS and 3 or 1
  if vim.fn.isdirectory(target) > 0 and string.len(target) > root_len then
    fileios.writefile(context.cwd, target)
  end
end

M.interactions = {
  cd = {
    key = "alt-l",
    interaction = M._cd_file_explorer,
    reload_after_execute = true,
  },
  upper = {
    key = "alt-h",
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
  consts.FZF_OPTS.MULTI,
  { "--prompt", paths.shorten() .. " > " },
  function()
    local n = 0
    if consts.HAS_LSD or consts.HAS_EZA or consts.HAS_LS then
      n = n + 1
    end
    if consts.HAS_ECHO then
      n = n + 1
    end
    return n > 0 and string.format("--header-lines=%d", n) or nil
  end,
}

--- @alias fzfx.FileExplorerPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,cwd:string}
--- @return fzfx.FileExplorerPipelineContext
M._file_explorer_context_maker = function()
  local temp = vim.fn.tempname()
  fileios.writefile(temp --[[@as string]], vim.fn.getcwd() --[[@as string]])
  local context = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
    cwd = temp,
  }
  return context
end

M.other_opts = {
  context_maker = M._file_explorer_context_maker,
}

return M
