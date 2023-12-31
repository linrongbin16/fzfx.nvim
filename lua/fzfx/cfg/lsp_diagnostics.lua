local tables = require("fzfx.commons.tables")
local termcolors = require("fzfx.commons.termcolors")
local paths = require("fzfx.commons.paths")

local consts = require("fzfx.lib.constants")
local cmds = require("fzfx.lib.commands")
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

M.command = {
  name = "FzfxLspDiagnostics",
  desc = "Search lsp definitions",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "workspace_diagnostics",
  },
  {
    name = "buf_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "buffer_diagnostics",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "workspace_diagnostics",
  },
  {
    name = "buf_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "buffer_diagnostics",
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "workspace_diagnostics",
  },
  {
    name = "buf_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "buffer_diagnostics",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "workspace_diagnostics",
  },
  {
    name = "buf_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "buffer_diagnostics",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "workspace_diagnostics",
  },
  {
    name = "buf_resume",
    feed = CommandFeedEnum.PUT,
    default_provider = "buffer_diagnostics",
  },
}

local LSP_DIAGNOSTICS_SIGNS = {
  [1] = {
    severity = 1,
    name = "DiagnosticSignError",
    text = require("fzfx.lib.env").icon_enabled() and "" or "E", -- nf-fa-times \uf00d
    texthl = vim.fn.hlexists("DiagnosticSignError") > 0
        and "DiagnosticSignError"
      or (
        vim.fn.hlexists("LspDiagnosticsSignError") > 0
          and "LspDiagnosticsSignError"
        or "ErrorMsg"
      ),
    textcolor = "red",
  },
  [2] = {
    severity = 2,
    name = "DiagnosticSignWarn",
    text = require("fzfx.lib.env").icon_enabled() and "" or "W", -- nf-fa-warning \uf071
    texthl = vim.fn.hlexists("DiagnosticSignWarn") > 0 and "DiagnosticSignWarn"
      or (
        vim.fn.hlexists("LspDiagnosticsSignWarn") > 0
          and "LspDiagnosticsSignWarn"
        or "WarningMsg"
      ),
    textcolor = "orange",
  },
  [3] = {
    severity = 3,
    name = "DiagnosticSignInfo",
    text = require("fzfx.lib.env").icon_enabled() and "" or "I", -- nf-fa-info_circle \uf05a
    texthl = vim.fn.hlexists("DiagnosticSignInfo") > 0 and "DiagnosticSignInfo"
      or (
        vim.fn.hlexists("LspDiagnosticsSignInfo") > 0
          and "LspDiagnosticsSignInfo"
        or "None"
      ),
    textcolor = "green",
  },
  [4] = {
    severity = 4,
    name = "DiagnosticSignHint",
    text = require("fzfx.lib.env").icon_enabled() and "" or "H", -- nf-fa-bell \uf0f3
    texthl = vim.fn.hlexists("DiagnosticSignHint") > 0 and "DiagnosticSignHint"
      or (
        vim.fn.hlexists("LspDiagnosticsSignHint") > 0
          and "LspDiagnosticsSignHint"
        or "Comment"
      ),
    textcolor = "grey",
  },
}

--- @return {severity:integer,name:string,text:string,texthl:string,textcolor:string}[]
M._make_lsp_diagnostic_signs = function()
  local results = {}
  for _, signs in ipairs(LSP_DIAGNOSTICS_SIGNS) do
    local sign_def = vim.fn.sign_getdefined(signs.name) --[[@as table]]
    local item = vim.deepcopy(signs)
    if not tables.tbl_empty(sign_def) then
      item.text = vim.trim(sign_def[1].text)
      item.texthl = sign_def[1].texthl
    end
    table.insert(results, item)
  end
  return results
end

