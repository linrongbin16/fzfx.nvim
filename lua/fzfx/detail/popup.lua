local numbers = require("fzfx.commons.numbers")
local apis = require("fzfx.commons.apis")
local fileios = require("fzfx.commons.fileios")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")
local fzf_helpers = require("fzfx.detail.fzf_helpers")

-- WindowOptsContext {

--- @class fzfx.WindowOptsContext
--- @field bufnr integer
--- @field tabnr integer
--- @field winnr integer
local WindowOptsContext = {}

--- @return fzfx.WindowOptsContext
function WindowOptsContext:save()
  local o = {
    bufnr = vim.api.nvim_get_current_buf(),
    winnr = vim.api.nvim_get_current_win(),
    tabnr = vim.api.nvim_get_current_tabpage(),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function WindowOptsContext:restore()
  if vim.api.nvim_tabpage_is_valid(self.tabnr) then
    vim.api.nvim_set_current_tabpage(self.tabnr)
  end
  if vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_set_current_win(self.winnr)
  end
end

-- WindowOptsContext }

-- ShellOptsContext {

--- @class fzfx.ShellOptsContext
--- @field shell string?
--- @field shellslash string?
--- @field shellcmdflag string?
--- @field shellxquote string?
--- @field shellquote string?
--- @field shellredir string?
--- @field shellpipe string?
--- @field shellxescape string?
local ShellOptsContext = {}

--- @return fzfx.ShellOptsContext
function ShellOptsContext:save()
  local o = constants.IS_WINDOWS
      and {
        shell = vim.o.shell,
        shellslash = vim.o.shellslash,
        shellcmdflag = vim.o.shellcmdflag,
        shellxquote = vim.o.shellxquote,
        shellquote = vim.o.shellquote,
        shellredir = vim.o.shellredir,
        shellpipe = vim.o.shellpipe,
        shellxescape = vim.o.shellxescape,
      }
    or {
      shell = vim.o.shell,
    }
  setmetatable(o, self)
  self.__index = self

  if constants.IS_WINDOWS then
    vim.o.shell = "cmd.exe"
    vim.o.shellslash = false
    vim.o.shellcmdflag = "/s /c"
    vim.o.shellxquote = '"'
    vim.o.shellquote = ""
    vim.o.shellredir = ">%s 2>&1"
    vim.o.shellpipe = "2>&1| tee"
    vim.o.shellxescape = ""
  else
    vim.o.shell = "sh"
  end

  return o
end

function ShellOptsContext:restore()
  if constants.IS_WINDOWS then
    vim.o.shell = self.shell
    vim.o.shellslash = self.shellslash
    vim.o.shellcmdflag = self.shellcmdflag
    vim.o.shellxquote = self.shellxquote
    vim.o.shellquote = self.shellquote
    vim.o.shellredir = self.shellredir
    vim.o.shellpipe = self.shellpipe
    vim.o.shellxescape = self.shellxescape
  else
    vim.o.shell = self.shell
  end
end

-- ShellOptsContext }

--- @package
--- @param value number
--- @param size integer
--- @return integer
local function _get_window_size(value, size)
  return numbers.bound(value > 1 and value or math.floor(size * value), 3, size)
end

--- @param opts fzfx.WindowOpts
--- @return fzfx.PopupWindowConfig
local function _make_cursor_config(opts)
  local relative = "cursor"
  local total_width = vim.api.nvim_win_get_width(0)
  local total_height = vim.api.nvim_win_get_height(0)
  local width = _get_window_size(opts.width, total_width)
  local height = _get_window_size(opts.height, total_height)

  log.ensure(
    opts.row >= 0,
    "window row (%s) opts must >= 0!",
    vim.inspect(opts)
  )
  log.ensure(
    opts.row >= 0,
    "window col (%s) opts must >= 0!",
    vim.inspect(opts)
  )
  local row = opts.row
  local col = opts.col

  return {
    anchor = "NW",
    relative = relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border,
    zindex = opts.zindex,
  }
end

--- @param maxsize integer
--- @param size integer
--- @param offset number
local function _make_window_center_shift(maxsize, size, offset)
  local base = math.floor((maxsize - size) * 0.5)
  if offset >= 0 then
    local shift = offset < 1 and math.floor((maxsize - size) * offset) or offset
    return numbers.bound(base + shift, 0, maxsize - size)
  else
    local shift = offset > -1 and math.ceil((maxsize - size) * offset) or offset
    return numbers.bound(base + shift, 0, maxsize - size)
  end
end

--- @param win_opts fzfx.WindowOpts
--- @return fzfx.PopupWindowConfig
local function _make_center_config(win_opts)
  local relative = win_opts.relative or "editor" --[[@as "editor"|"win"]]
  local total_width = vim.o.columns
  local total_height = vim.o.lines
  if relative == "win" then
    total_width = vim.api.nvim_win_get_width(0)
    total_height = vim.api.nvim_win_get_height(0)
  end

  local width = _get_window_size(win_opts.width, total_width)
  local height = _get_window_size(win_opts.height, total_height)

  if
    (win_opts.row > -1 and win_opts.row < -0.5)
    or (win_opts.row > 0.5 and win_opts.row < 1)
  then
    log.throw("invalid option (win_opts.row): %s!", vim.inspect(win_opts))
  end
  local row = _make_window_center_shift(total_height, height, win_opts.row)
  -- log.debug(
  --     "|fzfx.popup - make_popup_window_opts_relative_to_center| row:%s, win_opts:%s, total_height:%s, height:%s",
  --     vim.inspect(row),
  --     vim.inspect(opts),
  --     vim.inspect(total_height),
  --     vim.inspect(height)
  -- )

  if
    (win_opts.col > -1 and win_opts.col < -0.5)
    or (win_opts.col > 0.5 and win_opts.col < 1)
  then
    log.throw("invalid option (win_opts.col): %s!", vim.inspect(win_opts))
  end
  local col = _make_window_center_shift(total_width, width, win_opts.col)

  --- @type fzfx.PopupWindowConfig
  local pw_config = {
    anchor = "NW",
    relative = relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = win_opts.border,
    zindex = win_opts.zindex,
  }
  -- log.debug(
  --     "|fzfx.popup - make_popup_window_opts_relative_to_center| (origin) win_opts:%s, pw_config:%s",
  --     vim.inspect(opts),
  --     vim.inspect(pw_config)
  -- )
  return pw_config
end

--- @alias fzfx.PopupWindowConfig {anchor:"NW"?,relative:"editor"|"win"|"cursor"|nil,width:integer?,height:integer?,row:integer?,col:integer?,style:"minimal"?,border:"none"|"single"|"double"|"rounded"|"solid"|"shadow"|nil,zindex:integer?}
--
--- @param win_opts fzfx.WindowOpts
--- @return fzfx.PopupWindowConfig
local function _make_window_config(win_opts)
  --- @type "editor"|"win"|"cursor"
  local relative = win_opts.relative or "editor"

  if relative == "cursor" then
    return _make_cursor_config(win_opts)
  elseif relative == "editor" or relative == "win" then
    return _make_center_config(win_opts)
  else
    log.throw(
      "failed to make popup window opts, unsupported relative value %s.",
      vim.inspect(relative)
    )
    ---@diagnostic disable-next-line: missing-return
  end
end

--- @type table<integer, fzfx.PopupWindow>
local PopupWindowInstances = {}

--- @class fzfx.PopupWindow
--- @field window_opts_context fzfx.WindowOptsContext?
--- @field bufnr integer?
--- @field winnr integer?
--- @field _saved_win_opts fzfx.WindowOpts
--- @field _resizing boolean
local PopupWindow = {}

--- @alias fzfx.WindowOpts {relative:"editor"|"win"|"cursor",win:integer?,row:number,col:number,height:integer,width:integer,zindex:integer,border:string,title:string?,title_pos:string?,noautocmd:boolean?}
--- @package
--- @param win_opts fzfx.WindowOpts
--- @return fzfx.PopupWindow
function PopupWindow:new(win_opts)
  -- check executable: nvim, fzf
  fzf_helpers.nvim_exec()
  fzf_helpers.fzf_exec()

  -- save current window context
  local window_opts_context = WindowOptsContext:save()

  --- @type integer
  local bufnr = vim.api.nvim_create_buf(false, true)
  -- setlocal bufhidden=wipe nobuflisted
  -- setft=fzf
  apis.set_buf_option(bufnr, "bufhidden", "wipe")
  apis.set_buf_option(bufnr, "buflisted", false)
  apis.set_buf_option(bufnr, "filetype", "fzf")

  local popup_window_config = _make_window_config(win_opts or {})

  local total_width = popup_window_config.width
  popup_window_config.width = math.floor(total_width / 2)
  local winnr = vim.api.nvim_open_win(bufnr, true, popup_window_config)
  local previewer_winnr =
    vim.api.nvim_open_win(bufnr, true, popup_window_config)

  --- setlocal nospell nonumber
  --- set winhighlight='Pmenu:,Normal:Normal'
  --- set colorcolumn=''
  apis.set_win_option(winnr, "spell", false)
  apis.set_win_option(winnr, "number", false)
  apis.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
  apis.set_win_option(winnr, "colorcolumn", "")

  local o = {
    window_opts_context = window_opts_context,
    bufnr = bufnr,
    winnr = winnr,
    _saved_win_opts = win_opts,
    _resizing = false,
  }
  setmetatable(o, self)
  self.__index = self

  PopupWindowInstances[winnr] = o
  return o
end

function PopupWindow:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))

  if vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_close(self.winnr, true)
    -- else
    --     log.debug(
    --         "cannot close invalid popup window! %s",
    --         vim.inspect(self.winnr)
    --     )
  end

  ---@diagnostic disable-next-line: undefined-field
  self.window_opts_context:restore()

  local instance = PopupWindowInstances[self.winnr]
  if instance then
    PopupWindowInstances[self.winnr] = nil
  end
