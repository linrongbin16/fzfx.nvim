local tbl = require("fzfx.commons.tbl")
local path = require("fzfx.commons.path")
local fileio = require("fzfx.commons.fileio")
local term_color = require("fzfx.commons.color.term")

local switches = require("fzfx.lib.switches")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local providers_helper = require("fzfx.helper.providers")
local previewers_helper = require("fzfx.helper.previewers")

local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum

local M = {}

--- @alias fzfx.LspRangeStart {line:integer,character:integer}
--- @alias fzfx.LspRangeEnd {line:integer,character:integer}
--- @alias fzfx.LspRange {start:fzfx.LspRangeStart,end:fzfx.LspRangeEnd}
--- @alias fzfx.LspLocation {uri:string,range:fzfx.LspRange}
--- @alias fzfx.LspLocationLink {originSelectionRange:fzfx.LspRange,targetUri:string,targetRange:fzfx.LspRange,targetSelectionRange:fzfx.LspRange}

--- @param r fzfx.LspRange?
--- @return boolean
M._is_lsp_range = function(r)
  return type(tbl.tbl_get(r, "start", "line")) == "number"
    and type(tbl.tbl_get(r, "start", "character")) == "number"
    and type(tbl.tbl_get(r, "end", "line")) == "number"
    and type(tbl.tbl_get(r, "end", "character")) == "number"
end

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink|nil
M._is_lsp_location = function(loc)
  return type(tbl.tbl_get(loc, "uri")) == "string" and M._is_lsp_range(tbl.tbl_get(loc, "range"))
end

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink|nil
M._is_lsp_locationlink = function(loc)
  return type(tbl.tbl_get(loc, "targetUri")) == "string"
    and M._is_lsp_range(tbl.tbl_get(loc, "targetRange"))
end

