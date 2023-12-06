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

local contexts_helper = require("fzfx.helper.contexts")
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

--- @alias fzfx.LspRangeStart {line:integer,character:integer}
--- @alias fzfx.LspRangeEnd {line:integer,character:integer}
--- @alias fzfx.LspRange {start:fzfx.LspRangeStart,end:fzfx.LspRangeEnd}
--- @alias fzfx.LspLocation {uri:string,range:fzfx.LspRange}
--- @alias fzfx.LspLocationLink {originSelectionRange:fzfx.LspRange,targetUri:string,targetRange:fzfx.LspRange,targetSelectionRange:fzfx.LspRange}

--- @param r fzfx.LspRange?
--- @return boolean
M._is_lsp_range = function(r)
  return type(r) == "table"
    and type(r.start) == "table"
    and type(r.start.line) == "number"
    and type(r.start.character) == "number"
    and type(r["end"]) == "table"
    and type(r["end"].line) == "number"
    and type(r["end"].character) == "number"
end

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink|nil
M._is_lsp_location = function(loc)
  return type(loc) == "table"
    and type(loc.uri) == "string"
    and M._is_lsp_range(loc.range)
end

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink|nil
M._is_lsp_locationlink = function(loc)
  return type(loc) == "table"
    and type(loc.targetUri) == "string"
    and M._is_lsp_range(loc.targetRange)
end

