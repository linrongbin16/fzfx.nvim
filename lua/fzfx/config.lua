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

--- @type table<string, fzfx.FzfOpt>
local default_fzf_options = {
  multi = "--multi",
  toggle = "--bind=ctrl-e:toggle",
  toggle_all = "--bind=ctrl-a:toggle-all",
  toggle_preview = "--bind=alt-p:toggle-preview",
  preview_half_page_down = "--bind=ctrl-f:preview-half-page-down",
  preview_half_page_up = "--bind=ctrl-b:preview-half-page-up",
  no_multi = "--no-multi",
  lsp_preview_window = { "--preview-window", "left,65%,+{2}-/2" },
}

-- files {

--- @return string, string
local function _default_bat_style_theme()
  local style = "numbers,changes"
  if
    type(vim.env["BAT_STYLE"]) == "string"
    and string.len(vim.env["BAT_STYLE"]) > 0
  then
    style = vim.env["BAT_STYLE"]
  end
  local theme = "base16"
  if
    type(vim.env["BAT_THEME"]) == "string"
    and string.len(vim.env["BAT_THEME"]) > 0
  then
    theme = vim.env["BAT_THEME"]
  end
  return style, theme
end

--- @param filename string
--- @param lineno integer?
--- @return fun():string[]
local function _make_file_previewer(filename, lineno)
  --- @return string[]
  local function impl()
    if consts.HAS_BAT then
      local style, theme = _default_bat_style_theme()
      -- "%s --style=%s --theme=%s --color=always --pager=never --highlight-line=%s -- %s"
      return type(lineno) == "number"
          and {
            consts.BAT,
            "--style=" .. style,
            "--theme=" .. theme,
            "--color=always",
            "--pager=never",
            "--highlight-line=" .. lineno,
            "--",
            filename,
          }
        or {
          consts.BAT,
          "--style=" .. style,
          "--theme=" .. theme,
          "--color=always",
          "--pager=never",
          "--",
          filename,
        }
    else
      -- "cat %s"
      return {
        "cat",
        filename,
      }
    end
  end
  return impl
end

--- @param line string
--- @return string[]
local function _file_previewer(line)
  local parsed = parsers_helper.parse_find(line)
  local f = _make_file_previewer(parsed.filename)
  return f()
end

-- files }

-- live grep {

-- "rg --column -n --no-heading --color=always -S"
local default_restricted_rg = {
  "rg",
  "--column",
  "-n",
  "--no-heading",
  "--color=always",
  "-H",
  "-S",
}
-- "rg --column -n --no-heading --color=always -S -uu"
local default_unrestricted_rg = {
  "rg",
  "--column",
  "-n",
  "--no-heading",
  "--color=always",
  "-H",
  "-S",
  "-uu",
}
-- "grep --color=always -n -H -r --exclude-dir='.*' --exclude='.*'"
local default_restricted_grep = {
  consts.GREP,
  "--color=always",
  "-n",
  "-H",
  "-r",
  "--exclude-dir=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]]),
  "--exclude=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]]),
}
-- "grep --color=always -n -H -r"
local default_unrestricted_grep = {
  consts.GREP,
  "--color=always",
  "-n",
  "-H",
  "-r",
}

local default_invalid_buffer_error = "invalid buffer(%s)."

--- @param opts {unrestricted:boolean?,buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
local function _make_live_grep_provider(opts)
  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local parsed = queries_helper.parse_flagged(query or "")
    local payload = parsed.payload
    local option = parsed.option

    local args = nil
    if consts.HAS_RG then
      if type(opts) == "table" and opts.unrestricted then
        args = vim.deepcopy(default_unrestricted_rg)
      elseif type(opts) == "table" and opts.buffer then
        args = vim.deepcopy(default_unrestricted_rg)
        local current_bufpath = nvims.buf_is_valid(context.bufnr)
            and paths.reduce(vim.api.nvim_buf_get_name(context.bufnr))
          or nil
        if
          type(current_bufpath) ~= "string"
          or string.len(current_bufpath) == 0
        then
          log.echo(
            LogLevels.INFO,
            default_invalid_buffer_error,
            vim.inspect(context.bufnr)
          )
          return nil
        end
      else
        args = vim.deepcopy(default_restricted_rg)
      end
    elseif vim.fn.executable("grep") > 0 or vim.fn.executable("ggrep") > 0 then
      if type(opts) == "table" and opts.unrestricted then
        args = vim.deepcopy(default_unrestricted_grep)
      elseif type(opts) == "table" and opts.buffer then
        args = vim.deepcopy(default_unrestricted_grep)
        local current_bufpath = nvims.buf_is_valid(context.bufnr)
            and paths.reduce(vim.api.nvim_buf_get_name(context.bufnr))
          or nil
        if
          type(current_bufpath) ~= "string"
          or string.len(current_bufpath) == 0
        then
          log.echo(
            LogLevels.INFO,
            default_invalid_buffer_error,
            vim.inspect(context.bufnr)
          )
          return nil
        end
      else
        args = vim.deepcopy(default_restricted_grep)
      end
    else
      log.echo(LogLevels.INFO, "no rg/grep command found.")
      return nil
    end
    if type(option) == "string" and string.len(option) > 0 then
      local option_splits = strs.split(option, " ")
      for _, o in ipairs(option_splits) do
        if type(o) == "string" and string.len(o) > 0 then
          table.insert(args, o)
        end
      end
    end
    if type(opts) == "table" and opts.buffer then
      local current_bufpath =
        paths.reduce(vim.api.nvim_buf_get_name(context.bufnr))
      table.insert(args, payload)
      table.insert(args, current_bufpath)
    else
      -- table.insert(args, "--")
      table.insert(args, payload)
    end
    return args
  end
  return impl
end

--- @param line string
--- @return string[]
local function _file_previewer_grep(line)
  local parsed = parsers_helper.parse_grep(line)
  local impl = _make_file_previewer(parsed.filename, parsed.lineno)
  return impl()
end

-- live grep }

-- buffers {

--- @param bufnr integer
--- @return boolean
local function _is_valid_buffer_number(bufnr)
  local exclude_filetypes = {
    ["qf"] = true,
    ["neo-tree"] = true,
  }
  local ok, ft_or_err = pcall(nvims.get_buf_option, bufnr, "filetype")
  if not ok then
    return false
  end
  return nvims.buf_is_valid(bufnr) and not exclude_filetypes[ft_or_err]
end

--- @param query string
--- @param context fzfx.PipelineContext
--- @return string[]|nil
local function _buffers_provider(query, context)
  local bufs = vim.api.nvim_list_bufs()
  local filenames = {}
  local current_filename = _is_valid_buffer_number(context.bufnr)
      and paths.reduce(vim.api.nvim_buf_get_name(context.bufnr))
    or nil
  if
    type(current_filename) == "string" and string.len(current_filename) > 0
  then
    table.insert(filenames, current_filename)
  end
  for _, bufnr in ipairs(bufs) do
    local fname = paths.reduce(vim.api.nvim_buf_get_name(bufnr))
    if _is_valid_buffer_number(bufnr) and fname ~= current_filename then
      table.insert(filenames, fname)
    end
  end
  return filenames
end

--- @param line string
local function _delete_buffer(line)
  local bufs = vim.api.nvim_list_bufs()
  local filenames = {}
  for _, bufnr in ipairs(bufs) do
    local bufpath = paths.reduce(vim.api.nvim_buf_get_name(bufnr))
    filenames[bufpath] = bufnr
  end
  if type(line) == "string" and string.len(line) > 0 then
    local parsed = parsers_helper.parse_find(line)
    local bufnr = filenames[parsed.filename]
    if type(bufnr) == "number" and nvims.buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, {})
    end
  end
end

-- buffers }

-- git files {

local default_git_root_error = "not in git repo."

--- @param opts {current_folder:boolean?}?
--- @return fun():string[]|nil
local function _make_git_files_provider(opts)
  --- @return string[]|nil
  local function impl()
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, default_git_root_error)
      return nil
    end
    return (type(opts) == "table" and opts.current_folder)
        and { "git", "ls-files" }
      or { "git", "ls-files", ":/" }
  end
  return impl
end

-- git files }

-- git grep {

--- @param query string?
--- @param context fzfx.PipelineContext
--- @return string[]|nil
local function _git_live_grep_provider(query, context)
  local git_root_cmd = cmds.GitRootCommand:run()
  if git_root_cmd:failed() then
    log.echo(LogLevels.INFO, default_git_root_error)
    return nil
  end

  local parsed = queries_helper.parse_flagged(query or "")
  local payload = parsed.payload
  local option = parsed.option

  local args = { "git", "grep", "--color=always", "-n" }
  if type(option) == "string" and string.len(option) > 0 then
    local option_splits = strs.split(option, " ")
    for _, o in ipairs(option_splits) do
      if type(o) == "string" and string.len(o) > 0 then
        table.insert(args, o)
      end
    end
  end
  table.insert(args, payload)
  return args
end

-- git grep }

-- git branches {

--- @return fzfx.GitBranchesPipelineContext
local function _git_branches_context_maker()
  local ctx = {}
  local git_remotes_cmd = cmds.GitRemotesCommand:run()
  if git_remotes_cmd:failed() then
    return ctx
  end
  ctx.remotes = git_remotes_cmd:output()
  return ctx
end

--- @param opts {remote_branch:boolean?}?
local function _make_git_branches_provider(opts)
  local function impl()
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, default_git_root_error)
      return nil
    end
    local git_current_branch_cmd = cmds.GitCurrentBranchCommand:run()
    if git_current_branch_cmd:failed() then
      log.echo(
        LogLevels.WARN,
        table.concat(git_current_branch_cmd.result.stderr, " ")
      )
      return nil
    end
    local branch_results = {}
    table.insert(
      branch_results,
      string.format("* %s", git_current_branch_cmd:output())
    )
    local git_branches_cmd = cmds.GitBranchesCommand:run(
      (type(opts) == "table" and opts.remote_branch) and true or false
    )
    if git_branches_cmd:failed() then
      log.echo(
        LogLevels.WARN,
        table.concat(git_current_branch_cmd.result.stderr, " ")
      )
      return nil
    end
    for _, line in ipairs(git_branches_cmd.result.stdout) do
      if vim.trim(line):sub(1, 1) ~= "*" then
        table.insert(branch_results, string.format("  %s", vim.trim(line)))
      end
    end
    return branch_results
  end
  return impl
end

local default_git_log_pretty =
  "%C(yellow)%h %C(cyan)%cd %C(green)%aN%C(auto)%d %Creset%s"

