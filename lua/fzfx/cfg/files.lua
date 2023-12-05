local consts = require("fzfx.lib.constants")
local paths = require("fzfx.lib.paths")

local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local providers_helper = require("fzfx.helper.providers")
local previewers_helper = require("fzfx.helper.previewers")

local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.commands = {
  -- normal
  {
    name = "FzfxFiles",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "dir",
      desc = "Find files",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxFilesU",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "dir",
      desc = "Find files",
    },
    default_provider = "unrestricted_mode",
  },
  -- visual
  {
    name = "FzfxFilesV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find files by visual select",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxFilesUV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find files unrestricted by visual select",
    },
    default_provider = "unrestricted_mode",
  },
  -- cword
  {
    name = "FzfxFilesW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find files by cursor word",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxFilesUW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find files unrestricted by cursor word",
    },
    default_provider = "unrestricted_mode",
  },
  -- put
  {
    name = "FzfxFilesP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find files by yank text",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxFilesUP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find files unrestricted by yank text",
    },
    default_provider = "unrestricted_mode",
  },
  -- resume
  {
    name = "FzfxFilesR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find files by resume last",
    },
    default_provider = "restricted_mode",
  },
  {
    name = "FzfxFilesUR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find files unrestricted by resume last",
    },
    default_provider = "unrestricted_mode",
  },
}

local restricted_provider = consts.HAS_FD and providers_helper.RESTRICTED_FD
  or providers_helper.RESTRICTED_FIND
local unrestricted_provider = consts.HAS_FD and providers_helper.UNRESTRICTED_FD
  or providers_helper.UNRESTRICTED_FIND

M.providers = {
  restricted_mode = {
    key = "ctrl-r",
    provider = restricted_provider,
    line_opts = { prepend_icon_by_ft = true },
  },
  unrestricted_mode = {
    key = "ctrl-u",
    provider = unrestricted_provider,
    line_opts = { prepend_icon_by_ft = true },
  },
}

M.previewers = {
  restricted_mode = {
    previewer = previewers_helper.preview_files_find,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_find,
  },
  unrestricted_mode = {
    previewer = previewers_helper.preview_files_find,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_find,
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
  function()
    return { consts.FZF_OPTS.PROMPT, paths.shorten() .. " > " }
  end,
}

return M