end

function PopupWindow:resize()
  if self._resizing then
    return
  end
  self._resizing = true
  local new_popup_window_config = _make_window_config(self._saved_win_opts)
  vim.api.nvim_win_set_config(self.winnr, new_popup_window_config)
  vim.schedule(function()
    self._resizing = false
  end)
end

--- @class fzfx.Popup
--- @field popup_window fzfx.PopupWindow?
--- @field source string|string[]|nil
--- @field jobid integer|nil
--- @field result string|nil
local Popup = {}

--- @param actions table<string, any>
--- @return string[][]
local function _make_expect_keys(actions)
  local expect_keys = {}
  if type(actions) == "table" then
    for name, _ in pairs(actions) do
      table.insert(expect_keys, { "--expect", name })
    end
  end
  return expect_keys
end

--- @param fzf_opts string[]|string[][]
--- @param actions table<string, any>
--- @return string[]
local function _merge_fzf_actions(fzf_opts, actions)
  local expect_keys = _make_expect_keys(actions)
  local merged_opts = vim.list_extend(vim.deepcopy(fzf_opts), expect_keys)
  -- log.debug(
  --     "|fzfx.popup - _merge_fzf_actions| fzf_opts:%s, actions:%s, merged_opts:%s",
  --     vim.inspect(fzf_opts),
  --     vim.inspect(actions),
  --     vim.inspect(merged_opts)
  -- )
  return merged_opts
