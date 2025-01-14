local path = require("fzfx.commons.path")

local consts = require("fzfx.lib.constants")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")
local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum
local _decorator = require("fzfx.cfg._decorator")

local M = {}

M.command = {
  name = "FzfxFiles",
  desc = "Find files",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "restricted_mode",
  },
  -- unrestricted args
  {
    name = "unres_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "unrestricted_mode",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "restricted_mode",
  },
  -- unrestricted visual
  {
    name = "unres_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "unrestricted_mode",
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "restricted_mode",
  },
  -- unrestricted cword
  {
    name = "unres_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "unrestricted_mode",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "restricted_mode",
  },
  -- unrestricted put
  {
    name = "unres_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "unrestricted_mode",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "restricted_mode",
  },
  -- unrestricted resume
  {
    name = "unres_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "unrestricted_mode",
  },
}

-- "fd . -cnever -tf -tl -L -i"
M.RESTRICTED_FD = {
  consts.FD,
  ".",
  "-cnever",
  "-tf",
  "-tl",
  "-L",
  "-i",
}

-- "fd . -cnever -tf -tl -L -i -u"
M.UNRESTRICTED_FD = {
  consts.FD,
  ".",
  "-cnever",
  "-tf",
  "-tl",
  "-L",
  "-i",
  "-u",
}

-- 'find -L . -type f -not -path "*/.*"'
M.RESTRICTED_FIND = consts.IS_WINDOWS
    and {
      consts.FIND,
      "-L",
      ".",
      "-type",
      "f",
    }
  or {
    consts.FIND,
    "-L",
    ".",
    "-type",
    "f",
    "-not",
    "-path",
    [[*/.*]],
  }

-- "find -L . -type f"
M.UNRESTRICTED_FIND = {
  consts.FIND,
  "-L",
  ".",
  "-type",
  "f",
}

local restricted_provider = consts.HAS_FD and M.RESTRICTED_FD or M.RESTRICTED_FIND
local unrestricted_provider = consts.HAS_FD and M.UNRESTRICTED_FD or M.UNRESTRICTED_FIND

M.providers = {
  restricted_mode = {
    key = "ctrl-r",
    provider = restricted_provider,
    provider_type = ProviderTypeEnum.COMMAND_ARRAY,
    provider_decorator = { module = _decorator.PREPEND_ICON_FIND },
  },
  unrestricted_mode = {
    key = "ctrl-u",
    provider = unrestricted_provider,
    provider_type = ProviderTypeEnum.COMMAND_ARRAY,
    provider_decorator = { module = _decorator.PREPEND_ICON_FIND },
  },
}

M.previewers = {
  restricted_mode = {
    previewer = previewers_helper.fzf_preview_find,
    previewer_type = PreviewerTypeEnum.FUNCTIONAL_COMMAND_ARRAY,
    previewer_label = labels_helper.label_find,
  },
  unrestricted_mode = {
    previewer = previewers_helper.fzf_preview_find,
    previewer_type = PreviewerTypeEnum.FUNCTIONAL_COMMAND_ARRAY,
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
  "--multi",
  function()
    return { "--prompt", path.shorten() .. " > " }
  end,
}

return M
