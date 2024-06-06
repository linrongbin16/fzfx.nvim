local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

--- @param opts fzfx.Options?
local function setup(opts)
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
  require("fzfx.detail.popup").setup()
  require("fzfx.detail.bat_helpers").setup()
  require("fzfx.detail.fzf_helpers").setup()

  local general = require("fzfx.detail.general")

  -- files & buffers
  general.setup("files", configs.files)
  general.setup("buffers", configs.buffers)

  -- grep
  general.setup("live_grep", configs.live_grep)
  general.setup("buf_live_grep", configs.buf_live_grep)

  -- git
  general.setup("git_files", configs.git_files)
  general.setup("git_live_grep", configs.git_live_grep)
  general.setup("git_status", configs.git_status)
  general.setup("git_branches", configs.git_branches)
  general.setup("git_commits", configs.git_commits)
  general.setup("git_blame", configs.git_blame)

  -- lsp & diagnostics
  general.setup("lsp_definitions", configs.lsp_definitions)
  general.setup("lsp_type_definitions", configs.lsp_type_definitions)
  general.setup("lsp_references", configs.lsp_references)
  general.setup("lsp_implementations", configs.lsp_implementations)
  general.setup("lsp_incoming_calls", configs.lsp_incoming_calls)
  general.setup("lsp_outgoing_calls", configs.lsp_outgoing_calls)
  general.setup("lsp_diagnostics", configs.lsp_diagnostics)

  -- vim
  general.setup("vim_commands", configs.vim_commands)
  general.setup("vim_keymaps", configs.vim_keymaps)
  general.setup("vim_marks", configs.vim_marks)

  -- file explorer
  general.setup("file_explorer", configs.file_explorer)
end

--- @param name string
--- @param configs fzfx.Options
local function register(name, configs)
  require("fzfx.detail.general").setup(name, configs)
end

local M = {
  setup = setup,
  register = register,
}

return M
