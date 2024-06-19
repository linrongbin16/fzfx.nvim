local tbl = require("fzfx.commons.tbl")
local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")
local fileio = require("fzfx.commons.fileio")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local LogLevels = require("fzfx.lib.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")
local previewers_helper = require("fzfx.helper.previewers")

local ProviderTypeEnum = require("fzfx.schema").ProviderTypeEnum
local PreviewerTypeEnum = require("fzfx.schema").PreviewerTypeEnum
local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum

local M = {}

M.command = {
  name = "FzfxCommands",
  desc = "Search commands",
}

M.variants = {
  -- args
  {
    name = "args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "all_commands",
  },
  {
    name = "ex_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "ex_commands",
  },
  {
    name = "user_args",
    feed = CommandFeedEnum.ARGS,
    default_provider = "user_commands",
  },
  -- visual
  {
    name = "visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "all_commands",
  },
  {
    name = "ex_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "ex_commands",
  },
  {
    name = "user_visual",
    feed = CommandFeedEnum.VISUAL,
    default_provider = "uesr_commands",
  },
  -- cword
  {
    name = "cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "all_commands",
  },
  {
    name = "ex_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "ex_commands",
  },
  {
    name = "user_cword",
    feed = CommandFeedEnum.CWORD,
    default_provider = "user_commands",
  },
  -- put
  {
    name = "put",
    feed = CommandFeedEnum.PUT,
    default_provider = "all_commands",
  },
  {
    name = "ex_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "ex_commands",
  },
  {
    name = "user_put",
    feed = CommandFeedEnum.PUT,
    default_provider = "user_commands",
  },
  -- resume
  {
    name = "resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "all_commands",
  },
  {
    name = "ex_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "ex_commands",
  },
  {
    name = "user_resume",
    feed = CommandFeedEnum.RESUME,
    default_provider = "user_commands",
  },
}

-- Parse EX commands from vim documents, returns the EX command name.
--- @param line string
--- @return string
M._parse_ex_command_name = function(line)
  local stop = str.find(line, "|", 3)
  return str.trim(line:sub(3, stop - 1))
end

--- @return table<string, fzfx.VimCommand>
M._get_vim_ex_commands = function()
  local help_docs_list =
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.fn.globpath(vim.env.VIMRUNTIME, "doc/index.txt", 0, 1) --[[@as table]]
  log.debug(string.format("|_get_vim_ex_commands| help docs:%s", vim.inspect(help_docs_list)))
  if tbl.tbl_empty(help_docs_list) then
    log.echo(LogLevels.INFO, "no 'doc/index.txt' found.")
    return {}
  end
  local results = {}
  for _, help_doc in ipairs(help_docs_list) do
    local lines = fileio.readlines(help_doc) --[[@as table]]
    for i = 1, #lines do
      local line = lines[i]
      if str.startswith(line, "|:") then
        log.debug(string.format("|_get_vim_ex_commands| line[%d]:%s", i, vim.inspect(line)))
        local name = M._parse_ex_command_name(line)
        if type(name) == "string" and string.len(name) > 0 then
          results[name] = {
            name = name,
            loc = {
              filename = path.reduce2home(help_doc),
              lineno = i,
            },
          }
        end
      end
      i = i + 1
    end
  end
  log.debug(string.format("|_get_vim_ex_commands| results:%s", vim.inspect(results)))
  return results
end

--- @param header string
--- @return boolean
M._is_ex_command_output_header = function(header)
  local name_pos = str.find(header, "Name")
  local args_pos = str.find(header, "Args")
  local address_pos = str.find(header, "Address")
  local complete_pos = str.find(header, "Complete")
  local definition_pos = str.find(header, "Definition")
  return type(name_pos) == "number"
    and type(args_pos) == "number"
    and type(address_pos) == "number"
    and type(complete_pos) == "number"
    and type(definition_pos) == "number"
    and name_pos < args_pos
    and args_pos < address_pos
    and address_pos < complete_pos
    and complete_pos < definition_pos
