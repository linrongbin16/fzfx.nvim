local tbl = require("fzfx.commons.tbl")
local api = require("fzfx.commons.api")
local path = require("fzfx.commons.path")
local term_color = require("fzfx.commons.color.term")

local switches = require("fzfx.lib.switches")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels
local env = require("fzfx.lib.env")

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

local _, _, SIGN_ERROR_HL =
  api.get_hl_with_fallback("DiagnosticSignError", "LspDiagnosticsSignError", "ErrorMsg")
local _, _, SIGN_WARN_HL =
  api.get_hl_with_fallback("DiagnosticSignWarn", "LspDiagnosticsSignWarn", "WarningMsg")
local _, _, SIGN_INFO_HL =
  api.get_hl_with_fallback("DiagnosticSignInfo", "LspDiagnosticsSignInfo", "None")
local _, _, SIGN_HINT_HL =
  api.get_hl_with_fallback("DiagnosticSignHint", "LspDiagnosticsSignHint", "Comment")

local LSP_DIAGNOSTICS_SIGNS = {
  [1] = {
    severity = 1,
    name = "DiagnosticSignError",
    text = env.icon_enabled() and "" or "E", -- nf-fa-times \uf00d
    texthl = SIGN_ERROR_HL,
    textcolor = "red",
  },
  [2] = {
    severity = 2,
    name = "DiagnosticSignWarn",
    text = env.icon_enabled() and "" or "W", -- nf-fa-warning \uf071
    texthl = SIGN_WARN_HL,
    textcolor = "orange",
  },
  [3] = {
    severity = 3,
    name = "DiagnosticSignInfo",
    text = env.icon_enabled() and "" or "I", -- nf-fa-info_circle \uf05a
    texthl = SIGN_INFO_HL,
    textcolor = "cyan",
  },
  [4] = {
    severity = 4,
    name = "DiagnosticSignHint",
    text = env.icon_enabled() and "" or "H", -- nf-fa-bell \uf0f3
    texthl = SIGN_HINT_HL,
    textcolor = "grey",
  },
}

--- @return {severity:integer,name:string,text:string,texthl:string,textcolor:string}[]
M._make_lsp_diagnostic_signs = function()
  local results = {}
  for _, signs in ipairs(LSP_DIAGNOSTICS_SIGNS) do
    local sign_def = vim.fn.sign_getdefined(signs.name) --[[@as table]]
    local item = vim.deepcopy(signs)
    if not tbl.tbl_empty(sign_def) then
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
  log.debug(string.format("|_process_lsp_diagnostic_item| diag-1:%s", vim.inspect(diag)))
  local result = {
    bufnr = diag.bufnr,
    filename = path.reduce(vim.api.nvim_buf_get_name(diag.bufnr)),
    lnum = diag.lnum + 1,
    col = diag.col + 1,
    text = vim.trim(diag.message:gsub("\n", " ")),
    severity = diag.severity or 1,
  }
  log.debug(
    string.format(
      "|_process_lsp_diagnostic_item| diag-2:%s, result:%s",
      vim.inspect(diag),
      vim.inspect(result)
    )
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
    if tbl.tbl_empty(lsp_clients) then
      log.echo(LogLevels.INFO, "no active lsp clients.")
      return nil
    end
    local diag_list =
      vim.diagnostic.get((type(opts) == "table" and opts.buffer) and context.bufnr or nil)
    if tbl.tbl_empty(diag_list) then
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
        log.debug(string.format("|_make_lsp_diagnostics_provider| diag:%s", vim.inspect(diag)))
        local builder = ""
        if type(diag.text) == "string" and string.len(diag.text) > 0 then
          if type(signs[diag.severity]) == "table" then
            local sign_item = signs[diag.severity]
            local color_renderer = term_color[sign_item.textcolor]
            builder = " " .. color_renderer(sign_item.text, sign_item.texthl)
          end
          builder = builder .. " " .. diag.text
        end
        log.debug(
          string.format(
            "|_make_lsp_diagnostics_provider| diag:%s, builder:%s",
            vim.inspect(diag),
            vim.inspect(builder)
          )
        )
        local line = string.format(
          "%s:%s:%s:%s",
          providers_helper.LSP_FILENAME_COLOR(diag.filename),
          term_color.green(tostring(diag.lnum)),
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

-- if you want to use fzf-builtin previewer with bat, please use below configs:
--
-- previewer = previewers_helper.preview_files_grep
-- previewer_type = PreviewerTypeEnum.COMMAND_LIST

-- if you want to use nvim buffer previewer, please use below configs:
--
-- previewer = previewers_helper.buffer_preview_files_grep
-- previewer_type = PreviewerTypeEnum.BUFFER_FILE

local previewer = switches.buffer_previewer_disabled() and previewers_helper.preview_files_grep
  or previewers_helper.buffer_preview_files_grep
local previewer_type = switches.buffer_previewer_disabled() and PreviewerTypeEnum.COMMAND_LIST
  or PreviewerTypeEnum.BUFFER_FILE

M.previewers = {
  workspace_diagnostics = {
    previewer = previewer,
    previewer_type = previewer_type,
    previewer_label = labels_helper.label_rg,
  },
  buffer_diagnostics = {
    previewer = previewer,
    previewer_type = previewer_type,
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
  "--multi",
  { "--delimiter", ":" },
  { "--preview-window", "+{2}-/2" },
  { "--prompt", "Diagnostics > " },
}

return M