--- @param line string
--- @param range fzfx.LspRange
--- @param color_renderer fun(text:string):string
--- @return string?
M._colorize_lsp_range = function(line, range, color_renderer)
  -- log.debug(
  --   "|fzfx.config - _lsp_location_render_line| range:%s, line:%s",
  --   vim.inspect(range),
  --   vim.inspect(line)
  -- )
  local line_start = range.start.character + 1
  local line_end = range["end"].line ~= range.start.line and #line
    or math.min(range["end"].character, #line)
  local p1 = ""
  if line_start > 1 then
    p1 = line:sub(1, line_start - 1)
  end
  local p2 = ""
  if line_start <= line_end then
    p2 = color_renderer(line:sub(line_start, line_end))
  end
  local p3 = ""
  if line_end + 1 <= #line then
    p3 = line:sub(line_end + 1, #line)
  end
  local result = p1 .. p2 .. p3
  return result
end

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink
--- @return string?
M._render_lsp_location_line = function(loc)
  log.debug(
    "|fzfx.config - _render_lsp_location_line| loc:%s",
    vim.inspect(loc)
  )
  local filename = nil
  --- @type fzfx.LspRange
  local range = nil
  if M._is_lsp_location(loc) then
    filename = paths.reduce(vim.uri_to_fname(loc.uri))
    range = loc.range
    log.debug(
      "|fzfx.config - _render_lsp_location_line| location filename:%s, range:%s",
      vim.inspect(filename),
      vim.inspect(range)
    )
  elseif M._is_lsp_locationlink(loc) then
    filename = paths.reduce(vim.uri_to_fname(loc.targetUri))
    range = loc.targetRange
    log.debug(
      "|fzfx.config - _render_lsp_location_line| locationlink filename:%s, range:%s",
      vim.inspect(filename),
      vim.inspect(range)
    )
  end
  if not M._is_lsp_range(range) then
    return nil
  end
  if type(filename) ~= "string" or vim.fn.filereadable(filename) <= 0 then
    return nil
  end
  local filelines = fs.readlines(filename)
  if type(filelines) ~= "table" or #filelines < range.start.line + 1 then
    return nil
  end
  local loc_line =
    M._colorize_lsp_range(filelines[range.start.line + 1], range, colors.red)
  log.debug(
    "|fzfx.config - _render_lsp_location_line| range:%s, loc_line:%s",
    vim.inspect(range),
    vim.inspect(loc_line)
  )
  local line = string.format(
    "%s:%s:%s:%s",
    providers_helper.LSP_FILENAME_COLOR(vim.fn.fnamemodify(filename, ":~:.")),
    colors.green(tostring(range.start.line + 1)),
    tostring(range.start.character + 1),
    loc_line
  )
  -- log.debug(
  --   "|fzfx.config - _render_lsp_location_line| line:%s",
  --   vim.inspect(line)
  -- )
  return line
end

-- lsp methods: https://github.com/neovim/neovim/blob/dc9f7b814517045b5354364655f660aae0989710/runtime/lua/vim/lsp/protocol.lua#L1028
-- lsp capabilities: https://github.com/neovim/neovim/blob/dc9f7b814517045b5354364655f660aae0989710/runtime/lua/vim/lsp.lua#L39
--
--- @alias fzfx.LspMethod "textDocument/definition"|"textDocument/type_definition"|"textDocument/references"|"textDocument/implementation"|"callHierarchy/incomingCalls"|"callHierarchy/outgoingCalls"|"textDocument/prepareCallHierarchy"
--- @alias fzfx.LspServerCapability "definitionProvider"|"typeDefinitionProvider"|"referencesProvider"|"implementationProvider"|"callHierarchyProvider"
---
--- @param opts {method:fzfx.LspMethod,capability:fzfx.LspServerCapability,timeout:integer?}
--- @return fun(query:string,context:fzfx.LspLocationPipelineContext):string[]|nil
M._make_lsp_locations_provider = function(opts)
  --- @param query string
  --- @param context fzfx.LspLocationPipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local lsp_clients = vim.lsp.get_active_clients({ bufnr = context.bufnr })
    if tbls.tbl_empty(lsp_clients) then
      log.echo(LogLevels.INFO, "no active lsp clients.")
      return nil
    end
    -- log.debug(
    --   "|fzfx.config - _make_lsp_locations_provider| lsp_clients:%s",
    --   vim.inspect(lsp_clients)
    -- )
    local supported = false
    for _, lsp_client in ipairs(lsp_clients) do
      if lsp_client.server_capabilities[opts.capability] then
        supported = true
        break
      end
    end
    if not supported then
      log.echo(LogLevels.INFO, "%s not supported.", vim.inspect(opts.method))
      return nil
    end
    local response, err = vim.lsp.buf_request_sync(
      context.bufnr,
      opts.method,
      context.position_params,
      opts.timeout or 3000
    )
    -- log.debug(
    --   "|fzfx.config - _make_lsp_locations_provider| opts:%s, lsp_results:%s, lsp_err:%s",
    --   vim.inspect(opts),
    --   vim.inspect(response),
    --   vim.inspect(err)
    -- )
    if err then
      log.echo(LogLevels.ERROR, err)
      return nil
    end
    if tbls.tbl_empty(response) then
      log.echo(LogLevels.INFO, "no lsp locations found.")
      return nil
    end

    local results = {}
    for client_id, client_response in
      pairs(response --[[@as table]])
    do
      if
        client_id ~= nil
        and tbls.tbl_not_empty(tbls.tbl_get(client_response, "result"))
      then
        local lsp_loc = client_response.result
        if M._is_lsp_location(lsp_loc) then
          local line = M._render_lsp_location_line(lsp_loc)
          if type(line) == "string" and string.len(line) > 0 then
            table.insert(results, line)
          end
        else
          for _, loc in ipairs(lsp_loc) do
            local line = M._render_lsp_location_line(loc)
            if type(line) == "string" and string.len(line) > 0 then
              table.insert(results, line)
            end
          end
        end
      end
    end

    if tbls.tbl_empty(results) then
      log.echo(LogLevels.INFO, "no lsp locations found.")
      return nil
    end

    return results
  end
  return impl
end

--- @alias fzfx.LspLocationPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,position_params:any}
--- @return fzfx.LspLocationPipelineContext
M._lsp_position_context_maker = function()
  local context = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  context.position_params =
    vim.lsp.util.make_position_params(context.winnr, nil)
  context.position_params.context = {
    includeDeclaration = true,
  }
  return context
end

M.previewers = {
  previewer = previewers_helper.preview_files_grep,
  previewer_type = PreviewerTypeEnum.COMMAND_LIST,
  previewer_label = labels_helper.label_rg,
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.edit_rg,
  ["double-click"] = actions_helper.edit_rg,
}

M.win_opts = {
  relative = "cursor",
  height = 0.45,
  width = 1,
  row = 1,
  col = 0,
  border = "none",
  zindex = 51,
}

M.other_opts = {
  context_maker = M._lsp_position_context_maker,
}

return M
