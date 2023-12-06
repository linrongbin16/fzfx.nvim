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

local M = {}

M.commands = {
  -- normal
  {
    name = "FzfxKeyMaps",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "mapping",
      desc = "Find vim keymaps",
    },
    default_provider = "all_mode",
  },
  {
    name = "FzfxKeyMapsN",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "mapping",
      desc = "Find vim normal(n) mode keymaps ",
    },
    default_provider = "n_mode",
  },
  {
    name = "FzfxKeyMapsI",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "mapping",
      desc = "Find vim insert(i) mode keymaps ",
    },
    default_provider = "i_mode",
  },
  {
    name = "FzfxKeyMapsV",
    feed = CommandFeedEnum.ARGS,
    opts = {
      bang = true,
      nargs = "?",
      complete = "mapping",
      desc = "Find vim visual(v/s/x) mode keymaps ",
    },
    default_provider = "v_mode",
  },
  -- visual
  {
    name = "FzfxKeyMapsV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find vim keymaps by visual select",
    },
    default_provider = "all_mode",
  },
  {
    name = "FzfxKeyMapsNV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find vim normal(n) mode keymaps by visual select",
    },
    default_provider = "n_mode",
  },
  {
    name = "FzfxKeyMapsIV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find vim insert(i) mode keymaps by visual select",
    },
    default_provider = "i_mode",
  },
  {
    name = "FzfxKeyMapsVV",
    feed = CommandFeedEnum.VISUAL,
    opts = {
      bang = true,
      range = true,
      desc = "Find vim visual(v/s/x) mode keymaps by visual select",
    },
    default_provider = "v_mode",
  },
  -- cword
  {
    name = "FzfxKeyMapsW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find vim keymaps by cursor word",
    },
    default_provider = "all_mode",
  },
  {
    name = "FzfxKeyMapsNW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find vim normal(n) mode keymaps by cursor word",
    },
    default_provider = "n_mode",
  },
  {
    name = "FzfxKeyMapsIW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find vim insert(i) mode keymaps by cursor word",
    },
    default_provider = "i_mode",
  },
  {
    name = "FzfxKeyMapsVW",
    feed = CommandFeedEnum.CWORD,
    opts = {
      bang = true,
      desc = "Find vim visual(v/s/x) mode keymaps by cursor word",
    },
    default_provider = "v_mode",
  },
  -- put
  {
    name = "FzfxKeyMapsP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find vim keymaps by yank text",
    },
    default_provider = "all_mode",
  },
  {
    name = "FzfxKeyMapsNP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find vim normal(n) mode keymaps by yank text",
    },
    default_provider = "n_mode",
  },
  {
    name = "FzfxKeyMapsIP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find vim insert(i) mode keymaps by yank text",
    },
    default_provider = "i_mode",
  },
  {
    name = "FzfxKeyMapsVP",
    feed = CommandFeedEnum.PUT,
    opts = {
      bang = true,
      desc = "Find vim visual(v/s/x) mode keymaps by yank text",
    },
    default_provider = "v_mode",
  },
  -- resume
  {
    name = "FzfxKeyMapsR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find vim keymaps by resume last",
    },
    default_provider = "all_mode",
  },
  {
    name = "FzfxKeyMapsNR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find vim normal(n) mode keymaps by resume last",
    },
    default_provider = "n_mode",
  },
  {
    name = "FzfxKeyMapsIR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find vim insert(i) mode keymaps by resume last",
    },
    default_provider = "i_mode",
  },
  {
    name = "FzfxKeyMapsVR",
    feed = CommandFeedEnum.RESUME,
    opts = {
      bang = true,
      desc = "Find vim visual(v/s/x) mode keymaps by resume last",
    },
    default_provider = "v_mode",
  },
}

M.providers = {
  all_mode = {
    key = "ctrl-a",
    provider = _make_vim_keymaps_provider("all"),
    provider_type = ProviderTypeEnum.LIST,
  },
  n_mode = {
    key = "ctrl-o",
    provider = _make_vim_keymaps_provider("n"),
    provider_type = ProviderTypeEnum.LIST,
  },
  i_mode = {
    key = "ctrl-i",
    provider = _make_vim_keymaps_provider("i"),
    provider_type = ProviderTypeEnum.LIST,
  },
  v_mode = {
    key = "ctrl-v",
    provider = _make_vim_keymaps_provider("v"),
    provider_type = ProviderTypeEnum.LIST,
  },
}

M.previewers = {
  all_mode = {
    previewer = _vim_keymaps_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_keymap,
  },
  n_mode = {
    previewer = _vim_keymaps_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_keymap,
  },
  i_mode = {
    previewer = _vim_keymaps_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_keymap,
  },
  v_mode = {
    previewer = _vim_keymaps_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_keymap,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.feed_vim_key,
  ["double-click"] = actions_helper.feed_vim_key,
}

M.fzf_opts = {
  default_fzf_options.no_multi,
  "--header-lines=1",
  { "--preview-window", "~1" },
  { "--prompt", "Key Maps > " },
}

M.other_opts = {
  context_maker = _vim_keymaps_context_maker,
}

return M