local function _git_branches_previewer(line)
  local branch = strs.split(line, " ")[1]
  -- "git log --graph --date=short --color=always --pretty='%C(auto)%cd %h%d %s'",
  -- "git log --graph --color=always --date=relative",
  return string.format(
    "git log --pretty=%s --graph --date=short --color=always %s",
    nvims.shellescape(default_git_log_pretty),
    branch
  )
end

-- git branches }

-- git commits {

--- @param opts {buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
local function _make_git_commits_provider(opts)
  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, default_git_root_error)
      return nil
    end
    if type(opts) == "table" and opts.buffer then
      if not nvims.buf_is_valid(context.bufnr) then
        log.echo(
          LogLevels.INFO,
          default_invalid_buffer_error,
          vim.inspect(context.bufnr)
        )
        return nil
      end
      return {
        "git",
        "log",
        "--pretty=" .. default_git_log_pretty,
        "--date=short",
        "--color=always",
        "--",
        vim.api.nvim_buf_get_name(context.bufnr),
      }
    else
      return {
        "git",
        "log",
        "--pretty=" .. default_git_log_pretty,
        "--date=short",
        "--color=always",
      }
    end
  end
  return impl
end

--- @return integer
local function _get_delta_width()
  local window_width = vim.api.nvim_win_get_width(0)
  return math.floor(math.max(3, window_width / 2 - 6))
end

--- @param commit string
--- @return string?
local function _make_git_commits_previewer(commit)
  if consts.HAS_DELTA then
    local preview_width = _get_delta_width()
    return string.format(
      [[git show %s | delta -n --tabs 4 --width %d]],
      commit,
      preview_width
    )
  else
    return string.format([[git show --color=always %s]], commit)
  end
end

--- @param line string
--- @return string?
local function _git_commits_previewer(line)
  if strs.isspace(line:sub(1, 1)) then
    return nil
  end
  local commit = strs.split(line, " ")[1]
  return _make_git_commits_previewer(commit)
end

-- git commits }

-- git blame {

--- @param query string
--- @param context fzfx.PipelineContext
--- @return string?
local function _git_blame_provider(query, context)
  local git_root_cmd = cmds.GitRootCommand:run()
  if git_root_cmd:failed() then
    log.echo(LogLevels.INFO, default_git_root_error)
    return nil
  end
  if not nvims.buf_is_valid(context.bufnr) then
    log.echo(
      LogLevels.INFO,
      default_invalid_buffer_error,
      vim.inspect(context.bufnr)
    )
    return nil
  end
  local bufname = vim.api.nvim_buf_get_name(context.bufnr)
  local bufpath = vim.fn.fnamemodify(bufname, ":~:.")
  -- return string.format(
  --     "git blame --date=short --color-lines %s",
  --     bufpath
  -- )
  if consts.HAS_DELTA then
    return string.format(
      [[git blame %s | delta -n --tabs 4 --blame-format %s]],
      nvims.shellescape(bufpath --[[@as string]]),
      nvims.shellescape("{commit:<8} {author:<15.14} {timestamp:<15}")
    )
  else
    return string.format(
      [[git blame --date=short --color-lines %s]],
      nvims.shellescape(bufpath --[[@as string]])
    )
  end
end

-- git blame }

-- git status {

--- @param opts {current_folder:boolean?}?
--- @return fun():string[]|nil
local function _make_git_status_provider(opts)
  local function impl()
    local git_root_cmd = cmds.GitRootCommand:run()
    if git_root_cmd:failed() then
      log.echo(LogLevels.INFO, default_git_root_error)
      return nil
    end
    return (type(opts) == "table" and opts.current_folder)
        and {
          "git",
          "-c",
          "color.status=always",
          "status",
          "--short",
          ".",
        }
      or { "git", "-c", "color.status=always", "status", "--short" }
  end
  return impl
end

--- @param line string
--- @return string?
local function _git_status_previewer(line)
  local parsed = parsers_helper.parse_git_status(line)
  if consts.HAS_DELTA then
    local preview_width = _get_delta_width()
    return string.format(
      [[git diff %s | delta -n --tabs 4 --width %d]],
      nvims.shellescape(parsed.filename),
      preview_width
    )
  else
    return string.format(
      [[git diff --color=always %s]],
      nvims.shellescape(parsed.filename)
    )
  end
end

-- git status }