--- @param line string
--- @param range fzfx.LspRange
--- @param renderer fun(text:string):string
--- @return string?
M._colorize_lsp_range = function(line, range, renderer)
  local line_start = range.start.character + 1
  local line_end = range["end"].line ~= range.start.line and #line
    or math.min(range["end"].character, #line)
  local p1 = ""
  if line_start > 1 then
    p1 = line:sub(1, line_start - 1)
  end
  local p2 = ""
  if line_start <= line_end then
    p2 = renderer(line:sub(line_start, line_end))
  end
  local p3 = ""
  if line_end + 1 <= #line then
    p3 = line:sub(line_end + 1, #line)
  end
  local result = p1 .. p2 .. p3
  return result
end

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink
--- @return string
M._hash_lsp_location = function(loc)
  local uri, range
  if M._is_lsp_location(loc) then
    uri = loc.uri
    range = loc.range
  elseif M._is_lsp_locationlink(loc) then
    uri = loc.targetUri
    range = loc.targetRange
  end
  local result = string.format(
    "%s-%s:%s-%s:%s",
    uri or "",
    tbl.tbl_get(range, "start", "line") or 0,
    tbl.tbl_get(range, "start", "character") or 0,
    tbl.tbl_get(range, "end", "line") or 0,
    tbl.tbl_get(range, "end", "character") or 0
  )
  log.debug(
    string.format("|_hash_lsp_location| loc:%s, hash:%s", vim.inspect(loc), vim.inspect(result))
  )
  return result
end

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink
--- @return string?
M._render_lsp_location_line = function(loc)
  -- log.debug("|_render_lsp_location_line| loc:%s", vim.inspect(loc))

  --- @type string
  local filename = nil
  --- @type fzfx.LspRange
  local range = nil

  if M._is_lsp_location(loc) then
    filename = path.reduce(vim.uri_to_fname(loc.uri))
    range = loc.range
    -- log.debug(
    --   "|_render_lsp_location_line| location filename:%s, range:%s",
    --   vim.inspect(filename),
    --   vim.inspect(range)
    -- )
  elseif M._is_lsp_locationlink(loc) then
    filename = path.reduce(vim.uri_to_fname(loc.targetUri))
    range = loc.targetRange
    -- log.debug(
    --   "|_render_lsp_location_line| locationlink filename:%s, range:%s",
    --   vim.inspect(filename),
    --   vim.inspect(range)
    -- )
  end
  if not M._is_lsp_range(range) then
    return nil
  end
  filename = vim.fn.expand(filename)
  if type(filename) ~= "string" or vim.fn.filereadable(filename) <= 0 then
    return nil
  end
  local filelines = fileio.readlines(filename)
  if type(filelines) ~= "table" or #filelines < range.start.line + 1 then
    return nil
  end
  local loc_line = M._colorize_lsp_range(filelines[range.start.line + 1], range, term_color.red)
  -- log.debug(
  --   "|_render_lsp_location_line| range:%s, loc_line:%s",
  --   vim.inspect(range),
  --   vim.inspect(loc_line)
  -- )
  local line = string.format(
    "%s:%s:%s:%s",
    providers_helper.LSP_FILENAME_COLOR(vim.fn.fnamemodify(filename, ":~:.")),
    term_color.green(tostring(range.start.line + 1)),
    tostring(range.start.character + 1),
    loc_line
  )
  -- log.debug(
  --   "|fzfx.config - _render_lsp_location_line| line:%s",
  --   vim.inspect(line)
  -- )
  return line
end

-- locations {

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
    if tbl.tbl_empty(lsp_clients) then
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
      log.echo(LogLevels.INFO, vim.inspect(opts.method) .. " not supported.")
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
    if tbl.tbl_empty(response) then
      log.echo(LogLevels.INFO, "no lsp locations found.")
      return nil
    end

    local visited_locations = {}
    local results = {}
    for client_id, client_response in
      pairs(response --[[@as table]])
    do
      if client_id ~= nil and tbl.tbl_not_empty(tbl.tbl_get(client_response, "result")) then
        local lsp_loc = client_response.result
        if M._is_lsp_location(lsp_loc) then
          local loc_hash = M._hash_lsp_location(lsp_loc)
          if visited_locations[loc_hash] == nil then
            visited_locations[loc_hash] = true
            local line = M._render_lsp_location_line(lsp_loc)
            if type(line) == "string" and string.len(line) > 0 then
              table.insert(results, line)
            end
          end
        else
          for _, loc in ipairs(lsp_loc) do
            local loc_hash = M._hash_lsp_location(loc)
            if visited_locations[loc_hash] == nil then
              visited_locations[loc_hash] = true
              local line = M._render_lsp_location_line(loc)
              if type(line) == "string" and string.len(line) > 0 then
                table.insert(results, line)
              end
            end
          end
        end
      end
    end

    if tbl.tbl_empty(results) then
      log.echo(LogLevels.INFO, "no lsp locations found.")
      return nil
    end

    return results
  end
  return impl
end

-- locations }

-- call hierarchy {

--- @alias fzfx.LspCallHierarchyItem {name:string,kind:integer,detail:string?,uri:string,range:fzfx.LspRange,selectionRange:fzfx.LspRange}
--- @alias fzfx.LspCallHierarchyIncomingCall {from:fzfx.LspCallHierarchyItem,fromRanges:fzfx.LspRange[]}
--- @alias fzfx.LspCallHierarchyOutgoingCall {to:fzfx.LspCallHierarchyItem,fromRanges:fzfx.LspRange[]}

--- @param item fzfx.LspCallHierarchyItem?
--- @return boolean
M._is_lsp_call_hierarchy_item = function(item)
  -- log.debug(
  --   "|fzfx.config - _is_lsp_call_hierarchy_item| item:%s",
  --   vim.inspect(item)
  -- )
  return type(item) == "table"
    and type(item.name) == "string"
    and string.len(item.name) > 0
    and (item.kind ~= nil)
    and (item.detail == nil or type(item.detail) == "string")
    and type(item.uri) == "string"
    and string.len(item.uri) > 0
    and M._is_lsp_range(item.range)
    and M._is_lsp_range(item.selectionRange)
end

--- @param method string
--- @param call_item fzfx.Options?
--- @return boolean
M._is_lsp_call_hierarchy_incoming_call = function(method, call_item)
  return method == "callHierarchy/incomingCalls"
    and type(call_item) == "table"
    and M._is_lsp_call_hierarchy_item(call_item.from)
    and type(call_item.fromRanges) == "table"
end

--- @param method string
--- @param call_item fzfx.Options?
--- @return boolean
M._is_lsp_call_hierarchy_outgoing_call = function(method, call_item)
  return method == "callHierarchy/outgoingCalls"
    and type(call_item) == "table"
    and M._is_lsp_call_hierarchy_item(call_item.to)
    and type(call_item.fromRanges) == "table"
end

--- @param item fzfx.LspCallHierarchyItem
--- @param ranges fzfx.LspRange[]
--- @return string[]
M._render_lsp_call_hierarchy_line = function(item, ranges)
  log.debug(
    string.format(
      "|_render_lsp_call_hierarchy_line| item:%s, ranges:%s",
      vim.inspect(item),
      vim.inspect(ranges)
    )
  )
  local filename = nil
  if type(item.uri) == "string" and string.len(item.uri) > 0 and M._is_lsp_range(item.range) then
    filename = path.reduce(vim.uri_to_fname(item.uri))
    log.debug("|_render_lsp_call_hierarchy_line| location filename: " .. vim.inspect(filename))
  end
  if type(ranges) ~= "table" or #ranges == 0 then
    return {}
  end
  if type(filename) ~= "string" or vim.fn.filereadable(filename) <= 0 then
    return {}
  end
  local filelines = fileio.readlines(filename)
  if type(filelines) ~= "table" then
    return {}
  end
  local lines = {}
  for i, r in ipairs(ranges) do
    local item_line = M._colorize_lsp_range(filelines[r.start.line + 1], r, term_color.red)
    log.debug(
      string.format(
        "|_render_lsp_call_hierarchy_line| %s-range:%s, item_line:%s",
        vim.inspect(i),
        vim.inspect(r),
        vim.inspect(item_line)
      )
    )
    local line = string.format(
      "%s:%s:%s:%s",
      providers_helper.LSP_FILENAME_COLOR(vim.fn.fnamemodify(filename, ":~:.")),
      term_color.green(tostring(r.start.line + 1)),
      tostring(r.start.character + 1),
      item_line
    )
    log.debug(
      string.format(
        "|_render_lsp_call_hierarchy_line| %s-line:%s",
        vim.inspect(i),
        vim.inspect(line)
      )
    )
    table.insert(lines, line)
  end
  return lines
end

--- @param method fzfx.LspMethod
--- @param hi_item fzfx.LspCallHierarchyIncomingCall|fzfx.LspCallHierarchyOutgoingCall
--- @return fzfx.LspCallHierarchyItem?, fzfx.LspRange[]|nil
M._retrieve_lsp_call_hierarchy_item_and_from_ranges = function(method, hi_item)
  if M._is_lsp_call_hierarchy_incoming_call(method, hi_item) then
    return hi_item.from, hi_item.fromRanges
  elseif M._is_lsp_call_hierarchy_outgoing_call(method, hi_item) then
    return hi_item.to, hi_item.fromRanges
  else
    return nil, nil
  end
end

-- incoming calls test: https://github.com/neovide/neovide/blob/59e4ed47e72076bc8cec09f11d73c389624b19fc/src/main.rs#L266
--- @param opts {method:fzfx.LspMethod,capability:fzfx.LspServerCapability,timeout:integer?}
--- @return fun(query:string,context:fzfx.LspLocationPipelineContext):string[]|nil
M._make_lsp_call_hierarchy_provider = function(opts)
  --- @param query string
  --- @param context fzfx.LspLocationPipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    ---@diagnostic disable-next-line: deprecated
    local lsp_clients = vim.lsp.get_active_clients({ bufnr = context.bufnr })
    if tbl.tbl_empty(lsp_clients) then
      log.echo(LogLevels.INFO, "no active lsp clients.")
      return nil
    end
    -- log.debug(
    --   "|fzfx.config - _make_lsp_locations_provider| lsp_clients:%s",
    --   vim.inspect(lsp_clients)
    -- )
    local method_supported = false
    for _, lsp_client in ipairs(lsp_clients) do
      if lsp_client.server_capabilities[opts.capability] then
        method_supported = true
        break
      end
    end
    if not method_supported then
      log.echo(LogLevels.INFO, vim.inspect(opts.method) .. " not supported.")
      return nil
    end
    local lsp_results, lsp_err = vim.lsp.buf_request_sync(
      context.bufnr,
      "textDocument/prepareCallHierarchy",
      context.position_params,
      opts.timeout or 3000
    )
    log.debug(
      string.format(
        "|_make_lsp_call_hierarchy_provider| prepare, opts:%s, lsp_results:%s, lsp_err:%s",
        vim.inspect(opts),
        vim.inspect(lsp_results),
        vim.inspect(lsp_err)
      )
    )
    if lsp_err then
      log.echo(LogLevels.ERROR, lsp_err)
      return nil
    end
    if type(lsp_results) ~= "table" then
      log.echo(LogLevels.INFO, "no lsp call hierarchy found.")
      return nil
    end

    local lsp_item = nil
    for client_id, lsp_result in pairs(lsp_results) do
      if
        client_id ~= nil
        and type(lsp_result) == "table"
        and type(lsp_result.result) == "table"
      then
        lsp_item = lsp_result.result
        break
      end
    end
    if lsp_item == nil or #lsp_item == 0 then
      log.echo(LogLevels.INFO, "no lsp call hierarchy found.")
      return nil
    end

    local results = {}
    local lsp_results2, lsp_err2 = vim.lsp.buf_request_sync(
      context.bufnr,
      opts.method,
      { item = lsp_item[1] },
      opts.timeout or 3000
    )
    log.debug(
      string.format(
        "|_make_lsp_call_hierarchy_provider| 2nd call, opts:%s, lsp_item: %s, lsp_results2:%s, lsp_err2:%s",
        vim.inspect(opts),
        vim.inspect(lsp_item),
        vim.inspect(lsp_results2),
        vim.inspect(lsp_err2)
      )
    )
    if lsp_err2 then
      log.echo(LogLevels.ERROR, lsp_err2)
      return nil
    end
    if type(lsp_results2) ~= "table" then
      log.echo(LogLevels.INFO, "no lsp locations found.")
      return nil
    end
    for client_id, lsp_result in pairs(lsp_results2) do
      if
        client_id ~= nil
        and type(lsp_result) == "table"
        and type(lsp_result.result) == "table"
      then
        local lsp_hi_item_list = lsp_result.result
        log.debug(
          string.format(
            "|_make_lsp_call_hierarchy_provider| method:%s, lsp_hi_item_list:%s",
            vim.inspect(opts.method),
            vim.inspect(lsp_hi_item_list)
          )
        )
        for _, lsp_hi_item in ipairs(lsp_hi_item_list) do
          local hi_item, from_ranges =
            M._retrieve_lsp_call_hierarchy_item_and_from_ranges(opts.method, lsp_hi_item)
          log.debug(
            string.format(
              "|_make_lsp_call_hierarchy_provider| method:%s, lsp_hi_item:%s, hi_item:%s, from_ranges:%s",
              vim.inspect(opts.method),
              vim.inspect(lsp_hi_item_list),
              vim.inspect(hi_item),
              vim.inspect(from_ranges)
            )
          )
          if M._is_lsp_call_hierarchy_item(hi_item) and type(from_ranges) == "table" then
            local lines = M._render_lsp_call_hierarchy_line(
              hi_item --[[@as fzfx.LspCallHierarchyItem]],
              from_ranges
            )
            if type(lines) == "table" then
              for _, line in ipairs(lines) do
                if type(line) == "string" and string.len(line) > 0 then
                  table.insert(results, line)
                end
              end
            end
          end
        end
      end
    end

    if tbl.tbl_empty(results) then
      log.echo(LogLevels.INFO, "no lsp call hierarchy found.")
      return nil
    end

    return results
  end
  return impl
end

-- call hierarchy }

--- @alias fzfx.LspLocationPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,position_params:any}
--- @return fzfx.LspLocationPipelineContext
M._lsp_position_context_maker = function()
  local context = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  context.position_params = vim.lsp.util.make_position_params(context.winnr, nil)
  context.position_params.context = {
    includeDeclaration = true,
  }
  return context
end

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
  previewer = previewer,
  previewer_type = previewer_type,
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
}

M.other_opts = {
  context_maker = M._lsp_position_context_maker,
}

return M
