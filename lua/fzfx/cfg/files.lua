local consts = require("fzfx.lib.constants")
local paths = require("fzfx.commons.paths")

local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local providers_helper = require("fzfx.helper.providers")
local previewers_helper = require("fzfx.helper.previewers")

local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.commands = {
  -- command
  name = "FzfxFiles",
  desc = "Find files",

  -- sub commands
  -- normal
  {
    name = "normal_restricted",
    feed = CommandFeedEnum.ARGS,
    default_provider = "restricted_mode",
  },
  {
    name = "normal_unrestricted",
    feed = CommandFeedEnum.ARGS,
    default_provider = "unrestricted_mode",
  },
  -- visual
  {
    name = "visual_restricted",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "restricted_mode",
  },
  {
    name = "visual_unrestricted",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "unrestricted_mode",
  },
  -- cword
  {
    name = "cword_restricted",
    feed = CommandFeedEnum.CWORD,
    default_provider = "restricted_mode",
  },
  {
    name = "cword_unrestricted",
    feed = CommandFeedEnum.CWORD,
    default_provider = "unrestricted_mode",
  },
  -- put
  {
    name = "put_restricted",
    feed = CommandFeedEnum.PUT,
    default_provider = "restricted_mode",
  },
  {
    name = "put_unrestricted",
    feed = CommandFeedEnum.PUT,
    default_provider = "unrestricted_mode",
  },
  -- resume
  {
    name = "resume_restricted",
    feed = CommandFeedEnum.RESUME,
    default_provider = "restricted_mode",
  },
  {
    name = "resume_unrestricted",
    feed = CommandFeedEnum.RESUME,
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
    provider_decorator = { module = "prepend_icon_find", builtin = true },
  },
  unrestricted_mode = {
    key = "ctrl-u",
    provider = unrestricted_provider,
    provider_decorator = { module = "prepend_icon_find", builtin = true },
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
    return { "--prompt", paths.shorten() .. " > " }
  end,
}

return M
