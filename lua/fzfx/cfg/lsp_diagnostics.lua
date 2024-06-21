local tbl = require("fzfx.commons.tbl")
local path = require("fzfx.commons.path")
local color_term = require("fzfx.commons.color.term")
local color_hl = require("fzfx.commons.color.hl")

local switches = require("fzfx.lib.switches")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels
local env = require("fzfx.lib.env")
local lsp = require("fzfx.lib.lsp")

local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local _lsp = require("fzfx.cfg._lsp")
local _decorator = require("fzfx.cfg._decorator")

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

local _, _, ERROR_TEXT_HL =
  color_hl.get_hl_with_fallback("DiagnosticSignError", "LspDiagnosticsSignError", "ErrorMsg")
local _, _, WARN_TEXT_HL =
  color_hl.get_hl_with_fallback("DiagnosticSignWarn", "LspDiagnosticsSignWarn", "WarningMsg")
local _, _, INFO_TEXT_HL =
  color_hl.get_hl_with_fallback("DiagnosticSignInfo", "LspDiagnosticsSignInfo", "None")
local _, _, HINT_TEXT_HL =
  color_hl.get_hl_with_fallback("DiagnosticSignHint", "LspDiagnosticsSignHint", "Comment")

--- @alias fzfx.LspDiagnosticSignDef {severity:integer,name:string,text:string,texthl:string,textcolor:string}
--- @type fzfx.LspDiagnosticSignDef[]
M._DEFAULT_LSP_DIAGNOSTIC_SIGNS = {
  -- 1 Error
  {
    severity = 1,
    name = "DiagnosticSignError",
    text = env.icon_enabled() and "" or "E", -- nf-fa-times \uf00d
    texthl = ERROR_TEXT_HL --[[@as string]],
    textcolor = "red",
  },
  -- 2 Warn
  {
    severity = 2,
    name = "DiagnosticSignWarn",
    text = env.icon_enabled() and "" or "W", -- nf-fa-warning \uf071
    texthl = WARN_TEXT_HL --[[@as string]],
    textcolor = "orange",
  },
  -- 3 Info
  {
    severity = 3,
    name = "DiagnosticSignInfo",
    text = env.icon_enabled() and "" or "I", -- nf-fa-info_circle \uf05a
    texthl = INFO_TEXT_HL --[[@as string]],
    textcolor = "cyan",
  },
  -- 4 Hint
  {
    severity = 4,
    name = "DiagnosticSignHint",
    text = env.icon_enabled() and "" or "H", -- nf-fa-bell \uf0f3
    texthl = HINT_TEXT_HL --[[@as string]],
    textcolor = "grey",
  },
}

-- Get already defined signs definition, or use default signs config.
--- @return fzfx.LspDiagnosticSignDef[]
M._make_signs = function()
  local results = {}
  for _, signs in ipairs(M._DEFAULT_LSP_DIAGNOSTIC_SIGNS) do
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

local DIAGNOSTIC_SIGNS = M._make_signs()

--- @param diag {bufnr:integer,lnum:integer,col:integer,message:string,severity:integer}
--- @return {bufnr:integer,filename:string,lnum:integer,col:integer,text:string,severity:integer}?
M._process_diag = function(diag)
  if not vim.api.nvim_buf_is_valid(diag.bufnr) then
    return nil
  end
  -- log.debug(string.format("|_process_diag| diag:%s", vim.inspect(diag)))
  local result = {
    bufnr = diag.bufnr,
    filename = path.reduce(vim.api.nvim_buf_get_name(diag.bufnr)),
    lnum = diag.lnum + 1,
    col = diag.col + 1,
    text = vim.trim(diag.message:gsub("\n", " ")),
    severity = diag.severity or 1,
  }
  -- log.debug(string.format("|_process_diag| result:%s", vim.inspect(result)))
  return result
end

-- Render a diagnostic item to a line for (the left side of) fzf binary.
-- The rendering format refers to the rg's query results.
-- Which looks like: "lua/fzfx/config.lua:10:13: Unused local `query`."
--- @param diag {bufnr:integer,filename:string,lnum:integer,col:integer,text:string,severity:integer}
--- @return string
M._render_diag_to_line = function(diag)
  -- log.debug(string.format("|_render_diag_to_line| diag:%s", vim.inspect(diag)))

  local msg = ""
  if type(diag.text) == "string" and string.len(diag.text) > 0 then
    local sign = DIAGNOSTIC_SIGNS[diag.severity]
    if tbl.tbl_not_empty(sign) then
      local color_renderer = color_term[sign.textcolor]
      msg = " " .. color_renderer(sign.text, sign.texthl)
    end
    msg = msg .. " " .. diag.text
  end
  -- log.debug(
  --   string.format(
  --     "|_make_lsp_diagnostics_provider| diag:%s, builder:%s",
  --     vim.inspect(diag),
  --     vim.inspect(builder)
  --   )
  -- )
  local rendered_line = string.format(
    "%s:%s:%s:%s",
    _lsp.LSP_FILENAME_COLOR(diag.filename),
    color_term.green(tostring(diag.lnum)),
    tostring(diag.col),
    msg
  )
  return rendered_line
end

--- @param opts {buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
M._make_provider = function(opts)
  local buffer_mode = tbl.tbl_get(opts, "buffer") or false

  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local lsp_clients = lsp.get_clients()
    if tbl.tbl_empty(lsp_clients) then
      log.echo(LogLevels.INFO, "no active lsp clients.")
      return nil
    end

    local diags = vim.diagnostic.get(buffer_mode and context.bufnr or nil)
    if tbl.tbl_empty(diags) then
      log.echo(LogLevels.INFO, "no diagnostics found.")
      return nil
    end
    -- Sort by severity: error > warn > info > hint
    table.sort(diags, function(a, b)
      return a.severity < b.severity
    end)

    local results = {}
    for _, item in ipairs(diags) do
      local processed_diag = M._process_diag(item)
      if processed_diag then
        local line = M._render_diag_to_line(processed_diag)
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
    provider = M._make_provider(),
    provider_type = ProviderTypeEnum.LIST,
    provider_decorator = { module = _decorator.PREPEND_ICON_GREP },
  },
  buffer_diagnostics = {
    key = "ctrl-u",
    provider = M._make_provider({ buffer = true }),
    provider_type = ProviderTypeEnum.LIST,
    provider_decorator = { module = _decorator.PREPEND_ICON_GREP },
  },
}

-- If you want to use fzf-builtin previewer with bat, please use below configs:
--
-- ```
-- previewer = previewers_helper.preview_files_grep
-- previewer_type = PreviewerTypeEnum.COMMAND_LIST
-- ```
--
-- If you want to use nvim buffer previewer, please use below configs:
--
-- ```
-- previewer = previewers_helper.buffer_preview_files_grep
-- previewer_type = PreviewerTypeEnum.BUFFER_FILE
-- ```

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