end

--- @param fzf_opts fzfx.Options
--- @param actions fzfx.Options
--- @param result string
--- @return string
local function _make_fzf_command(fzf_opts, actions, result)
  local final_opts = _merge_fzf_actions(fzf_opts, actions)
  local final_opts_string = fzf_helpers.make_fzf_opts(final_opts)
  -- log.debug(
  --     "|fzfx.popup - _make_fzf_command| final_opts:%s, builder:%s",
  --     vim.inspect(final_opts),
  --     vim.inspect(final_opts_string)
  -- )
  local command = string.format(
    "%s %s >%s",
    fzf_helpers.fzf_exec(),
    final_opts_string,
    result
  )
  -- log.debug(
  --     "|fzfx.popup - _make_fzf_command| command:%s",
  --     vim.inspect(command)
  -- )
  return command
end

--- @alias fzfx.OnPopupExit fun(last_query:string):nil
--- @param win_opts fzfx.WindowOpts
--- @param source string
--- @param fzf_opts fzfx.Options
--- @param actions fzfx.Options
--- @param context fzfx.PipelineContext
--- @param on_popup_exit fzfx.OnPopupExit?
--- @return fzfx.Popup
function Popup:new(win_opts, source, fzf_opts, actions, context, on_popup_exit)
  local result = vim.fn.tempname() --[[@as string]]
  local fzf_command = _make_fzf_command(fzf_opts, actions, result)
  local popup_window = PopupWindow:new(win_opts)

  local function on_fzf_exit(jobid2, exitcode, event)
    log.debug(
      "|Popup:new| fzf exit, jobid2:%s, exitcode:%s, event:%s",
      vim.inspect(jobid2),
      vim.inspect(exitcode),
      vim.inspect(event)
    )
    if exitcode > 1 and (exitcode ~= 130 and exitcode ~= 129) then
      log.err(
        "command '%s' exit with code: %d, event: %s",
        vim.inspect(fzf_command),
        vim.inspect(exitcode),
        vim.inspect(event)
      )
      return
    end

    -- press <ESC> if still in fzf terminal
    local esc_key = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
    if vim.o.buftype == "terminal" and vim.o.filetype == "fzf" then
      vim.api.nvim_feedkeys(esc_key, "x", false)
    end

    -- close popup window and restore old window
    popup_window:close()

    -- -- press <ESC> if in insert mode
    -- vim.api.nvim_feedkeys(esc_key, "x", false)

    log.ensure(
      vim.fn.filereadable(result) > 0,
      "|Popup:new.on_fzf_exit| result %s must be readable",
      vim.inspect(result)
    )
    local lines = fileios.readlines(result --[[@as string]]) --[[@as table]]
    log.debug(
      "|Popup:new| fzf exit, result:%s, lines:%s",
      vim.inspect(result),
      vim.inspect(lines)
    )
    if (exitcode == 130 or exitcode == 129) and #lines == 0 then
      return
    end
    local last_query = vim.trim(lines[1])
    local action_key = vim.trim(lines[2])
    local action_lines = vim.list_slice(lines, 3)
    -- log.debug(
    --     "|fzfx.popup - Popup:new.on_fzf_exit| action_key:%s, action_lines:%s",
    --     vim.inspect(action_key),
    --     vim.inspect(action_lines)
    -- )
    if actions[action_key] ~= nil then
      vim.schedule(function()
        local action_callback = actions[action_key]
        assert(
          type(action_callback) == "function",
          string.format(
            "wrong action type on key: %s, must be function(%s): %s",
            vim.inspect(action_key),
            type(action_callback),
            vim.inspect(action_callback)
          )
        )
        local ok, cb_err = pcall(action_callback, action_lines, context)
        assert(
          ok,
          string.format(
            "failed to run action on callback(%s) with lines(%s)! %s",
            vim.inspect(action_callback),
            vim.inspect(action_lines),
            vim.inspect(cb_err)
          )
        )
      end)
    else
      log.err("unknown action key: %s", vim.inspect(action_key))
    end
    if type(on_popup_exit) == "function" then
      vim.schedule(function()
        on_popup_exit(last_query)
      end)
    end
  end

  -- save shell opts
  local shell_opts_context = ShellOptsContext:save()
  local prev_fzf_default_opts = vim.env.FZF_DEFAULT_OPTS
  local prev_fzf_default_command = vim.env.FZF_DEFAULT_COMMAND
  vim.env.FZF_DEFAULT_OPTS = fzf_helpers.make_fzf_default_opts()
  vim.env.FZF_DEFAULT_COMMAND = source
  log.debug(
    "|Popup:new| $FZF_DEFAULT_OPTS:%s",
    vim.inspect(vim.env.FZF_DEFAULT_OPTS)
  )
  log.debug(
    "|Popup:new| $FZF_DEFAULT_COMMAND:%s",
    vim.inspect(vim.env.FZF_DEFAULT_COMMAND)
  )
  log.debug("|Popup:new| fzf_command:%s", vim.inspect(fzf_command))

  -- launch
  local jobid = vim.fn.termopen(fzf_command, { on_exit = on_fzf_exit }) --[[@as integer ]]

  -- restore shell opts
  shell_opts_context:restore()
  vim.env.FZF_DEFAULT_COMMAND = prev_fzf_default_command
  vim.env.FZF_DEFAULT_OPTS = prev_fzf_default_opts

  vim.cmd([[ startinsert ]])

  local o = {
    popup_window = popup_window,
    source = source,
    jobid = jobid,
    result = result,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function Popup:close()
  -- log.debug("|fzfx.popup - Popup:close| self:%s", vim.inspect(self))
end

--- @return table<integer, fzfx.PopupWindow>
local function _get_all_popup_window_instances()
  return PopupWindowInstances
end

local function _remove_all_popup_window_instances()
  PopupWindowInstances = {}
end

--- @return integer
local function _count_all_popup_window_instances()
  local n = 0
  for _, p in pairs(PopupWindowInstances) do
    n = n + 1
  end
  return n
end

local function resize_all_popup_window_instances()
  -- log.debug(
  --     "|fzfx.popup - resize_all_popup_window_instances| instances:%s",
  --     vim.inspect(PopupWindowInstances)
  -- )
  for winnr, popup_win in pairs(PopupWindowInstances) do
    if winnr and popup_win then
      popup_win:resize()
    end
  end
end

local function setup()
  vim.api.nvim_create_autocmd({ "VimResized" }, {
    pattern = { "*" },
    callback = resize_all_popup_window_instances,
  })
  if vim.fn.has("nvim-0.9") > 0 then
    vim.api.nvim_create_autocmd({ "WinResized" }, {
      pattern = { "*" },
      callback = resize_all_popup_window_instances,
    })
  end
end

local M = {
  _make_window_size = _get_window_size,
  _make_window_center_shift = _make_window_center_shift,
  _make_cursor_config = _make_cursor_config,
  _make_center_config = _make_center_config,
  _make_window_config = _make_window_config,
  _get_all_popup_window_instances = _get_all_popup_window_instances,
  _remove_all_popup_window_instances = _remove_all_popup_window_instances,
  _count_all_popup_window_instances = _count_all_popup_window_instances,
  _make_expect_keys = _make_expect_keys,
  _merge_fzf_actions = _merge_fzf_actions,
  _make_fzf_command = _make_fzf_command,
  PopupWindow = PopupWindow,
  Popup = Popup,
  setup = setup,
}

return M
