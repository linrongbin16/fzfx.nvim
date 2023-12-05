local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")
local cmds = require("fzfx.lib.commands")
local colors = require("fzfx.lib.colors")
local paths = require("fzfx.lib.paths")
local fs = require("fzfx.lib.filesystems")
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

  git_live_grep = {
    commands = {
      -- normal
      {
        name = "FzfxGLiveGrep",
        feed = CommandFeedEnum.ARGS,
        opts = {
          bang = true,
          nargs = "*",
          desc = "Git live grep",
        },
      },
      -- visual
      {
        name = "FzfxGLiveGrepV",
        feed = CommandFeedEnum.VISUAL,
        opts = {
          bang = true,
          range = true,
          desc = "Git live grep by visual select",
        },
      },
      -- cword
      {
        name = "FzfxGLiveGrepW",
        feed = CommandFeedEnum.CWORD,
        opts = {
          bang = true,
          desc = "Git live grep by cursor word",
        },
      },
      -- put
      {
        name = "FzfxGLiveGrepP",
        feed = CommandFeedEnum.PUT,
        opts = {
          bang = true,
          desc = "Git live grep by yank text",
        },
      },
      -- resume
      {
        name = "FzfxGLiveGrepR",
        feed = CommandFeedEnum.RESUME,
        opts = {
          bang = true,
          desc = "Git live grep by resume last",
        },
      },
    },
    providers = {
      key = "default",
      provider = _git_live_grep_provider,
      provider_type = ProviderTypeEnum.COMMAND_LIST,
      line_opts = {
        prepend_icon_by_ft = true,
        prepend_icon_path_delimiter = ":",
        prepend_icon_path_position = 1,
      },
    },
    previewers = {
      previewer = _file_previewer_grep,
      previewer_type = PreviewerTypeEnum.COMMAND_LIST,
      previewer_label = labels_helper.label_grep,
    },
    actions = {
      ["esc"] = actions_helper.nop,
      ["enter"] = actions_helper.edit_grep,
      ["double-click"] = actions_helper.edit_grep,
      ["ctrl-q"] = actions_helper.setqflist_grep,
    },
    fzf_opts = {
      default_fzf_options.multi,
      { "--prompt", "Git Live Grep > " },
      "--disabled",
      { "--delimiter", ":" },
      { "--preview-window", "+{2}-/2" },
    },
    other_opts = {
      reload_on_change = true,
    },
  },

