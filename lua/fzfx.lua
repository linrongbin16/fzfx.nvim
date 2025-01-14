local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local M = {}

-- Register a command (such as `FzfxFiles`) in fzfx.
--- @param name string
--- @param configs fzfx.Options
M.register = function(name, configs)
  require("fzfx.detail.general").setup(name, configs)
end

--- @param opts fzfx.Options?
M.setup = function(opts)
  -- configs
  local configs = require("fzfx.config").setup(opts)

  -- log
  log.setup({
    level = configs.debug.enable and LogLevels.DEBUG or LogLevels.INFO,
    console_log = configs.debug.console_log,
    file_log = configs.debug.file_log,
  })

  -- cache
  if vim.fn.filereadable(configs.cache.dir) > 0 then
    log.throw(
      string.format("the 'cache.dir' (%s) already exist but not a directory!", configs.cache.dir)
    )
  else
    vim.fn.mkdir(configs.cache.dir, "p")
  end

  -- initialize
  require("fzfx.detail.module").setup()
  require("fzfx.detail.rpcserver").setup()
  require("fzfx.detail.yanks").setup()
  require("fzfx.detail.popup.window").setup()
  require("fzfx.detail.fzf_helpers").setup()

  -- files & buffers
  M.register("files", configs.files)
  M.register("buffers", configs.buffers)

  -- grep
  M.register("live_grep", configs.live_grep)
  M.register("buf_live_grep", configs.buf_live_grep)

  -- git
  M.register("git_files", configs.git_files)
  M.register("git_live_grep", configs.git_live_grep)
  M.register("git_status", configs.git_status)
  M.register("git_branches", configs.git_branches)
  M.register("git_commits", configs.git_commits)
  M.register("git_blame", configs.git_blame)

  -- lsp & diagnostics
  M.register("lsp_definitions", configs.lsp_definitions)
  M.register("lsp_type_definitions", configs.lsp_type_definitions)
  M.register("lsp_references", configs.lsp_references)
  M.register("lsp_implementations", configs.lsp_implementations)
  M.register("lsp_incoming_calls", configs.lsp_incoming_calls)
  M.register("lsp_outgoing_calls", configs.lsp_outgoing_calls)
  M.register("lsp_diagnostics", configs.lsp_diagnostics)

  -- vim
  M.register("vim_commands", configs.vim_commands)
  M.register("vim_keymaps", configs.vim_keymaps)
  M.register("vim_marks", configs.vim_marks)
  M.register("vim_command_history", configs.vim_command_history)

  -- file explorer
  M.register("file_explorer", configs.file_explorer)
end

return M
