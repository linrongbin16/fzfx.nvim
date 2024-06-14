local M = {}

--- @alias fzfx.Options table<string, any>
--- @type fzfx.Options
local Defaults = {
  -- Find files, i.e. the 'FzfxFiles' command.
  --
  --- @type fzfx.GroupConfig
  files = require("fzfx.cfg.files"),

  -- Live grep, i.e. the 'FzfxLiveGrep' command.
  --
  --- @type fzfx.GroupConfig
  live_grep = require("fzfx.cfg.live_grep"),

  -- Live grep only on current buffer, i.e. the 'FzfxBufLiveGrep' command.
  --
  --- @type fzfx.GroupConfig
  buf_live_grep = require("fzfx.cfg.buf_live_grep"),

  -- Find buffers, i.e. the 'FzfxBuffers' command.
  --
  --- @type fzfx.GroupConfig
  buffers = require("fzfx.cfg.buffers"),

  -- Find git files, i.e. the 'FzfxGFiles' command.
  --
  --- @type fzfx.GroupConfig
  git_files = require("fzfx.cfg.git_files"),

  -- Git live grep, i.e. the 'FzfxGLiveGrep' command.
  --
  --- @type fzfx.GroupConfig
  git_live_grep = require("fzfx.cfg.git_live_grep"),

  -- Search git status (changed files), i.e. the 'FzfxGStatus' command.
  --
  --- @type fzfx.GroupConfig
  git_status = require("fzfx.cfg.git_status"),

  -- Search git branches, i.e. the 'FzfxGBranches' command.
  --
  --- @type fzfx.GroupConfig
  git_branches = require("fzfx.cfg.git_branches"),

  -- Search git commits (logs), i.e. the 'FzfxGCommits' command.
  --
  --- @type fzfx.GroupConfig
  git_commits = require("fzfx.cfg.git_commits"),

  -- Search git blame (on current buffer), i.e. the 'FzfxGBlame' command.
  --
  --- @type fzfx.GroupConfig
  git_blame = require("fzfx.cfg.git_blame"),

  -- Search vim commands, i.e. the 'FzfxCommands' command.
  --
  --- @type fzfx.GroupConfig
  vim_commands = require("fzfx.cfg.vim_commands"),

  -- Search vim key mappings, i.e. the 'FzfxKeyMaps' command.
  --
  --- @type fzfx.GroupConfig
  vim_keymaps = require("fzfx.cfg.vim_keymaps"),

  -- Search vim marks, i.e. the 'FzfxMarks' command.
  --
  --- @type fzfx.GroupConfig
  vim_marks = require("fzfx.cfg.vim_marks"),

  -- Search (LSP) diagnostics, i.e. the 'FzfxLspDiagnostics' command.
  --
  --- @type fzfx.GroupConfig
  lsp_diagnostics = require("fzfx.cfg.lsp_diagnostics"),

  -- Search LSP definitions under cursor, i.e. the 'FzfxLspDefinitions' command.
  --
  --- @type fzfx.GroupConfig
  lsp_definitions = require("fzfx.cfg.lsp_definitions"),

  -- Search LSP type definitions under cursor, i.e. the 'FzfxLspTypeDefinitions' command.
  --
  --- @type fzfx.GroupConfig
  lsp_type_definitions = require("fzfx.cfg.lsp_type_definitions"),

  -- Search LSP references under cursor, i.e. the 'FzfxLspReferences' command.
  --
  --- @type fzfx.GroupConfig
  lsp_references = require("fzfx.cfg.lsp_references"),

  -- Search LSP implementations under cursor, i.e. the 'FzfxLspImplementations' command.
  --
  --- @type fzfx.GroupConfig
  lsp_implementations = require("fzfx.cfg.lsp_implementations"),

  -- Search LSP incoming calls under cursor, i.e. the 'FzfxLspIncomingCalls' command.
  --
  --- @type fzfx.GroupConfig
  lsp_incoming_calls = require("fzfx.cfg.lsp_incoming_calls"),

  -- Search LSP outgoing calls under cursor, i.e. the 'FzfxLspOutgoingCalls' command.
  --
  --- @type fzfx.GroupConfig
  lsp_outgoing_calls = require("fzfx.cfg.lsp_outgoing_calls"),

  -- Search files and directories, i.e. the 'FzfxFileExplorer' command.
  --
  --- @type fzfx.GroupConfig
  file_explorer = require("fzfx.cfg.file_explorer"),

  -- Yanked history, save yanked text as the input of 'put' variants.
  yank_history = {
    other_opts = {
      maxsize = 100,
    },
  },

  -- basic fzf opts
  fzf_opts = {
    "--ansi",
    "--info=inline",
    "--layout=reverse",
    "--border=rounded",
    "--height=100%",
    "--bind=ctrl-e:toggle",
    "--bind=ctrl-a:toggle-all",
    "--bind=alt-p:toggle-preview",
    "--bind=ctrl-f:preview-half-page-down",
    "--bind=ctrl-b:preview-half-page-up",
  },

  -- global fzf opts with highest priority.
  --
  -- there're two 'fzf_opts' configs: root level, commands level, for example if the configs is:
  --
  -- ```lua
  -- {
  --   live_grep = {
  --     fzf_opts = {
  --       '--disabled',
  --       { '--prompt', 'Live Grep > ' },
  --       { '--preview-window', '+{2}-/2' },
  --     },
  --   },
  --   fzf_opts = {
  --     '--no-multi',
  --     { '--preview-window', 'top,70%' },
  --   },
  -- }
  -- ```
  --
  -- finally the engine will emit below options to the 'fzf' binary:
  -- ```
  -- fzf --no-multi --disabled --prompt 'Live Grep > ' --preview-window '+{2}-/2'
  -- ```
  --
  -- note: the '--preview-window' option in root level will be override by command level (live_grep).
  --
  -- now 'override_fzf_opts' provide the highest priority global options that can override command level 'fzf_opts',
  -- so help users to easier config the fzf opts such as '--preview-window'.
  override_fzf_opts = {},

  -- fzf colors
  -- see: https://github.com/junegunn/fzf/blob/master/README-VIM.md#explanation-of-gfzf_colors
  fzf_color_opts = {
    fg = { "fg", "Normal" },
    bg = { "bg", "Normal" },
    hl = { "fg", "Comment" },
    ["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
    ["bg+"] = { "bg", "CursorLine", "CursorColumn" },
    ["hl+"] = { "fg", "Statement" },
    info = { "fg", "PreProc" },
    border = { "fg", "FloatBorder", "NormalFloat", "Normal" },
    prompt = { "fg", "Conditional" },
    pointer = { "fg", "Exception" },
    marker = { "fg", "Keyword" },
    spinner = { "fg", "Label" },
    header = { "fg", "Comment" },
    preview_label = { "fg", "Label" },
  },

  -- icons
  -- nerd fonts: https://www.nerdfonts.com/cheat-sheet
  -- unicode: https://symbl.cc/en/
  icons = {
    -- nerd fonts:
    --     nf-fa-file_text_o               \uf0f6
    --     nf-fa-file_o                    \uf016 (default)
    unknown_file = "",

    -- nerd fonts:
    --     nf-custom-folder                \ue5ff (default)
    --     nf-fa-folder                    \uf07b
    -- 󰉋    nf-md-folder                    \udb80\ude4b
    folder = "",

    -- nerd fonts:
    --     nf-custom-folder_open           \ue5fe (default)
    --     nf-fa-folder_open               \uf07c
    -- 󰝰    nf-md-folder_open               \udb81\udf70
    folder_open = "",

    -- nerd fonts:
    --     nf-oct-arrow_right              \uf432
    --     nf-cod-arrow_right              \uea9c
    --     nf-fa-caret_right               \uf0da
    --     nf-weather-direction_right      \ue349
    --     nf-fa-long_arrow_right          \uf178
    --     nf-oct-chevron_right            \uf460
    --     nf-fa-chevron_right             \uf054 (default)
    --
    -- unicode:
    -- https://symbl.cc/en/collections/arrow-symbols/
    -- ➜    U+279C                          &#10140;
    -- ➤    U+27A4                          &#10148;
    fzf_pointer = "",

    -- nerd fonts:
    --     nf-fa-star                      \uf005
    -- 󰓎    nf-md-star                      \udb81\udcce
    --     nf-cod-star_full                \ueb59
    --     nf-oct-dot_fill                 \uf444
    --     nf-fa-dot_circle_o              \uf192
    --     nf-cod-check                    \ueab2
    --     nf-fa-check                     \uf00c
    -- 󰄬    nf-md-check                     \udb80\udd2c
    --
    -- unicode:
    -- https://symbl.cc/en/collections/star-symbols/
    -- https://symbl.cc/en/collections/list-bullets/
    -- https://symbl.cc/en/collections/special-symbols/
    -- •    U+2022                          &#8226;
    -- ✓    U+2713                          &#10003; (default)
    fzf_marker = "✓",
  },

  -- popup window
  popup = {
    -- popup window layout options
    win_opts = {
      -- popup window height/width.
      --
      -- 1. if 0 <= h/w <= 1, evaluate proportionally according to editor's lines and columns,
      --    e.g. popup height = h * lines, width = w * columns.
      --
      -- 2. if h/w > 1, evaluate as absolute height and width, directly pass to vim.api.nvim_open_win.
      --
      height = 0.85,
      width = 0.85,

      -- popup window position, by default popup window is in the center of editor.
      -- e.g. the option `relative="editor"`.
      -- for now the `relative` options supports:
      --  - editor
      --  - win
      --  - cursor
      relative = "editor",

      -- when relative is 'editor' or 'win', the anchor is the middle center, not the `nvim_open_win` API's default 'NW' (north west).
      -- because 'NW' is a little bit complicated for users to calculate the position, usually we just put the popup window in the center of editor/window.
      -- if you need to adjust the position of popup, you can specify the `row` and `col` of the popup:
      --
      -- 1. if -0.5 <= `row`/`col` <= 0.5, they're evaluated as percentage value based on the editor/window's `height` and `width`.
      --    i.e. the real row of center = `row * height`, real column of center = `col * width`.
      --
      -- 2. if `row`/`col` <= -1 or `row`/`col` >= 1, they're evaluated as absolute value.
      --    e.g. you can set 'row = -vim.o.cmdheight' to move popup up for 1~2 rows based on the 'cmdheight' option.
      --    this is especially useful when popup window is too big and conflicts with the statusline at bottom.
      --
      -- 3. `row`/`col` cannot be in range (-1, -0.5) or (0.5, 1), it's invalid.
      --
      -- when relative is 'cursor', the anchor is 'NW' (north west).
      -- because we just want to put the popup window relative to the cursor.
      -- so 'row' and 'col' will be directly passed to the `nvim_open_win` API without any pre-processing.
      --
      row = 0,
      col = 0,
    },
  },

  cache = {
    dir = require("fzfx.commons.path").join(vim.fn.stdpath("data"), "fzfx.nvim"),
  },

  -- debug
  debug = {
    enable = false,
    console_log = true,
    file_log = false,
  },
}

--- @type fzfx.Options
local Configs = {}

--- @param opts fzfx.Options?
--- @return fzfx.Options
M.setup = function(opts)
  Configs = vim.tbl_deep_extend("force", Defaults, opts or {})
  return Configs
end

--- @return fzfx.Options
M.get = function()
  return Configs
end

--- @param opts fzfx.Options
M.set = function(opts)
  Configs = opts
end

--- @return fzfx.Options
M.defaults = function()
  return Defaults
end

return M