end

--- @param line string
--- @param start_pos integer
--- @return {filename:string,lineno:integer}?
M._parse_ex_command_output_lua_function_definition = function(line, start_pos)
  log.debug(
    string.format(
      "|_parse_ex_command_output_lua_function_definition| line:%s, start_pos:%s",
      vim.inspect(line),
      vim.inspect(start_pos)
    )
  )
  local lua_flag = "<Lua "
  local lua_function_flag = "<Lua function>"
  local lua_function_pos = str.find(line, lua_function_flag, start_pos)
  if lua_function_pos then
    start_pos = str.find(line, lua_flag, lua_function_pos + string.len(lua_function_flag)) --[[@as integer]]
  else
    start_pos = str.find(line, lua_flag, start_pos) --[[@as integer]]
  end
  if start_pos == nil then
    return nil
  end
  local first_colon_pos = str.find(line, ":", start_pos)
  local content = vim.trim(line:sub(first_colon_pos + 1))
  if string.len(content) > 0 and content:sub(#content) == ">" then
    content = content:sub(1, #content - 1)
  end
  log.debug(
    string.format(
      "|_parse_ex_command_output_lua_function_definition| content-2:%s",
      vim.inspect(content)
    )
  )
  local content_splits = str.split(content, ":")
  log.debug(
    string.format(
      "|_parse_ex_command_output_lua_function_definition| split content:%s",
      vim.inspect(content_splits)
    )
  )
  return {
    filename = vim.fn.expand(content_splits[1]),
    lineno = tonumber(content_splits[2]),
  }
end

--- @alias fzfx.VimExCommandOutputHeader {name_pos:integer,args_pos:integer,address_pos:integer,complete_pos:integer,definition_pos:integer}
--- @param header string
--- @return fzfx.VimExCommandOutputHeader
M._parse_ex_command_output_header = function(header)
  local name_pos = str.find(header, "Name")
  local args_pos = str.find(header, "Args")
  local address_pos = str.find(header, "Address")
  local complete_pos = str.find(header, "Complete")
  local definition_pos = str.find(header, "Definition")
  return {
    name_pos = name_pos,
    args_pos = args_pos,
    address_pos = address_pos,
    complete_pos = complete_pos,
    definition_pos = definition_pos,
  }
end

-- the ':command' output looks like:
--
--```
--    Name              Args Address Complete    Definition
--    Barbecue          ?            <Lua function> <Lua 437: ~/.config/nvim/lazy/barbecue/lua/barbecue.lua:18>
--                                               Run subcommands through this general command
--!   Bdelete           ?            buffer      :call s:bdelete("bdelete", <q-bang>, <q-args>)
--    BufferLineCloseLeft 0                      <Lua 329: ~/.config/nvim/lazy/bufferline.nvim/lua/bufferline.lua:226>
--    BufferLineCloseRight 0                     <Lua 328: ~/.config/nvim/lazy/bufferline.nvim/lua/bufferline.lua:225>
--!   Bwipeout          ?            buffer      :call s:bdelete("bwipeout", <q-bang>, <q-args>)
--    DoMatchParen      0                        call matchup#matchparen#toggle(1)
--!|  Explore           *    0c ?    dir         call netrw#Explore(<count>,0,0+<bang>0,<q-args>)
--!   FZF               *            dir         call s:cmd(<bang>0, <f-args>)
--!   FzfxBuffers       ?            file        <Lua 744: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               Find buffers
--!   FzfxBuffersP      0                        <Lua 742: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               Find buffers by yank text
--!   FzfxBuffersV      0    .                   <Lua 358: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               Find buffers by visual select
--!   FzfxBuffersW      0                        <Lua 861: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               Find buffers by cursor word
--!   FzfxFileExplorer  ?            dir         <Lua 845: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               File explorer (ls -l)
--!   FzfxFileExplorerP 0                        <Lua 839: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               File explorer (ls -l) by yank text
--!   FzfxFileExplorerU ?            dir         <Lua 844: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               File explorer (ls -la)
--!   FzfxFileExplorerUP 0                       <Lua 838: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               File explorer (ls -la) by yank text
--!   FzfxFileExplorerUV 0   .                   <Lua 842: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               File explorer (ls -la) by visual select
--!   FzfxFileExplorerUW 0                       <Lua 840: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>
--                                               File explorer (ls -la) by cursor word
--```
--- @return table<string, {filename:string,lineno:integer}>
M._parse_ex_command_output = function()
  local tmpfile = vim.fn.tempname()
  vim.cmd(string.format(
    [[
    redir! > %s
    silent command
    redir END
    ]],
    tmpfile
  ))

  local results = {}
  local command_outputs = fileio.readlines(tmpfile --[[@as string]]) --[[@as table]]
  local found_command_output_header = false
  --- @type fzfx.VimExCommandOutputHeader
  local parsed_header = nil

  for i = 1, #command_outputs do
    local line = command_outputs[i]

    if found_command_output_header then
      -- parse command name, e.g., FzfxCommands, etc.
      local idx = parsed_header.name_pos
      log.debug(
        string.format("|_parse_ex_command_output| line[%d]:%s(%d)", i, vim.inspect(line), idx)
      )
      while idx <= #line and not str.isspace(line:sub(idx, idx)) do
        -- log.debug(
        --     "|fzfx.config - _parse_ex_command_output| parse non-spaces, idx:%d, char:%s(%s)",
        --     idx,
        --     vim.inspect(line:sub(idx, idx)),
        --     vim.inspect(string.len(line:sub(idx, idx)))
        -- )
        -- log.debug(
        --     "|fzfx.config - _parse_ex_command_output| parse non-spaces, isspace:%s",
        --     vim.inspect(strs.isspace(line:sub(idx, idx)))
        -- )
        if str.isspace(line:sub(idx, idx)) then
          break
        end
        idx = idx + 1
      end
      local name = vim.trim(line:sub(parsed_header.name_pos, idx))

      idx = math.max(parsed_header.definition_pos, idx)
      local parsed_line = M._parse_ex_command_output_lua_function_definition(line, idx)
      if parsed_line then
        results[name] = {
          filename = parsed_line.filename,
          lineno = parsed_line.lineno,
        }
      end
    end

    if M._is_ex_command_output_header(line) then
      found_command_output_header = true
      parsed_header = M._parse_ex_command_output_header(line)
      log.debug(
        string.format("|_parse_ex_command_output| parsed header:%s", vim.inspect(parsed_header))
      )
    end
  end

  return results
end

--- @return table<string, fzfx.VimCommand>
M._get_vim_user_commands = function()
  local parsed_ex_commands = M._parse_ex_command_output()
  local user_commands = vim.api.nvim_get_commands({ builtin = false })
  log.debug(string.format("|_get_vim_user_commands| user commands:%s", vim.inspect(user_commands)))

  local results = {}
  for name, opts in pairs(user_commands) do
    if type(opts) == "table" and opts.name == name then
      results[name] = {
        name = opts.name,
        opts = {
          bang = opts.bang,
          bar = opts.bar,
          range = opts.range,
          complete = opts.complete,
          complete_arg = opts.complete_arg,
          desc = opts.definition,
          nargs = opts.nargs,
        },
      }
      local parsed = parsed_ex_commands[name]
      if parsed then
        results[name].loc = {
          filename = parsed.filename,
          lineno = parsed.lineno,
        }
      end
    end
  end
  return results
end

--- @param vc fzfx.VimCommand
--- @return string
M._render_vim_commands_column_opts = function(vc)
  local bang = (type(vc.opts) == "table" and vc.opts.bang) and "Y" or "N"
  local bar = (type(vc.opts) == "table" and vc.opts.bar) and "Y" or "N"
  local nargs = (type(vc.opts) == "table" and vc.opts.nargs) and vc.opts.nargs or "N/A"
  local range = (type(vc.opts) == "table" and vc.opts.range) and vc.opts.range or "N/A"
  local complete = (type(vc.opts) == "table" and vc.opts.complete)
      and (vc.opts.complete == "<Lua function>" and "<Lua>" or vc.opts.complete)
    or "N/A"

  return string.format("%-4s|%-3s|%-5s|%-5s|%s", bang, bar, nargs, range, complete)
end

--- @param commands fzfx.VimCommand[]
--- @param name_width integer
--- @param opts_width integer
--- @return string[]
M._render_vim_commands = function(commands, name_width, opts_width)
  --- @param r fzfx.VimCommand
  --- @return string
  local function rendered_desc_or_loc(r)
    if
      type(r.loc) == "table"
      and type(r.loc.filename) == "string"
      and type(r.loc.lineno) == "number"
    then
      return string.format("%s:%d", path.reduce(r.loc.filename), r.loc.lineno)
    else
      return (type(r.opts) == "table" and type(r.opts.desc) == "string")
          and string.format('"%s"', r.opts.desc)
        or ""
    end
  end

  local NAME = "Name"
  local OPTS = "Bang|Bar|Nargs|Range|Complete"
  local DEF_OR_LOC = "Definition/Location"

  local results = {}
  local formatter = "%-"
    .. tostring(name_width)
    .. "s"
    .. " "
    .. "%-"
    .. tostring(opts_width)
    .. "s %s"
  local header = string.format(formatter, NAME, OPTS, DEF_OR_LOC)
  table.insert(results, header)
  log.debug(
    string.format(
      "|_render_vim_commands| formatter:%s, header:%s",
      vim.inspect(formatter),
      vim.inspect(header)
    )
  )
  for i, c in ipairs(commands) do
    local rendered = string.format(
      formatter,
      c.name,
      M._render_vim_commands_column_opts(c),
      rendered_desc_or_loc(c)
    )
    log.debug(string.format("|_render_vim_commands| rendered[%d]:%s", i, vim.inspect(rendered)))
    table.insert(results, rendered)
  end
  return results
end

--- @alias fzfx.VimCommandLocation {filename:string,lineno:integer}
--- @alias fzfx.VimCommandOptions {bang:boolean?,bar:boolean?,nargs:string?,range:string?,complete:string?,complete_arg:string?,desc:string?}
--- @alias fzfx.VimCommand {name:string,loc:fzfx.VimCommandLocation?,opts:fzfx.VimCommandOptions}
--- @param opts {ex_commands:boolean?,user_commands:boolean?}?
--- @return fzfx.VimCommand[]
M._get_vim_commands = function(opts)
  local results = {}

  if tbl.tbl_get(opts, "ex_commands") then
    local tmp = M._get_vim_ex_commands()
    for _, c in pairs(tmp) do
      table.insert(results, c)
    end
  end
  if tbl.tbl_get(opts, "user_commands") then
    local tmp = M._get_vim_user_commands()
    for _, c in pairs(tmp) do
      table.insert(results, c)
    end
  end

  table.sort(results, function(a, b)
    return a.name < b.name
  end)

  return results
end

--- @param query string
--- @param context fzfx.VimCommandsPipelineContext
--- @return string[]
local function vim_commands_provider(query, context)
  local commands = M._get_vim_commands({ ex_commands = true, user_commands = true })
  return M._render_vim_commands(commands, context.name_width, context.opts_width)
end

--- @param query string
--- @param context fzfx.VimCommandsPipelineContext
--- @return string[]
local function vim_ex_commands_provider(query, context)
  local commands = M._get_vim_commands({ ex_commands = true })
  return M._render_vim_commands(commands, context.name_width, context.opts_width)
end

--- @param query string
--- @param context fzfx.VimCommandsPipelineContext
--- @return string[]
local function vim_user_commands_provider(query, context)
  local commands = M._get_vim_commands({ user_commands = true })
  return M._render_vim_commands(commands, context.name_width, context.opts_width)
end

M.providers = {
  all_commands = {
    key = "ctrl-a",
    provider = vim_commands_provider,
    provider_type = ProviderTypeEnum.LIST,
  },
  ex_commands = {
    key = "ctrl-e",
    provider = vim_ex_commands_provider,
    provider_type = ProviderTypeEnum.LIST,
  },
  user_commands = {
    key = "ctrl-u",
    provider = vim_user_commands_provider,
    provider_type = ProviderTypeEnum.LIST,
  },
}

--- @param line string
--- @param context fzfx.VimCommandsPipelineContext
--- @return string[]|nil
M._vim_commands_previewer = function(line, context)
  local parsed = parsers_helper.parse_vim_command(line, context)
  -- log.debug(
  --   "|fzfx.config - _vim_commands_previewer| line:%s, context:%s, parsed:%s",
  --   vim.inspect(line),
  --   vim.inspect(context),
  --   vim.inspect(parsed)
  -- )
  if
    tbl.tbl_not_empty(parsed)
    and str.not_empty(parsed.filename)
    and type(parsed.lineno) == "number"
  then
    -- log.debug(
    --   "|fzfx.config - _vim_commands_previewer| loc:%s",
    --   vim.inspect(parsed)
    -- )
    return previewers_helper.preview_files_with_line_range(parsed.filename, parsed.lineno)
  elseif constants.HAS_ECHO and tbl.tbl_not_empty(parsed) then
    -- log.debug(
    --   "|fzfx.config - _vim_commands_previewer| desc:%s",
    --   vim.inspect(parsed)
    -- )
    return { "echo", parsed.definition or "" }
  else
    log.echo(LogLevels.INFO, "no echo command found.")
    return nil
  end
end

M.previewers = {
  all_commands = {
    previewer = M._vim_commands_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_command,
  },
  ex_commands = {
    previewer = M._vim_commands_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_command,
  },
  user_commands = {
    previewer = M._vim_commands_previewer,
    previewer_type = PreviewerTypeEnum.COMMAND_LIST,
    previewer_label = labels_helper.label_vim_command,
  },
}

M.actions = {
  ["esc"] = actions_helper.nop,
  ["enter"] = actions_helper.feed_vim_command,
  ["double-click"] = actions_helper.feed_vim_command,
}

M.fzf_opts = {
  "--no-multi",
  "--header-lines=1",
  { "--preview-window", "~1" },
  { "--prompt", "Commands > " },
}

--- @param commands fzfx.VimCommand[]
--- @return integer,integer
M._calculate_vim_commands_columns_width = function(commands)
  local NAME = "Name"
  local OPTS = "Bang|Bar|Nargs|Range|Complete"
  local name_width = string.len(NAME)
  local opts_width = string.len(OPTS)
  for _, c in ipairs(commands) do
    name_width = math.max(name_width, string.len(c.name))
    opts_width = math.max(opts_width, string.len(M._render_vim_commands_column_opts(c)))
  end
  return name_width, opts_width
end

--- @alias fzfx.VimCommandsPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,name_width:integer,opts_width:integer}
--- @return fzfx.VimCommandsPipelineContext
M._vim_commands_context_maker = function()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  local commands = M._get_vim_commands({ ex_commands = true, user_commands = true })
  local name_width, opts_width = M._calculate_vim_commands_columns_width(commands)
  ctx.name_width = name_width
  ctx.opts_width = opts_width
  return ctx
end

M.other_opts = {
  context_maker = M._vim_commands_context_maker,
}

return M