--- @param diag {bufnr:integer,lnum:integer,col:integer,message:string,severity:integer}
--- @return {bufnr:integer,filename:string,lnum:integer,col:integer,text:string,severity:integer}?
M._process_lsp_diagnostic_item = function(diag)
  if not vim.api.nvim_buf_is_valid(diag.bufnr) then
    return nil
  end
  log.debug("|_process_lsp_diagnostic_item| diag-1:%s", vim.inspect(diag))
  local result = {
    bufnr = diag.bufnr,
    filename = paths.reduce(vim.api.nvim_buf_get_name(diag.bufnr)),
    lnum = diag.lnum + 1,
    col = diag.col + 1,
    text = vim.trim(diag.message:gsub("\n", " ")),
    severity = diag.severity or 1,
  }
  log.debug(
    "|_process_lsp_diagnostic_item| diag-2:%s, result:%s",
    vim.inspect(diag),
    vim.inspect(result)
  )
  return result
end

--- @param opts {buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
M._make_lsp_diagnostics_provider = function(opts)
  local signs = M._make_lsp_diagnostic_signs()

  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    ---@diagnostic disable-next-line: deprecated
    local lsp_clients = vim.lsp.get_active_clients()
    if tables.tbl_empty(lsp_clients) then
      log.echo(LogLevels.INFO, "no active lsp clients.")
      return nil
    end
    local diag_list = vim.diagnostic.get(
      (type(opts) == "table" and opts.buffer) and context.bufnr or nil
    )
    if tables.tbl_empty(diag_list) then
      log.echo(LogLevels.INFO, "no lsp diagnostics found.")
      return nil
    end
    -- sort order: error > warn > info > hint
    table.sort(diag_list, function(a, b)
      return a.severity < b.severity
    end)

    local results = {}
    for _, item in ipairs(diag_list) do
      local diag = M._process_lsp_diagnostic_item(item)
      if diag then
        -- it looks like:
        -- `lua/fzfx/config.lua:10:13: Unused local `query`.
        log.debug("|_make_lsp_diagnostics_provider| diag:%s", vim.inspect(diag))
        local builder = ""
        if type(diag.text) == "string" and string.len(diag.text) > 0 then
          if type(signs[diag.severity]) == "table" then
            local sign_item = signs[diag.severity]
            local color_renderer = termcolors[sign_item.textcolor]
            builder = " " .. color_renderer(sign_item.text, sign_item.texthl)
          end
          builder = builder .. " " .. diag.text
        end
        log.debug(
          "|_make_lsp_diagnostics_provider| diag:%s, builder:%s",
          vim.inspect(diag),
          vim.inspect(builder)
        )
        local line = string.format(
          "%s:%s:%s:%s",
          providers_helper.LSP_FILENAME_COLOR(diag.filename),
          termcolors.green(tostring(diag.lnum)),
          tostring(diag.col),
          builder
        )
        table.insert(results, line)
      end
    end
    return results
  end
  return impl
end

M.providers = {
  workspace_diagnostics = {
    key = "ctrl-w",
    provider = M._make_lsp_diagnostics_provider(),
    provider_type = ProviderTypeEnum.LIST,
    provider_decorator = { module = "prepend_icon_grep", builtin = true },
  },
  buffer_diagnostics = {
    key = "ctrl-u",
    provider = M._make_lsp_diagnostics_provider({ buffer = true }),
    provider_type = ProviderTypeEnum.LIST,
    provider_decorator = { module = "prepend_icon_grep", builtin = true },
  },
}

M.previewers = {
  workspace_diagnostics = {
    previewer = previewers_helper.preview_files_grep,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_rg,
  },
  buffer_diagnostics = {
    previewer = previewers_helper.preview_files_grep,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_rg,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_rg,
  ["double-click"] = actions_helper.edit_rg,
  ["ctrl-q"] = actions_helper.setqflist_rg,
}

M.fzf_opts = {
  consts.FZF_OPTS.MULTI,
  consts.FZF_OPTS.DELIMITER,
  consts.FZF_OPTS.GREP_PREVIEW_WINDOW,
  { "--prompt", "Diagnostics > " },
}

return M