-- lsp diagnostics {

local default_lsp_diagnostic_signs = {
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
    textcolor = "teal",
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

-- simulate rg's filepath color, see:
-- * https://github.com/BurntSushi/ripgrep/discussions/2605#discussioncomment-6881383
-- * https://github.com/BurntSushi/ripgrep/blob/d596f6ebd035560ee5706f7c0299c4692f112e54/crates/printer/src/color.rs#L14
local default_lsp_filename_color = consts.IS_WINDOWS and colors.cyan
  or colors.magenta

local default_no_lsp_clients_error = "no active lsp clients."
local default_no_lsp_diagnostics_error = "no lsp diagnostics found."

--- @return {severity:integer,name:string,text:string,texthl:string,textcolor:string}[]
local function _make_lsp_diagnostic_signs()
  local results = {}
  for _, signs in ipairs(default_lsp_diagnostic_signs) do
    local sign_def = vim.fn.sign_getdefined(signs.name) --[[@as table]]
    local item = vim.deepcopy(signs)
    if not tbls.tbl_empty(sign_def) then
      item.text = vim.trim(sign_def[1].text)
      item.texthl = sign_def[1].texthl
    end
    table.insert(results, item)
  end
  return results
end

--- @param diag {bufnr:integer,lnum:integer,col:integer,message:string,severity:integer}
--- @return {bufnr:integer,filename:string,lnum:integer,col:integer,text:string,severity:integer}?
local function _process_lsp_diagnostic_item(diag)
  if not vim.api.nvim_buf_is_valid(diag.bufnr) then
    return nil
  end
  log.debug(
    "|fzfx.config - _process_lsp_diagnostic_item| diag-1:%s",
    vim.inspect(diag)
  )
  local result = {
    bufnr = diag.bufnr,
    filename = paths.reduce(vim.api.nvim_buf_get_name(diag.bufnr)),
    lnum = diag.lnum + 1,
    col = diag.col + 1,
    text = vim.trim(diag.message:gsub("\n", " ")),
    severity = diag.severity or 1,
  }
  log.debug(
    "|fzfx.config - _process_lsp_diagnostic_item| diag-2:%s, result:%s",
    vim.inspect(diag),
    vim.inspect(result)
  )
  return result
end

--- @param opts {buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
local function _make_lsp_diagnostics_provider(opts)
  local signs = _make_lsp_diagnostic_signs()

  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    ---@diagnostic disable-next-line: deprecated
    local lsp_clients = vim.lsp.get_active_clients()
    if tbls.tbl_empty(lsp_clients) then
      log.echo(LogLevels.INFO, default_no_lsp_clients_error)
      return nil
    end
    local diag_list = vim.diagnostic.get(
      (type(opts) == "table" and opts.buffer) and context.bufnr or nil
    )
    if tbls.tbl_empty(diag_list) then
      log.echo(LogLevels.INFO, default_no_lsp_diagnostics_error)
      return nil
    end
    -- sort order: error > warn > info > hint
    table.sort(diag_list, function(a, b)
      return a.severity < b.severity
    end)

    local results = {}
    for _, item in ipairs(diag_list) do
      local diag = _process_lsp_diagnostic_item(item)
      if diag then
        -- it looks like:
        -- `lua/fzfx/config.lua:10:13: Unused local `query`.
        log.debug(
          "|fzfx.config - _make_lsp_diagnostics_provider| diag:%s",
          vim.inspect(diag)
        )
        local builder = ""
        if type(diag.text) == "string" and string.len(diag.text) > 0 then
          if type(signs[diag.severity]) == "table" then
            local sign_item = signs[diag.severity]
            local color_renderer = colors[sign_item.textcolor]
            builder = " " .. color_renderer(sign_item.text, sign_item.texthl)
          end
          builder = builder .. " " .. diag.text
        end
        log.debug(
          "|fzfx.config - _make_lsp_diagnostics_provider| diag:%s, builder:%s",
          vim.inspect(diag),
          vim.inspect(builder)
        )
        local line = string.format(
          "%s:%s:%s:%s",
          default_lsp_filename_color(diag.filename),
          colors.green(tostring(diag.lnum)),
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

-- lsp diagnostics }

-- lsp locations {

--- @alias fzfx.LspRangeStart {line:integer,character:integer}
--- @alias fzfx.LspRangeEnd {line:integer,character:integer}
--- @alias fzfx.LspRange {start:fzfx.LspRangeStart,end:fzfx.LspRangeEnd}
--- @alias fzfx.LspLocation {uri:string,range:fzfx.LspRange}
--- @alias fzfx.LspLocationLink {originSelectionRange:fzfx.LspRange,targetUri:string,targetRange:fzfx.LspRange,targetSelectionRange:fzfx.LspRange}

--- @param r fzfx.LspRange?
--- @return boolean
local function _is_lsp_range(r)
  return type(r) == "table"
    and type(r.start) == "table"
    and type(r.start.line) == "number"
    and type(r.start.character) == "number"
    and type(r["end"]) == "table"
    and type(r["end"].line) == "number"
    and type(r["end"].character) == "number"
end

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink|nil
local function _is_lsp_location(loc)
  return type(loc) == "table"
    and type(loc.uri) == "string"
    and _is_lsp_range(loc.range)
end

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink|nil
local function _is_lsp_locationlink(loc)
  return type(loc) == "table"
    and type(loc.targetUri) == "string"
    and _is_lsp_range(loc.targetRange)
end

--- @param line string
--- @param range fzfx.LspRange
--- @param color_renderer fun(text:string):string
--- @return string?
local function _lsp_range_render_line(line, range, color_renderer)
  log.debug(
    "|fzfx.config - _lsp_location_render_line| range:%s, line:%s",
    vim.inspect(range),
    vim.inspect(line)
  )
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

--- @alias fzfx.LspLocationPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,position_params:any}
--- @return fzfx.LspLocationPipelineContext
local function _lsp_position_context_maker()
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

--- @param loc fzfx.LspLocation|fzfx.LspLocationLink
--- @return string?
local function _render_lsp_location_line(loc)
  log.debug(
    "|fzfx.config - _render_lsp_location_line| loc:%s",
    vim.inspect(loc)
  )
  local filename = nil
  --- @type fzfx.LspRange
  local range = nil
  if _is_lsp_location(loc) then
    filename = paths.reduce(vim.uri_to_fname(loc.uri))
    range = loc.range
    log.debug(
      "|fzfx.config - _render_lsp_location_line| location filename:%s, range:%s",
      vim.inspect(filename),
      vim.inspect(range)
    )
  elseif _is_lsp_locationlink(loc) then
    filename = paths.reduce(vim.uri_to_fname(loc.targetUri))
    range = loc.targetRange
    log.debug(
      "|fzfx.config - _render_lsp_location_line| locationlink filename:%s, range:%s",
      vim.inspect(filename),
      vim.inspect(range)
    )
  end
  if not _is_lsp_range(range) then
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
    _lsp_range_render_line(filelines[range.start.line + 1], range, colors.red)
  log.debug(
    "|fzfx.config - _render_lsp_location_line| range:%s, loc_line:%s",
    vim.inspect(range),
    vim.inspect(loc_line)
  )
  local line = string.format(
    "%s:%s:%s:%s",
    default_lsp_filename_color(vim.fn.fnamemodify(filename, ":~:.")),
    colors.green(tostring(range.start.line + 1)),
    tostring(range.start.character + 1),
    loc_line
  )
  log.debug(
    "|fzfx.config - _render_lsp_location_line| line:%s",
    vim.inspect(line)
  )
  return line
end

local default_no_lsp_locations_error = "no lsp locations found."

-- lsp methods: https://github.com/neovim/neovim/blob/dc9f7b814517045b5354364655f660aae0989710/runtime/lua/vim/lsp/protocol.lua#L1028
--- @alias fzfx.LspMethod "textDocument/definition"|"textDocument/type_definition"|"textDocument/references"|"textDocument/implementation"|"callHierarchy/incomingCalls"|"callHierarchy/outgoingCalls"|"textDocument/prepareCallHierarchy"
---
-- lsp capabilities: https://github.com/neovim/neovim/blob/dc9f7b814517045b5354364655f660aae0989710/runtime/lua/vim/lsp.lua#L39
--- @alias fzfx.LspServerCapability "definitionProvider"|"typeDefinitionProvider"|"referencesProvider"|"implementationProvider"|"callHierarchyProvider"
---
--- @param opts {method:fzfx.LspMethod,capability:fzfx.LspServerCapability,timeout:integer?}
--- @return fun(query:string,context:fzfx.LspLocationPipelineContext):string[]|nil
local function _make_lsp_locations_provider(opts)
  --- @param query string
  --- @param context fzfx.LspLocationPipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    ---@diagnostic disable-next-line: deprecated
    local lsp_clients = vim.lsp.get_active_clients({ bufnr = context.bufnr })
    if tbls.tbl_empty(lsp_clients) then
      log.echo(LogLevels.INFO, default_no_lsp_clients_error)
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
      log.echo(LogLevels.INFO, "%s not supported.", vim.inspect(opts.method))
      return nil
    end
    local lsp_results, lsp_err = vim.lsp.buf_request_sync(
      context.bufnr,
      opts.method,
      context.position_params,
      opts.timeout or 3000
    )
    log.debug(
      "|fzfx.config - _make_lsp_locations_provider| opts:%s, lsp_results:%s, lsp_err:%s",
      vim.inspect(opts),
      vim.inspect(lsp_results),
      vim.inspect(lsp_err)
    )
    if lsp_err then
      log.echo(LogLevels.ERROR, lsp_err)
      return nil
    end
    if type(lsp_results) ~= "table" then
      log.echo(LogLevels.INFO, default_no_lsp_locations_error)
      return nil
    end

    local results = {}
    for client_id, lsp_result in pairs(lsp_results) do
      if
        client_id ~= nil
        and type(lsp_result) == "table"
        and type(lsp_result.result) == "table"
      then
        local lsp_loc = lsp_result.result
        if _is_lsp_location(lsp_loc) then
          local line = _render_lsp_location_line(lsp_loc)
          if type(line) == "string" and string.len(line) > 0 then
            table.insert(results, line)
          end
        else
          for _, loc in ipairs(lsp_loc) do
            local line = _render_lsp_location_line(loc)
            if type(line) == "string" and string.len(line) > 0 then
              table.insert(results, line)
            end
          end
        end
      end
    end

    if tbls.tbl_empty(results) then
      log.echo(LogLevels.INFO, default_no_lsp_locations_error)
      return nil
    end

    return results
  end
  return impl
end

-- lsp locations }

-- lsp call hierarchy {

local default_no_lsp_call_hierarchy_error = "no lsp call hierarchy found."

--- @alias fzfx.LspCallHierarchyItem {name:string,kind:integer,detail:string?,uri:string,range:fzfx.LspRange,selectionRange:fzfx.LspRange}
--- @alias fzfx.LspCallHierarchyIncomingCall {from:fzfx.LspCallHierarchyItem,fromRanges:fzfx.LspRange[]}
--- @alias fzfx.LspCallHierarchyOutgoingCall {to:fzfx.LspCallHierarchyItem,fromRanges:fzfx.LspRange[]}
---
--- @param item fzfx.LspCallHierarchyItem?
--- @return boolean
local function _is_lsp_call_hierarchy_item(item)
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
    and _is_lsp_range(item.range)
    and _is_lsp_range(item.selectionRange)
end

--- @param call_item fzfx.Options?
--- @return boolean
local function _is_lsp_call_hierarchy_incoming_call(call_item)
  return type(call_item) == "table"
    and _is_lsp_call_hierarchy_item(call_item.from)
    and type(call_item.fromRanges) == "table"
end

--- @param call_item fzfx.Options?
--- @return boolean
local function _is_lsp_call_hierarchy_outgoing_call(call_item)
  return type(call_item) == "table"
    and _is_lsp_call_hierarchy_item(call_item.to)
    and type(call_item.fromRanges) == "table"
end

--- @param item fzfx.LspCallHierarchyItem
--- @param ranges fzfx.LspRange[]
--- @return string[]
local function _render_lsp_call_hierarchy_line(item, ranges)
  log.debug(
    "|fzfx.config - _render_lsp_call_hierarchy_line| item:%s, ranges:%s",
    vim.inspect(item),
    vim.inspect(ranges)
  )
  local filename = nil
  if
    type(item.uri) == "string"
    and string.len(item.uri) > 0
    and _is_lsp_range(item.range)
  then
    filename = paths.reduce(vim.uri_to_fname(item.uri))
    log.debug(
      "|fzfx.config - _render_lsp_call_hierarchy_line| location filename:%s",
      vim.inspect(filename)
    )
  end
  if type(ranges) ~= "table" or #ranges == 0 then
    return {}
  end
  if type(filename) ~= "string" or vim.fn.filereadable(filename) <= 0 then
    return {}
  end
  local filelines = fs.readlines(filename)
  if type(filelines) ~= "table" then
    return {}
  end
  local lines = {}
  for i, r in ipairs(ranges) do
    local item_line =
      _lsp_range_render_line(filelines[r.start.line + 1], r, colors.red)
    log.debug(
      "|fzfx.config - _render_lsp_call_hierarchy_line| %s-range:%s, item_line:%s",
      vim.inspect(i),
      vim.inspect(r),
      vim.inspect(item_line)
    )
    local line = string.format(
      "%s:%s:%s:%s",
      default_lsp_filename_color(vim.fn.fnamemodify(filename, ":~:.")),
      colors.green(tostring(r.start.line + 1)),
      tostring(r.start.character + 1),
      item_line
    )
    log.debug(
      "|fzfx.config - _render_lsp_call_hierarchy_line| %s-line:%s",
      vim.inspect(i),
      vim.inspect(line)
    )
    table.insert(lines, line)
  end
  return lines
end

--- @param method fzfx.LspMethod
--- @param hi_item fzfx.LspCallHierarchyIncomingCall|fzfx.LspCallHierarchyOutgoingCall
--- @return fzfx.LspCallHierarchyItem?, fzfx.LspRange[]|nil
local function _retrieve_lsp_call_hierarchy_item_and_from_ranges(
  method,
  hi_item
)
  if
    method == "callHierarchy/incomingCalls"
    and _is_lsp_call_hierarchy_incoming_call(hi_item)
  then
    return hi_item.from, hi_item.fromRanges
  elseif
    method == "callHierarchy/outgoingCalls"
    and _is_lsp_call_hierarchy_outgoing_call(hi_item)
  then
    return hi_item.to, hi_item.fromRanges
  else
    return nil, nil
  end
end

-- incoming calls test: https://github.com/neovide/neovide/blob/59e4ed47e72076bc8cec09f11d73c389624b19fc/src/main.rs#L266
--- @param opts {method:fzfx.LspMethod,capability:fzfx.LspServerCapability,timeout:integer?}
--- @return fun(query:string,context:fzfx.LspLocationPipelineContext):string[]|nil
local function _make_lsp_call_hierarchy_provider(opts)
  --- @param query string
  --- @param context fzfx.LspLocationPipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    ---@diagnostic disable-next-line: deprecated
    local lsp_clients = vim.lsp.get_active_clients({ bufnr = context.bufnr })
    if tbls.tbl_empty(lsp_clients) then
      log.echo(LogLevels.INFO, default_no_lsp_clients_error)
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
      log.echo(LogLevels.INFO, "%s not supported.", vim.inspect(opts.method))
      return nil
    end
    local lsp_results, lsp_err = vim.lsp.buf_request_sync(
      context.bufnr,
      "textDocument/prepareCallHierarchy",
      context.position_params,
      opts.timeout or 3000
    )
    log.debug(
      "|fzfx.config - _make_lsp_call_hierarchy_provider| prepare, opts:%s, lsp_results:%s, lsp_err:%s",
      vim.inspect(opts),
      vim.inspect(lsp_results),
      vim.inspect(lsp_err)
    )
    if lsp_err then
      log.echo(LogLevels.ERROR, lsp_err)
      return nil
    end
    if type(lsp_results) ~= "table" then
      log.echo(LogLevels.INFO, default_no_lsp_call_hierarchy_error)
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
      log.echo(LogLevels.INFO, default_no_lsp_call_hierarchy_error)
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
      "|fzfx.config - _make_lsp_call_hierarchy_provider| 2nd call, opts:%s, lsp_item: %s, lsp_results2:%s, lsp_err2:%s",
      vim.inspect(opts),
      vim.inspect(lsp_item),
      vim.inspect(lsp_results2),
      vim.inspect(lsp_err2)
    )
    if lsp_err2 then
      log.echo(LogLevels.ERROR, lsp_err2)
      return nil
    end
    if type(lsp_results2) ~= "table" then
      log.echo(LogLevels.INFO, default_no_lsp_locations_error)
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
          "|fzfx.config - _make_lsp_call_hierarchy_provider| method:%s, lsp_hi_item_list:%s",
          vim.inspect(opts.method),
          vim.inspect(lsp_hi_item_list)
        )
        for _, lsp_hi_item in ipairs(lsp_hi_item_list) do
          local hi_item, from_ranges =
            _retrieve_lsp_call_hierarchy_item_and_from_ranges(
              opts.method,
              lsp_hi_item
            )
          log.debug(
            "|fzfx.config - _make_lsp_call_hierarchy_provider| method:%s, lsp_hi_item:%s, hi_item:%s, from_ranges:%s",
            vim.inspect(opts.method),
            vim.inspect(lsp_hi_item_list),
            vim.inspect(hi_item),
            vim.inspect(from_ranges)
          )
          if
            _is_lsp_call_hierarchy_item(hi_item)
            and type(from_ranges) == "table"
          then
            local lines = _render_lsp_call_hierarchy_line(
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

    if tbls.tbl_empty(results) then
      log.echo(LogLevels.INFO, default_no_lsp_call_hierarchy_error)
      return nil
    end

    return results
  end
  return impl
end

-- lsp call hierarchy }

-- vim commands {

--- @param line string
--- @return string
local function _parse_vim_ex_command_name(line)
  local name_stop_pos = strs.find(line, "|", 3)
  return vim.trim(line:sub(3, name_stop_pos - 1))
end

--- @return table<string, fzfx.VimCommand>
local function _get_vim_ex_commands()
  local help_docs_list =
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.fn.globpath(vim.env.VIMRUNTIME, "doc/index.txt", 0, 1) --[[@as table]]
  log.debug(
    "|fzfx.config - _get_vim_ex_commands| help docs:%s",
    vim.inspect(help_docs_list)
  )
  if tbls.tbl_empty(help_docs_list) then
    log.echo(LogLevels.INFO, "no 'doc/index.txt' found.")
    return {}
  end
  local results = {}
  for _, help_doc in ipairs(help_docs_list) do
    local lines = fs.readlines(help_doc) --[[@as table]]
    for i = 1, #lines do
      local line = lines[i]
      if strs.startswith(line, "|:") then
        log.debug(
          "|fzfx.config - _get_vim_ex_commands| line[%d]:%s",
          i,
          vim.inspect(line)
        )
        local name = _parse_vim_ex_command_name(line)
        if type(name) == "string" and string.len(name) > 0 then
          results[name] = {
            name = name,
            loc = {
              filename = paths.reduce2home(help_doc),
              lineno = i,
            },
          }
        end
      end
      i = i + 1
    end
  end
  log.debug(
    "|fzfx.config - _get_vim_ex_commands| results:%s",
    vim.inspect(results)
  )
  return results
end

--- @param header string
--- @return boolean
local function _is_ex_command_output_header(header)
  local name_pos = strs.find(header, "Name")
  local args_pos = strs.find(header, "Args")
  local address_pos = strs.find(header, "Address")
  local complete_pos = strs.find(header, "Complete")
  local definition_pos = strs.find(header, "Definition")
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
local function _parse_ex_command_output_lua_function_definition(line, start_pos)
  log.debug(
    "|fzfx.config - _parse_ex_command_output_lua_function_definition| line:%s, start_pos:%s",
    vim.inspect(line),
    vim.inspect(start_pos)
  )
  local lua_flag = "<Lua "
  local lua_function_flag = "<Lua function>"
  local lua_function_pos = strs.find(line, lua_function_flag, start_pos)
  if lua_function_pos then
    start_pos = strs.find(
      line,
      lua_flag,
      lua_function_pos + string.len(lua_function_flag)
    ) --[[@as integer]]
  else
    start_pos = strs.find(line, lua_flag, start_pos) --[[@as integer]]
  end
  if start_pos == nil then
    return nil
  end
  local first_colon_pos = strs.find(line, ":", start_pos)
  local content = vim.trim(line:sub(first_colon_pos + 1))
  if string.len(content) > 0 and content:sub(#content) == ">" then
    content = content:sub(1, #content - 1)
  end
  log.debug(
    "|fzfx.config - _parse_ex_command_output_lua_function_definition| content-2:%s",
    vim.inspect(content)
  )
  local content_splits = strs.split(content, ":")
  log.debug(
    "|fzfx.config - _parse_ex_command_output_lua_function_definition| split content:%s",
    vim.inspect(content_splits)
  )
  return {
    filename = vim.fn.expand(content_splits[1]),
    lineno = tonumber(content_splits[2]),
  }
end

--- @param header string
--- @return fzfx.VimExCommandOutputHeader
local function _parse_ex_command_output_header(header)
  local name_pos = strs.find(header, "Name")
  local args_pos = strs.find(header, "Args")
  local address_pos = strs.find(header, "Address")
  local complete_pos = strs.find(header, "Complete")
  local definition_pos = strs.find(header, "Definition")
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
local function _parse_ex_command_output()
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
  local command_outputs = fs.readlines(tmpfile --[[@as string]]) --[[@as table]]
  local found_command_output_header = false
  --- @type fzfx.VimExCommandOutputHeader
  local parsed_header = nil

  for i = 1, #command_outputs do
    local line = command_outputs[i]

    if found_command_output_header then
      -- parse command name, e.g., FzfxCommands, etc.
      local idx = parsed_header.name_pos
      log.debug(
        "|fzfx.config - _parse_ex_command_output| line[%d]:%s(%d)",
        i,
        vim.inspect(line),
        idx
      )
      while idx <= #line and not strs.isspace(line:sub(idx, idx)) do
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
        if strs.isspace(line:sub(idx, idx)) then
          break
        end
        idx = idx + 1
      end
      local name = vim.trim(line:sub(parsed_header.name_pos, idx))

      idx = math.max(parsed_header.definition_pos, idx)
      local parsed_line =
        _parse_ex_command_output_lua_function_definition(line, idx)
      if parsed_line then
        results[name] = {
          filename = parsed_line.filename,
          lineno = parsed_line.lineno,
        }
      end
    end

    if _is_ex_command_output_header(line) then
      found_command_output_header = true
      parsed_header = _parse_ex_command_output_header(line)
      log.debug(
        "|fzfx.config - _parse_ex_command_output| parsed header:%s",
        vim.inspect(parsed_header)
      )
    end
  end

  return results
end

--- @return table<string, fzfx.VimCommand>
local function _get_vim_user_commands()
  local parsed_ex_commands = _parse_ex_command_output()
  local user_commands = vim.api.nvim_get_commands({ builtin = false })
  log.debug(
    "|fzfx.config - _get_vim_user_commands| user commands:%s",
    vim.inspect(user_commands)
  )

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

--- @param rendered fzfx.VimCommand
--- @return string
local function _render_vim_commands_column_opts(rendered)
  local bang = (type(rendered.opts) == "table" and rendered.opts.bang) and "Y"
    or "N"
  local bar = (type(rendered.opts) == "table" and rendered.opts.bar) and "Y"
    or "N"
  local nargs = (type(rendered.opts) == "table" and rendered.opts.nargs)
      and rendered.opts.nargs
    or "N/A"
  local range = (type(rendered.opts) == "table" and rendered.opts.range)
      and rendered.opts.range
    or "N/A"
  local complete = (type(rendered.opts) == "table" and rendered.opts.complete)
      and (rendered.opts.complete == "<Lua function>" and "<Lua>" or rendered.opts.complete)
    or "N/A"

  return string.format(
    "%-4s|%-3s|%-5s|%-5s|%s",
    bang,
    bar,
    nargs,
    range,
    complete
  )
end

--- @param commands fzfx.VimCommand[]
--- @return integer,integer
local function _render_vim_commands_columns_status(commands)
  local NAME = "Name"
  local OPTS = "Bang|Bar|Nargs|Range|Complete"
  local max_name = string.len(NAME)
  local max_opts = string.len(OPTS)
  for _, c in ipairs(commands) do
    max_name = math.max(max_name, string.len(c.name))
    max_opts =
      math.max(max_opts, string.len(_render_vim_commands_column_opts(c)))
  end
  return max_name, max_opts
end

--- @param commands fzfx.VimCommand[]
--- @param name_width integer
--- @param opts_width integer
--- @return string[]
local function _render_vim_commands(commands, name_width, opts_width)
  --- @param r fzfx.VimCommand
  --- @return string
  local function rendered_desc_or_loc(r)
    if
      type(r.loc) == "table"
      and type(r.loc.filename) == "string"
      and type(r.loc.lineno) == "number"
    then
      return string.format("%s:%d", paths.reduce(r.loc.filename), r.loc.lineno)
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
    "|fzfx.config - _render_vim_commands| formatter:%s, header:%s",
    vim.inspect(formatter),
    vim.inspect(header)
  )
  for i, c in ipairs(commands) do
    local rendered = string.format(
      formatter,
      c.name,
      _render_vim_commands_column_opts(c),
      rendered_desc_or_loc(c)
    )
    log.debug(
      "|fzfx.config - _render_vim_commands| rendered[%d]:%s",
      i,
      vim.inspect(rendered)
    )
    table.insert(results, rendered)
  end
  return results
end

--- @param no_ex_commands boolean?
--- @param no_user_commands boolean?
--- @return fzfx.VimCommand[]
local function _get_vim_commands(no_ex_commands, no_user_commands)
  local results = {}
  local ex_commands = no_ex_commands and {} or _get_vim_ex_commands()
  log.debug(
    "|fzfx.config - _get_vim_commands| ex commands:%s",
    vim.inspect(ex_commands)
  )
  local user_commands = no_user_commands and {} or _get_vim_user_commands()
  log.debug(
    "|fzfx.config - _get_vim_commands| user commands:%s",
    vim.inspect(user_commands)
  )
  for _, c in pairs(ex_commands) do
    table.insert(results, c)
  end
  for _, c in pairs(user_commands) do
    table.insert(results, c)
  end
  table.sort(results, function(a, b)
    return a.name < b.name
  end)

  return results
end

--- @return fzfx.VimCommandsPipelineContext
local function _vim_commands_context_maker()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  local commands = _get_vim_commands()
  local name_width, opts_width = _render_vim_commands_columns_status(commands)
  ctx.name_width = name_width
  ctx.opts_width = opts_width
  return ctx
end

--- @param ctx fzfx.VimCommandsPipelineContext
--- @return string[]
local function vim_commands_provider(ctx)
  local commands = _get_vim_commands()
  return _render_vim_commands(commands, ctx.name_width, ctx.opts_width)
end

--- @param ctx fzfx.VimCommandsPipelineContext
--- @return string[]
local function vim_ex_commands_provider(ctx)
  local commands = _get_vim_commands(nil, true)
  return _render_vim_commands(commands, ctx.name_width, ctx.opts_width)
end

--- @param ctx fzfx.VimCommandsPipelineContext
--- @return string[]
local function vim_user_commands_provider(ctx)
  local commands = _get_vim_commands(true)
  return _render_vim_commands(commands, ctx.name_width, ctx.opts_width)
end

--- @param filename string
--- @param lineno integer
--- @return string[]
local function _vim_commands_lua_function_previewer(filename, lineno)
  local height = vim.api.nvim_win_get_height(0)
  if consts.HAS_BAT then
    local style, theme = _default_bat_style_theme()
    -- "%s --style=%s --theme=%s --color=always --pager=never --highlight-line=%s --line-range %d: -- %s"
    return {
      consts.BAT,
      "--style=" .. style,
      "--theme=" .. theme,
      "--color=always",
      "--pager=never",
      "--highlight-line=" .. lineno,
      "--line-range",
      string.format(
        "%d:",
        math.max(lineno - math.max(math.floor(height / 2), 1), 1)
      ),
      "--",
      filename,
    }
  else
    -- "cat %s"
    return {
      "cat",
      filename,
    }
  end
end

--- @param line string
--- @param context fzfx.VimCommandsPipelineContext
--- @return string[]|nil
local function vim_commands_previewer(line, context)
  local parsed = parsers_helper.parse_vim_command(line, context)
  log.debug(
    "|fzfx.config - vim_commands_previewer| line:%s, context:%s, parsed:%s",
    vim.inspect(line),
    vim.inspect(context),
    vim.inspect(parsed)
  )
  if
    tbls.tbl_not_empty(parsed)
    and strs.not_empty(parsed.filename)
    and type(parsed.lineno) == "number"
  then
    log.debug(
      "|fzfx.config - vim_commands_previewer| loc:%s",
      vim.inspect(parsed)
    )
    return _vim_commands_lua_function_previewer(parsed.filename, parsed.lineno)
  elseif consts.HAS_ECHO and tbls.tbl_not_empty(parsed) then
    log.debug(
      "|fzfx.config - vim_commands_previewer| desc:%s",
      vim.inspect(parsed)
    )
    return { "echo", parsed.definition or "" }
  else
    log.echo(LogLevels.INFO, "no echo command found.")
    return nil
  end
end

-- vim commands }

-- vim keymaps {

-- the ':verbose map' output looks like:
--
--```
--n  K           *@<Cmd>lua vim.lsp.buf.hover()<CR>
--                Show hover
--                Last set from Lua
--n  [w          *@<Lua 1213: ~/.config/nvim/lua/builtin/lsp.lua:60>
--                Previous diagnostic warning
--                Last set from Lua
--n  [e          *@<Lua 1211: ~/.config/nvim/lua/builtin/lsp.lua:60>
--                 Previous diagnostic error
--                 Last set from Lua
--n  [d          *@<Lua 1209: ~/.config/nvim/lua/builtin/lsp.lua:60>
--                 Previous diagnostic item
--                 Last set from Lua
--x  \ca         *@<Cmd>lua vim.lsp.buf.range_code_action()<CR>
--                 Code actions
--n  <CR>        *@<Lua 961: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>
--                 Last set from Lua
--n  <Esc>       *@<Lua 998: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>
--                 Last set from Lua
--n  .           *@<Lua 977: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>
--                 Last set from Lua
--n  <           *@<Lua 987: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>
--                 Last set from Lua
--v  <BS>        * d
--                 Last set from /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/mswin.vim line 24
--x  <Plug>NetrwBrowseXVis * :<C-U>call netrw#BrowseXVis()<CR>
--                 Last set from /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/plugin/netrwPlugin.vim line 90
--n  <Plug>NetrwBrowseX * :call netrw#BrowseX(netrw#GX(),netrw#CheckIfRemote(netrw#GX()))<CR>
--                 Last set from /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/plugin/netrwPlugin.vim line 84
--n  <C-L>       * :nohlsearch<C-R>=has('diff')?'|diffupdate':''<CR><CR><C-L>
--                 Last set from ~/.config/nvim/lua/builtin/options.vim line 50
--```
--- @param line string
--- @return fzfx.VimKeyMap
local function _parse_map_command_output_line(line)
  local first_space_pos = 1
  while
    first_space_pos <= #line
    and not strs.isspace(line:sub(first_space_pos, first_space_pos))
  do
    first_space_pos = first_space_pos + 1
  end
  -- local mode = vim.trim(line:sub(1, first_space_pos - 1))
  while
    first_space_pos <= #line
    and strs.isspace(line:sub(first_space_pos, first_space_pos))
  do
    first_space_pos = first_space_pos + 1
  end
  local second_space_pos = first_space_pos
  while
    second_space_pos <= #line
    and not strs.isspace(line:sub(second_space_pos, second_space_pos))
  do
    second_space_pos = second_space_pos + 1
  end
  local lhs = vim.trim(line:sub(first_space_pos, second_space_pos - 1))
  local result = { lhs = lhs }
  local rhs_or_location = vim.trim(line:sub(second_space_pos))
  local lua_definition_pos = strs.find(rhs_or_location, "<Lua ")

  if lua_definition_pos and strs.endswith(rhs_or_location, ">") then
    local first_colon_pos =
      strs.find(rhs_or_location, ":", lua_definition_pos + string.len("<Lua ")) --[[@as integer]]
    local last_colon_pos = strs.rfind(rhs_or_location, ":") --[[@as integer]]
    local filename =
      rhs_or_location:sub(first_colon_pos + 1, last_colon_pos - 1)
    local lineno = rhs_or_location:sub(last_colon_pos + 1, #rhs_or_location - 1)
    log.debug(
      "|fzfx.config - _parse_map_command_output_line| lhs:%s, filename:%s, lineno:%s",
      vim.inspect(lhs),
      vim.inspect(filename),
      vim.inspect(lineno)
    )
    result.filename = paths.normalize(filename, { expand = true })
    result.lineno = tonumber(lineno)
  end
  return result
end

--- @return fzfx.VimKeyMap[]
local function _get_vim_keymaps()
  local tmpfile = vim.fn.tempname()
  vim.cmd(string.format(
    [[
    redir! > %s
    silent execute 'verbose map'
    redir END
    ]],
    tmpfile
  ))

  local keys_output_map = {}
  local map_output_lines = fs.readlines(tmpfile --[[@as string]]) --[[@as table]]

  local LAST_SET_FROM = "\tLast set from "
  local LAST_SET_FROM_LUA = "\tLast set from Lua"
  local LINE = " line "
  local last_lhs = nil
  for i = 1, #map_output_lines do
    local line = map_output_lines[i]
    if type(line) == "string" and string.len(vim.trim(line)) > 0 then
      if strs.isalpha(line:sub(1, 1)) then
        local parsed = _parse_map_command_output_line(line)
        keys_output_map[parsed.lhs] = parsed
        last_lhs = parsed.lhs
      elseif
        strs.startswith(line, LAST_SET_FROM)
        and strs.rfind(line, LINE)
        and not strs.startswith(line, LAST_SET_FROM_LUA)
        and last_lhs
      then
        local line_pos = strs.rfind(line, LINE)
        local filename =
          vim.trim(line:sub(string.len(LAST_SET_FROM) + 1, line_pos - 1))
        local lineno = vim.trim(line:sub(line_pos + string.len(LINE)))
        keys_output_map[last_lhs].filename =
          paths.normalize(filename, { expand = true })
        keys_output_map[last_lhs].lineno = tonumber(lineno)
      end
    end
  end
  -- log.debug(
  --     "|fzfx.config - _get_vim_keymaps| keys_output_map1:%s",
  --     vim.inspect(keys_output_map)
  -- )
  local api_keys_list = vim.api.nvim_get_keymap("")
  -- log.debug(
  --     "|fzfx.config - _get_vim_keymaps| api_keys_list:%s",
  --     vim.inspect(api_keys_list)
  -- )
  local api_keys_map = {}
  for _, km in ipairs(api_keys_list) do
    if not api_keys_map[km.lhs] then
      api_keys_map[km.lhs] = km
    end
  end

  local function get_boolean(v, default_value)
    if type(v) == "number" then
      return v > 0
    elseif type(v) == "boolean" then
      return v
    else
      return default_value
    end
  end
  local function get_string(v, default_value)
    if type(v) == "string" and string.len(v) > 0 then
      return v
    else
      return default_value
    end
  end

  local function get_key_def(keys, left)
    if keys[left] then
      return keys[left]
    end
    if strs.startswith(left, "<Space>") or strs.startswith(left, "<space>") then
      return keys[" " .. left:sub(string.len("<Space>") + 1)]
    end
    return nil
  end

  for lhs, km in pairs(keys_output_map) do
    local km2 = get_key_def(api_keys_map, lhs)
    if km2 then
      km.rhs = get_string(km2.rhs, "")
      km.mode = get_string(km2.mode, "")
      km.noremap = get_boolean(km2.noremap, false)
      km.nowait = get_boolean(km2.nowait, false)
      km.silent = get_boolean(km2.silent, false)
      km.desc = get_string(km2.desc, "")
    else
      km.rhs = get_string(km.rhs, "")
      km.mode = get_string(km.mode, "")
      km.noremap = get_boolean(km.noremap, false)
      km.nowait = get_boolean(km.nowait, false)
      km.silent = get_boolean(km.silent, false)
      km.desc = get_string(km.desc, "")
    end
  end
  log.debug(
    "|fzfx.config - _get_vim_keymaps| keys_output_map2:%s",
    vim.inspect(keys_output_map)
  )
  local results = {}
  for _, r in pairs(keys_output_map) do
    table.insert(results, r)
  end
  table.sort(results, function(a, b)
    return a.lhs < b.lhs
  end)
  log.debug("|fzfx.config - _get_vim_keymaps| results:%s", vim.inspect(results))
  return results
end

--- @param rendered fzfx.VimKeyMap
--- @return string
local function _render_vim_keymaps_column_opts(rendered)
  local mode = rendered.mode or ""
  local noremap = rendered.noremap and "Y" or "N"
  local nowait = rendered.nowait and "Y" or "N"
  local silent = rendered.silent and "Y" or "N"
  return string.format("%-4s|%-7s|%-6s|%-6s", mode, noremap, nowait, silent)
end

--- @param keys fzfx.VimKeyMap[]
--- @return integer,integer
local function _render_vim_keymaps_columns_status(keys)
  local KEY = "Key"
  local OPTS = "Mode|Noremap|Nowait|Silent"
  local max_key = string.len(KEY)
  local max_opts = string.len(OPTS)
  for _, k in ipairs(keys) do
    max_key = math.max(max_key, string.len(k.lhs))
    max_opts =
      math.max(max_opts, string.len(_render_vim_keymaps_column_opts(k)))
  end
  log.debug(
    "|fzfx.config - _render_vim_keymaps_columns_status| lhs:%s, opts:%s",
    vim.inspect(max_key),
    vim.inspect(max_opts)
  )
  return max_key, max_opts
end

--- @param keymaps fzfx.VimKeyMap[]
--- @param key_width integer
--- @param opts_width integer
--- @return string[]
local function _render_vim_keymaps(keymaps, key_width, opts_width)
  --- @param r fzfx.VimKeyMap
  --- @return string?
  local function rendered_def_or_loc(r)
    if
      type(r) == "table"
      and type(r.filename) == "string"
      and string.len(r.filename) > 0
      and type(r.lineno) == "number"
      and r.lineno >= 0
    then
      return string.format("%s:%d", paths.reduce(r.filename), r.lineno)
    elseif type(r.rhs) == "string" and string.len(r.rhs) > 0 then
      return string.format('"%s"', r.rhs)
    elseif type(r.desc) == "string" and string.len(r.desc) > 0 then
      return string.format('"%s"', r.desc)
    else
      return ""
    end
  end

  local KEY = "Key"
  local OPTS = "Mode|Noremap|Nowait|Silent"
  local DEF_OR_LOC = "Definition/Location"

  local results = {}
  local formatter = "%-"
    .. tostring(key_width)
    .. "s"
    .. " %-"
    .. tostring(opts_width)
    .. "s %s"
  local header = string.format(formatter, KEY, OPTS, DEF_OR_LOC)
  table.insert(results, header)
  log.debug(
    "|fzfx.config - _render_vim_keymaps| formatter:%s, header:%s",
    vim.inspect(formatter),
    vim.inspect(header)
  )
  for i, c in ipairs(keymaps) do
    local rendered = string.format(
      formatter,
      c.lhs,
      _render_vim_keymaps_column_opts(c),
      rendered_def_or_loc(c)
    )
    log.debug(
      "|fzfx.config - _render_vim_keymaps| rendered[%d]:%s",
      i,
      vim.inspect(rendered)
    )
    table.insert(results, rendered)
  end
  return results
end

--- @return fzfx.VimKeyMapsPipelineContext
local function _vim_keymaps_context_maker()
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  local keys = _get_vim_keymaps()
  local key_width, opts_width = _render_vim_keymaps_columns_status(keys)
  ctx.key_width = key_width
  ctx.opts_width = opts_width
  return ctx
end

--- @param mode "n"|"i"|"v"|"all"
--- @return fun(query:string,context:fzfx.VimKeyMapsPipelineContext):string[]|nil
local function _make_vim_keymaps_provider(mode)
  --- @param query string
  --- @param context fzfx.VimKeyMapsPipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local keys = _get_vim_keymaps()
    local filtered_keys = {}
    if mode == "all" then
      filtered_keys = keys
    else
      for _, k in ipairs(keys) do
        if k.mode == mode then
          table.insert(filtered_keys, k)
        elseif
          mode == "v"
          and (
            strs.find(k.mode, "v")
            or strs.find(k.mode, "s")
            or strs.find(k.mode, "x")
          )
        then
          table.insert(filtered_keys, k)
        elseif mode == "n" and strs.find(k.mode, "n") then
          table.insert(filtered_keys, k)
        elseif mode == "i" and strs.find(k.mode, "i") then
          table.insert(filtered_keys, k)
        elseif mode == "n" and string.len(k.mode) == 0 then
          table.insert(filtered_keys, k)
        end
      end
    end
    return _render_vim_keymaps(
      filtered_keys,
      context.key_width,
      context.opts_width
    )
  end
  return impl
end

--- @param filename string
--- @param lineno integer
--- @return string[]
local function _vim_keymaps_lua_function_previewer(filename, lineno)
  local height = vim.api.nvim_win_get_height(0)
  if consts.HAS_BAT then
    local style, theme = _default_bat_style_theme()
    -- "%s --style=%s --theme=%s --color=always --pager=never --highlight-line=%s --line-range %d: -- %s"
    return {
      consts.BAT,
      "--style=" .. style,
      "--theme=" .. theme,
      "--color=always",
      "--pager=never",
      "--highlight-line=" .. lineno,
      "--line-range",
      string.format(
        "%d:",
        math.max(lineno - math.max(math.floor(height / 2), 1), 1)
      ),
      "--",
      filename,
    }
  else
    -- "cat %s"
    return {
      "cat",
      filename,
    }
  end
end

--- @param line string
--- @param context fzfx.VimKeyMapsPipelineContext
--- @return string[]|nil
local function _vim_keymaps_previewer(line, context)
  local parsed = parsers_helper.parse_vim_keymap(line, context)
  log.debug(
    "|fzfx.config - vim_keymaps_previewer| line:%s, context:%s, desc_or_loc:%s",
    vim.inspect(line),
    vim.inspect(context),
    vim.inspect(parsed)
  )
  if
    tbls.tbl_not_empty(parsed)
    and strs.not_empty(parsed.filename)
    and type(parsed.lineno) == "number"
  then
    log.debug(
      "|fzfx.config - vim_keymaps_previewer| loc:%s",
      vim.inspect(parsed)
    )
    return _vim_keymaps_lua_function_previewer(parsed.filename, parsed.lineno)
  elseif consts.HAS_ECHO and tbls.tbl_not_empty(parsed) then
    log.debug(
      "|fzfx.config - vim_keymaps_previewer| desc:%s",
      vim.inspect(parsed)
    )
    return { "echo", parsed.definition or "" }
  else
    log.echo(LogLevels.INFO, "no echo command found.")
    return nil
  end
end

-- vim keymaps }

-- file explorer {

--- @alias fzfx.FileExplorerPipelineContext {bufnr:integer,winnr:integer,tabnr:integer,cwd:string}
--- @return fzfx.FileExplorerPipelineContext
local function _file_explorer_context_maker()
  local temp = vim.fn.tempname()
  fs.writefile(temp --[[@as string]], vim.fn.getcwd() --[[@as string]])
  local context = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
    cwd = temp,
  }
  return context
end

--- @param ls_args "-lh"|"-lha"
--- @return fun(query:string,context:fzfx.PipelineContext):string?
local function _make_file_explorer_provider(ls_args)
  --- @param query string
  --- @param context fzfx.FileExplorerPipelineContext
  --- @return string?
  local function impl(query, context)
    local cwd = fs.readfile(context.cwd)
    if consts.HAS_LSD then
      return consts.HAS_ECHO
          and string.format(
            "echo %s && lsd %s --color=always --header -- %s",
            nvims.shellescape(cwd --[[@as string]]),
            ls_args,
            nvims.shellescape(cwd --[[@as string]])
          )
        or string.format(
          "lsd %s --color=always --header -- %s",
          ls_args,
          nvims.shellescape(cwd --[[@as string]])
        )
    elseif consts.HAS_EZA then
      return consts.HAS_ECHO
          and string.format(
            "echo %s && %s --color=always %s -- %s",
            nvims.shellescape(cwd --[[@as string]]),
            consts.EZA,
            ls_args,
            nvims.shellescape(cwd --[[@as string]])
          )
        or string.format(
          "%s --color=always %s -- %s",
          consts.EZA,
          ls_args,
          nvims.shellescape(cwd --[[@as string]])
        )
    elseif consts.HAS_LS then
      return consts.HAS_ECHO
          and string.format(
            "echo %s && ls --color=always %s %s",
            nvims.shellescape(cwd --[[@as string]]),
            ls_args,
            nvims.shellescape(cwd --[[@as string]])
          )
        or string.format(
          "ls --color=always %s %s",
          ls_args,
          nvims.shellescape(cwd --[[@as string]])
        )
    else
      log.echo(LogLevels.INFO, "no ls/eza/exa command found.")
      return nil
    end
  end

  return impl
end

--- @param filename string
--- @return string[]|nil
local function _directory_previewer(filename)
  if consts.HAS_LSD then
    return {
      "lsd",
      "--color=always",
      "-lha",
      "--header",
      "--",
      filename,
    }
  elseif consts.HAS_EZA then
    return {
      consts.EZA,
      "--color=always",
      "-lha",
      "--",
      filename,
    }
  elseif vim.fn.executable("ls") > 0 then
    return { "ls", "--color=always", "-lha", "--", filename }
  else
    log.echo(LogLevels.INFO, "no ls/eza/exa command found.")
    return nil
  end
end

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
--- @return string[]|nil
local function _file_explorer_previewer(line, context)
  local parsed = consts.HAS_LSD and parsers_helper.parse_lsd(line, context)
    or (
      consts.HAS_EZA and parsers_helper.parse_eza(line, context)
      or parsers_helper.parse_ls(line, context)
    )
  if vim.fn.filereadable(parsed.filename) > 0 then
    local preview = _make_file_previewer(parsed.filename)
    return preview()
  elseif vim.fn.isdirectory(parsed.filename) > 0 then
    return _directory_previewer(parsed.filename)
  else
    return nil
  end
end

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
local function _cd_file_explorer(line, context)
  local parsed = consts.HAS_LSD and parsers_helper.parse_lsd(line, context)
    or (
      consts.HAS_EZA and parsers_helper.parse_eza(line, context)
      or parsers_helper.parse_ls(line, context)
    )
  if vim.fn.isdirectory(parsed.filename) > 0 then
    fs.writefile(context.cwd, parsed.filename)
  end
end

--- @param line string
--- @param context fzfx.FileExplorerPipelineContext
local function _upper_file_explorer(line, context)
  local cwd = fs.readfile(context.cwd) --[[@as string]]
  local target = vim.fn.fnamemodify(cwd, ":h") --[[@as string]]
  -- Windows root folder: `C:\`
  -- Unix/linux root folder: `/`
  local root_len = consts.IS_WINDOWS and 3 or 1
  if vim.fn.isdirectory(target) > 0 and string.len(target) > root_len then
    fs.writefile(context.cwd, target)
  end
end

-- file explorer }

--- @alias fzfx.Options table<string, any>
--- @type fzfx.Options
local Defaults = {
  -- the 'Files' commands
  files = require("fzfx.cfg.files"),

  -- the 'Live Grep' commands
  live_grep = require("fzfx.cfg.live_grep"),

  -- the 'Buffers' commands
  buffers = require("fzfx.cfg.buffers"),

  -- the 'Git Files' commands
  git_files = require("fzfx.cfg.git_files"),

  -- the 'Git Live Grep' commands
  git_live_grep = require("fzfx.cfg.git_live_grep"),

  -- the 'Git Status' commands
  git_status = require("fzfx.cfg.git_status"),

  -- the 'Git Branches' commands
  git_branches = require("fzfx.cfg.git_branches"),

  -- the 'Git Commits' commands
  git_commits = require("fzfx.cfg.git_commits"),

  -- the 'Git Blame' command
  git_blame = require("fzfx.cfg.git_blame"),

  -- the 'Vim Commands' commands
  vim_commands = require("fzfx.cfg.vim_commands"),

  -- the 'Vim KeyMaps' commands
  --- @type fzfx.GroupConfig
  vim_keymaps = require("fzfx.cfg.vim_keymaps"),

  -- the 'Lsp Diagnostics' command
  --- @type fzfx.GroupConfig
  lsp_diagnostics = require("fzfx.cfg.lsp_diagnostics"),

  -- the 'Lsp Definitions' command
  --- @type fzfx.GroupConfig
  lsp_definitions = {
    commands = {
      name = "FzfxLspDefinitions",
      feed = CommandFeedEnum.ARGS,
      opts = {
        bang = true,
        desc = "Search lsp definitions",
      },
    },
    providers = {
      key = "default",
      provider = _make_lsp_locations_provider({
        method = "textDocument/definition",
        capability = "definitionProvider",
      }),
      provider_type = ProviderTypeEnum.LIST,
      line_opts = {
        prepend_icon_by_ft = true,
        prepend_icon_path_delimiter = ":",
        prepend_icon_path_position = 1,
      },
    },
    previewers = {
      previewer = _file_previewer_grep,
      previewer_type = PreviewerTypeEnum.COMMAND_LIST,
      previewer_label = labels_helper.label_rg,
    },
    actions = {
      ["esc"] = actions_helper.nop,
      ["enter"] = actions_helper.edit_rg,
      ["double-click"] = actions_helper.edit_rg,
    },
    fzf_opts = {
      default_fzf_options.multi,
      default_fzf_options.lsp_preview_window,
      "--border=none",
      { "--delimiter", ":" },
      { "--prompt", "Definitions > " },
    },
    win_opts = {
      relative = "cursor",
      height = 0.45,
      width = 1,
      row = 1,
      col = 0,
      border = "none",
      zindex = 51,
    },
    other_opts = {
      context_maker = _lsp_position_context_maker,
    },
  },

  -- the 'Lsp Type Definitions' command
  --- @type fzfx.GroupConfig
  lsp_type_definitions = {
    commands = {
      name = "FzfxLspTypeDefinitions",
      feed = CommandFeedEnum.ARGS,
      opts = {
        bang = true,
        desc = "Search lsp type definitions",
      },
    },
    providers = {
      key = "default",
      provider = _make_lsp_locations_provider({
        method = "textDocument/type_definition",
        capability = "typeDefinitionProvider",
      }),
      provider_type = ProviderTypeEnum.LIST,
      line_opts = {
        prepend_icon_by_ft = true,
        prepend_icon_path_delimiter = ":",
        prepend_icon_path_position = 1,
      },
    },
    previewers = {
      previewer = _file_previewer_grep,
      previewer_type = PreviewerTypeEnum.COMMAND_LIST,
      previewer_label = labels_helper.label_rg,
    },
    actions = {
      ["esc"] = actions_helper.nop,
      ["enter"] = actions_helper.edit_rg,
      ["double-click"] = actions_helper.edit_rg,
    },
    fzf_opts = {
      default_fzf_options.multi,
      default_fzf_options.lsp_preview_window,
      "--border=none",
      { "--delimiter", ":" },
      { "--prompt", "TypeDefinitions > " },
    },
    win_opts = {
      relative = "cursor",
      height = 0.45,
      width = 1,
      row = 1,
      col = 0,
      border = "none",
      zindex = 51,
    },
    other_opts = {
      context_maker = _lsp_position_context_maker,
    },
  },

  -- the 'Lsp References' command
  --- @type fzfx.GroupConfig
  lsp_references = {
    commands = {
      name = "FzfxLspReferences",
      feed = CommandFeedEnum.ARGS,
      opts = {
        bang = true,
        desc = "Search lsp references",
      },
    },
    providers = {
      key = "default",
      provider = _make_lsp_locations_provider({
        method = "textDocument/references",
        capability = "referencesProvider",
      }),
      provider_type = ProviderTypeEnum.LIST,
      line_opts = {
        prepend_icon_by_ft = true,
        prepend_icon_path_delimiter = ":",
        prepend_icon_path_position = 1,
      },
    },
    previewers = {
      previewer = _file_previewer_grep,
      previewer_type = PreviewerTypeEnum.COMMAND_LIST,
      previewer_label = labels_helper.label_rg,
    },
    actions = {
      ["esc"] = actions_helper.nop,
      ["enter"] = actions_helper.edit_rg,
      ["double-click"] = actions_helper.edit_rg,
    },
    fzf_opts = {
      default_fzf_options.multi,
      default_fzf_options.lsp_preview_window,
      "--border=none",
      { "--delimiter", ":" },
      { "--prompt", "References > " },
    },
    win_opts = {
      relative = "cursor",
      height = 0.45,
      width = 1,
      row = 1,
      col = 0,
      border = "none",
      zindex = 51,
    },
    other_opts = {
      context_maker = _lsp_position_context_maker,
    },
  },

  -- the 'Lsp Implementations' command
  --- @type fzfx.GroupConfig
  lsp_implementations = {
    commands = {
      name = "FzfxLspImplementations",
      feed = CommandFeedEnum.ARGS,
      opts = {
        bang = true,
        desc = "Search lsp implementations",
      },
    },
    providers = {
      key = "default",
      provider = _make_lsp_locations_provider({
        method = "textDocument/implementation",
        capability = "implementationProvider",
      }),
      provider_type = ProviderTypeEnum.LIST,
      line_opts = {
        prepend_icon_by_ft = true,
        prepend_icon_path_delimiter = ":",
        prepend_icon_path_position = 1,
      },
    },
    previewers = {
      previewer = _file_previewer_grep,
      previewer_type = PreviewerTypeEnum.COMMAND_LIST,
      previewer_label = labels_helper.label_rg,
    },
    actions = {
      ["esc"] = actions_helper.nop,
      ["enter"] = actions_helper.edit_rg,
      ["double-click"] = actions_helper.edit_rg,
    },
    fzf_opts = {
      default_fzf_options.multi,
      default_fzf_options.lsp_preview_window,
      "--border=none",
      { "--delimiter", ":" },
      { "--prompt", "Implementations > " },
    },
    win_opts = {
      relative = "cursor",
      height = 0.45,
      width = 1,
      row = 1,
      col = 0,
      border = "none",
      zindex = 51,
    },
    other_opts = {
      context_maker = _lsp_position_context_maker,
    },
  },

  -- the 'Lsp Incoming Calls' command
  --- @type fzfx.GroupConfig
  lsp_incoming_calls = {
    commands = {
      name = "FzfxLspIncomingCalls",
      feed = CommandFeedEnum.ARGS,
      opts = {
        bang = true,
        desc = "Search lsp incoming calls",
      },
    },
    providers = {
      key = "default",
      provider = _make_lsp_call_hierarchy_provider({
        method = "callHierarchy/incomingCalls",
        capability = "callHierarchyProvider",
      }),
      provider_type = ProviderTypeEnum.LIST,
      line_opts = {
        prepend_icon_by_ft = true,
        prepend_icon_path_delimiter = ":",
        prepend_icon_path_position = 1,
      },
    },
    previewers = {
      previewer = _file_previewer_grep,
      previewer_type = PreviewerTypeEnum.COMMAND_LIST,
      previewer_label = labels_helper.label_rg,
    },
    actions = {
      ["esc"] = actions_helper.nop,
      ["enter"] = actions_helper.edit_rg,
      ["double-click"] = actions_helper.edit_rg,
    },
    fzf_opts = {
      default_fzf_options.multi,
      default_fzf_options.lsp_preview_window,
      "--border=none",
      { "--delimiter", ":" },
      { "--prompt", "Incoming Calls > " },
    },
    win_opts = {
      relative = "cursor",
      height = 0.45,
      width = 1,
      row = 1,
      col = 0,
      border = "none",
      zindex = 51,
    },
    other_opts = {
      context_maker = _lsp_position_context_maker,
    },
  },

  -- the 'Lsp Outgoing Calls' command
  --- @type fzfx.GroupConfig
  lsp_outgoing_calls = {
    commands = {
      name = "FzfxLspOutgoingCalls",
      feed = CommandFeedEnum.ARGS,
      opts = {
        bang = true,
        desc = "Search lsp outgoing calls",
      },
    },
    providers = {
      key = "default",
      provider = _make_lsp_call_hierarchy_provider({
        method = "callHierarchy/outgoingCalls",
        capability = "callHierarchyProvider",
      }),
      provider_type = ProviderTypeEnum.LIST,
      line_opts = {
        prepend_icon_by_ft = true,
        prepend_icon_path_delimiter = ":",
        prepend_icon_path_position = 1,
      },
    },
    previewers = {
      previewer = _file_previewer_grep,
      previewer_type = PreviewerTypeEnum.COMMAND_LIST,
      previewer_label = labels_helper.label_rg,
    },
    actions = {
      ["esc"] = actions_helper.nop,
      ["enter"] = actions_helper.edit_rg,
      ["double-click"] = actions_helper.edit_rg,
    },
    fzf_opts = {
      default_fzf_options.multi,
      default_fzf_options.lsp_preview_window,
      "--border=none",
      { "--delimiter", ":" },
      { "--prompt", "Outgoing Calls > " },
    },
    win_opts = {
      relative = "cursor",
      height = 0.45,
      width = 1,
      row = 1,
      col = 0,
      border = "none",
      zindex = 51,
    },
    other_opts = {
      context_maker = _lsp_position_context_maker,
    },
  },

  -- the 'File Explorer' commands
  --- @type fzfx.GroupConfig
  file_explorer = {
    commands = {
      -- normal
      {
        name = "FzfxFileExplorer",
        feed = CommandFeedEnum.ARGS,
        opts = {
          bang = true,
          nargs = "?",
          complete = "dir",
          desc = "File explorer (ls -l)",
        },
        default_provider = "filter_hidden",
      },
      {
        name = "FzfxFileExplorerU",
        feed = CommandFeedEnum.ARGS,
        opts = {
          bang = true,
          nargs = "?",
          complete = "dir",
          desc = "File explorer (ls -la)",
        },
        default_provider = "include_hidden",
      },
      -- visual
      {
        name = "FzfxFileExplorerV",
        feed = CommandFeedEnum.VISUAL,
        opts = {
          bang = true,
          range = true,
          desc = "File explorer (ls -l) by visual select",
        },
        default_provider = "filter_hidden",
      },
      {
        name = "FzfxFileExplorerUV",
        feed = CommandFeedEnum.VISUAL,
        opts = {
          bang = true,
          range = true,
          desc = "File explorer (ls -la) by visual select",
        },
        default_provider = "include_hidden",
      },
      -- word
      {
        name = "FzfxFileExplorerW",
        feed = CommandFeedEnum.CWORD,
        opts = {
          bang = true,
          desc = "File explorer (ls -l) by cursor word",
        },
        default_provider = "filter_hidden",
      },
      {
        name = "FzfxFileExplorerUW",
        feed = CommandFeedEnum.CWORD,
        opts = {
          bang = true,
          desc = "File explorer (ls -la) by cursor word",
        },
        default_provider = "include_hidden",
      },
      -- put
      {
        name = "FzfxFileExplorerP",
        feed = CommandFeedEnum.PUT,
        opts = {
          bang = true,
          desc = "File explorer (ls -l) by yank text",
        },
        default_provider = "filter_hidden",
      },
      {
        name = "FzfxFileExplorerUP",
        feed = CommandFeedEnum.PUT,
        opts = {
          bang = true,
          desc = "File explorer (ls -la) by yank text",
        },
        default_provider = "include_hidden",
      },
      -- resume
      {
        name = "FzfxFileExplorerR",
        feed = CommandFeedEnum.RESUME,
        opts = {
          bang = true,
          desc = "File explorer (ls -l) by resume last",
        },
        default_provider = "filter_hidden",
      },
      {
        name = "FzfxFileExplorerUR",
        feed = CommandFeedEnum.RESUME,
        opts = {
          bang = true,
          desc = "File explorer (ls -la) by resume last",
        },
        default_provider = "include_hidden",
      },
    },
    providers = {
      filter_hidden = {
        key = "ctrl-r",
        provider = _make_file_explorer_provider("-lh"),
        provider_type = ProviderTypeEnum.COMMAND,
      },
      include_hidden = {
        key = "ctrl-u",
        provider = _make_file_explorer_provider("-lha"),
        provider_type = ProviderTypeEnum.COMMAND,
      },
    },
    previewers = {
      filter_hidden = {
        previewer = _file_explorer_previewer,
        previewer_type = PreviewerTypeEnum.COMMAND_LIST,
        previewer_label = consts.HAS_LSD and labels_helper.label_lsd
          or (
            consts.HAS_EZA and labels_helper.label_eza
            or labels_helper.label_ls
          ),
      },
      include_hidden = {
        previewer = _file_explorer_previewer,
        previewer_type = PreviewerTypeEnum.COMMAND_LIST,
        previewer_label = consts.HAS_LSD and labels_helper.label_lsd
          or (
            consts.HAS_EZA and labels_helper.label_eza
            or labels_helper.label_ls
          ),
      },
    },
    interactions = {
      cd = {
        key = "alt-l",
        interaction = _cd_file_explorer,
        reload_after_execute = true,
      },
      upper = {
        key = "alt-h",
        interaction = _upper_file_explorer,
        reload_after_execute = true,
      },
    },
    actions = {
      ["esc"] = actions_helper.nop,
      ["enter"] = actions_helper.edit_ls,
      ["double-click"] = actions_helper.edit_ls,
    },
    fzf_opts = {
      default_fzf_options.multi,
      { "--prompt", paths.shorten() .. " > " },
      function()
        local n = 0
        if consts.HAS_LSD or consts.HAS_EZA or consts.HAS_LS then
          n = n + 1
        end
        if consts.HAS_ECHO then
          n = n + 1
        end
        return n > 0 and string.format("--header-lines=%d", n) or nil
      end,
    },
    other_opts = {
      context_maker = _file_explorer_context_maker,
    },
  },

  -- the 'Yank History' commands
  yank_history = {
    other_opts = {
      maxsize = 100,
    },
  },

  -- the 'Users' commands
  users = nil,

  -- FZF_DEFAULT_OPTS
  fzf_opts = {
    "--ansi",
    "--info=inline",
    "--layout=reverse",
    "--border=rounded",
    "--height=100%",
    default_fzf_options.toggle,
    default_fzf_options.toggle_all,
    default_fzf_options.toggle_preview,
    default_fzf_options.preview_half_page_down,
    default_fzf_options.preview_half_page_up,
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
    border = { "fg", "Ignore" },
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
    --     nf-fa-file_text_o               \uf0f6 (default)
    --     nf-fa-file_o                    \uf016
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
    -- nvim float window options
    -- see: https://neovim.io/doc/user/api.html#nvim_open_win()
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
      --
      -- when relative is 'editor' or 'win', the anchor is the center position, not default 'NW' (north west).
      -- because 'NW' is a little bit complicated for users to calculate the position, usually we just put the popup window in the center of editor.
      --
      -- 1. if -0.5 <= r/c <= 0.5, evaluate proportionally according to editor's lines and columns.
      --    e.g. shift rows = r * lines, shift columns = c * columns.
      --
      -- 2. if r/c <= -1 or r/c >= 1, evaluate as absolute rows/columns to be shift.
      --    e.g. you can easily set 'row = -vim.o.cmdheight' to move popup window to up 1~2 lines (based on your 'cmdheight' option).
      --    this is especially useful when popup window is too big and conflicts with command/status line at bottom.
      --
      -- 3. r/c cannot be in range (-1, -0.5) or (0.5, 1), it makes no sense.
      --
      -- when relative is 'cursor', the anchor is 'NW' (north west).
      -- because we just want to put the popup window relative to the cursor.
      -- so 'row' and 'col' will be directly passed to `vim.api.nvim_open_win` API without any pre-processing.
      --
      row = 0,
      col = 0,
      border = "none",
      zindex = 51,
    },
  },

  -- environment variables
  env = {
    --- @type string|nil
    nvim = nil,
    --- @type string|nil
    fzf = nil,
  },

  cache = {
    dir = paths.join(vim.fn.stdpath("data"), "fzfx.nvim"),
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

--- @param options fzfx.Options?
--- @return fzfx.Options
local function setup(options)
  Configs = vim.tbl_deep_extend("force", Defaults, options or {})
  return Configs
end

--- @return fzfx.Options
local function get_config()
  return Configs
end

--- @return fzfx.Options
local function get_defaults()
  return Defaults
end

local M = {
  setup = setup,
  get_config = get_config,
  get_defaults = get_defaults,

  -- files
  _default_bat_style_theme = _default_bat_style_theme,
  _make_file_previewer = _make_file_previewer,
  _file_previewer = _file_previewer,

  -- live grep
  _make_live_grep_provider = _make_live_grep_provider,
  _file_previewer_grep = _file_previewer_grep,

  -- buffers
  _is_valid_buffer_number = _is_valid_buffer_number,
  _buffers_provider = _buffers_provider,
  _delete_buffer = _delete_buffer,

  -- git files
  _make_git_files_provider = _make_git_files_provider,

  -- git live grep
  _git_live_grep_provider = _git_live_grep_provider,

  -- git branches
  _make_git_branches_provider = _make_git_branches_provider,
  _git_branches_previewer = _git_branches_previewer,

  -- git commits
  _make_git_commits_provider = _make_git_commits_provider,
  _make_git_commits_previewer = _make_git_commits_previewer,
  _git_commits_previewer = _git_commits_previewer,

  -- git blame
  _git_blame_provider = _git_blame_provider,

  -- lsp diagnostics
  _make_lsp_diagnostic_signs = _make_lsp_diagnostic_signs,
  _process_lsp_diagnostic_item = _process_lsp_diagnostic_item,
  _make_lsp_diagnostics_provider = _make_lsp_diagnostics_provider,

  -- lsp locations
  _is_lsp_range = _is_lsp_range,
  _is_lsp_location = _is_lsp_location,
  _is_lsp_locationlink = _is_lsp_locationlink,
  _lsp_location_render_line = _lsp_range_render_line,
  _lsp_position_context_maker = _lsp_position_context_maker,
  _render_lsp_location_line = _render_lsp_location_line,
  _make_lsp_locations_provider = _make_lsp_locations_provider,

  -- lsp call hierarchy
  _is_lsp_call_hierarchy_item = _is_lsp_call_hierarchy_item,
  _is_lsp_call_hierarchy_incoming_call = _is_lsp_call_hierarchy_incoming_call,
  _is_lsp_call_hierarchy_outgoing_call = _is_lsp_call_hierarchy_outgoing_call,
  _render_lsp_call_hierarchy_line = _render_lsp_call_hierarchy_line,
  _retrieve_lsp_call_hierarchy_item_and_from_ranges = _retrieve_lsp_call_hierarchy_item_and_from_ranges,
  _make_lsp_call_hierarchy_provider = _make_lsp_call_hierarchy_provider,

  -- commands
  _parse_vim_ex_command_name = _parse_vim_ex_command_name,
  _get_vim_ex_commands = _get_vim_ex_commands,
  _is_ex_command_output_header = _is_ex_command_output_header,
  _parse_ex_command_output_header = _parse_ex_command_output_header,
  _parse_ex_command_output_lua_function_definition = _parse_ex_command_output_lua_function_definition,
  _parse_ex_command_output = _parse_ex_command_output,
  _get_vim_user_commands = _get_vim_user_commands,
  _render_vim_commands_column_opts = _render_vim_commands_column_opts,
  _render_vim_commands_columns_status = _render_vim_commands_columns_status,
  _render_vim_commands = _render_vim_commands,
  _vim_commands_lua_function_previewer = _vim_commands_lua_function_previewer,
  _vim_commands_context_maker = _vim_commands_context_maker,
  _get_vim_commands = _get_vim_commands,

  -- keymaps
  _parse_map_command_output_line = _parse_map_command_output_line,
  _get_vim_keymaps = _get_vim_keymaps,
  _render_vim_keymaps_column_opts = _render_vim_keymaps_column_opts,
  _render_vim_keymaps_columns_status = _render_vim_keymaps_columns_status,
  _render_vim_keymaps = _render_vim_keymaps,
  _vim_keymaps_context_maker = _vim_keymaps_context_maker,
  _vim_keymaps_lua_function_previewer = _vim_keymaps_lua_function_previewer,
  _make_git_status_provider = _make_git_status_provider,
  _get_delta_width = _get_delta_width,
  _git_status_previewer = _git_status_previewer,
  _make_vim_keymaps_provider = _make_vim_keymaps_provider,
  _vim_keymaps_previewer = _vim_keymaps_previewer,

  -- file explorer
  _file_explorer_context_maker = _file_explorer_context_maker,
  _make_file_explorer_provider = _make_file_explorer_provider,
  _directory_previewer = _directory_previewer,
  _file_explorer_previewer = _file_explorer_previewer,
  _cd_file_explorer = _cd_file_explorer,
  _upper_file_explorer = _upper_file_explorer,
}

return M
