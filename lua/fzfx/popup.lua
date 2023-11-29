local nums = require("fzfx.lib.numbers")
local nvims = require("fzfx.lib.nvims")
local fs = require("fzfx.lib.filesystems")

local log = require("fzfx.log")
local conf = require("fzfx.config")
local fzf_helpers = require("fzfx.fzf_helpers")

--- @class PopupWindowConfig
--- @field anchor "NW"|nil
--- @field relative "editor"|"win"|"cursor"|nil
--- @field width integer?
--- @field height integer?
--- @field row integer?
--- @field col integer?
--- @field style "minimal"|nil
--- @field border "none"|"single"|"double"|"rounded"|"solid"|"shadow"|nil
--- @field zindex integer?

--- @package
--- @param value number
--- @param base integer
--- @param minimal integer?
--- @return integer
local function _make_window_size(value, base, minimal)
  minimal = minimal or 3
  return nums.bound(
    value > 1 and value or math.floor(base * value),
    minimal,
    base
  )
end

--- @param opts fzfx.Options
--- @return PopupWindowConfig
local function _make_cursor_window_config(opts)
  --- @type "cursor"
  local relative = opts.relative
  local total_width = vim.api.nvim_win_get_width(0)
  local total_height = vim.api.nvim_win_get_height(0)

  local width = _make_window_size(opts.width, total_width)
  local height = _make_window_size(opts.height, total_height)
  if opts.row < 0 then
    log.throw("invalid option (win_opts.row < 0): %s!", vim.inspect(opts))
  end
  local row = opts.row

  if opts.col < 0 then
    log.throw("invalid option (win_opts.col < 0): %s!", vim.inspect(opts))
  end
  local col = opts.col

  --- @type PopupWindowConfig
  local pw_config = {
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
  -- log.debug(
  --     "|fzfx.popup - make_popup_window_opts_relative_to_cursor| (origin) win_opts:%s, pw_config:%s",
  --     vim.inspect(opts),
  --     vim.inspect(pw_config)
  -- )
  return pw_config
end

--- @param maxsize integer
--- @param size integer
--- @param offset number
local function _make_window_center_shift(maxsize, size, offset)
  local base = math.floor((maxsize - size) * 0.5)
  if offset >= 0 then
    local shift = offset < 1 and math.floor((maxsize - size) * offset) or offset
    return nums.bound(base + shift, 0, maxsize - size)
  else
    local shift = offset > -1 and math.ceil((maxsize - size) * offset) or offset
    return nums.bound(base + shift, 0, maxsize - size)
  end
end

--- @param opts fzfx.Options
--- @return PopupWindowConfig
local function _make_center_window_config(opts)
  --- @type "editor"|"win"
  local relative = opts.relative or "editor"

  local total_width = vim.o.columns
  local total_height = vim.o.lines
  if relative == "win" then
    total_width = vim.api.nvim_win_get_width(0)
    total_height = vim.api.nvim_win_get_height(0)
  end

  local width = _make_window_size(opts.width, total_width)
  local height = _make_window_size(opts.height, total_height)

  if
    (opts.row > -1 and opts.row < -0.5) or (opts.row > 0.5 and opts.row < 1)
  then
    log.throw("invalid option (win_opts.row): %s!", vim.inspect(opts))
  end
  local row = _make_window_center_shift(total_height, height, opts.row)
  -- log.debug(
  --     "|fzfx.popup - make_popup_window_opts_relative_to_center| row:%s, win_opts:%s, total_height:%s, height:%s",
  --     vim.inspect(row),
  --     vim.inspect(opts),
  --     vim.inspect(total_height),
  --     vim.inspect(height)
  -- )

  if
    (opts.col > -1 and opts.col < -0.5) or (opts.col > 0.5 and opts.col < 1)
  then
    log.throw("invalid option (win_opts.col): %s!", vim.inspect(opts))
  end
  local col = _make_window_center_shift(total_width, width, opts.col)

  --- @type PopupWindowConfig
  local pw_config = {
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
  -- log.debug(
  --     "|fzfx.popup - make_popup_window_opts_relative_to_center| (origin) win_opts:%s, pw_config:%s",
  --     vim.inspect(opts),
  --     vim.inspect(pw_config)
  -- )
  return pw_config
end

--- @param win_opts fzfx.Options
--- @return PopupWindowConfig
local function _make_window_config(win_opts)
  --- @type "editor"|"win"|"cursor"
  local relative = win_opts.relative or "editor"

  if relative == "cursor" then
    return _make_cursor_window_config(win_opts)
  elseif relative == "editor" or relative == "win" then
    return _make_center_window_config(win_opts)
  else
    log.throw(
      "failed to make popup window opts, unsupported relative value %s.",
      vim.inspect(relative)
    )
    ---@diagnostic disable-next-line: missing-return
  end
end

--- @type table<integer, PopupWindow>
local PopupWindowInstances = {}

--- @class PopupWindow
--- @field window_opts_context fzfx.WindowOptsContext?
--- @field bufnr integer?
--- @field winnr integer?
--- @field _saved_win_opts fzfx.Options
--- @field _resizing boolean
local PopupWindow = {}

--- @package
--- @param win_opts fzfx.Options?
--- @return PopupWindow
function PopupWindow:new(win_opts)
  -- check executable: nvim, fzf
  fzf_helpers.nvim_exec()
  fzf_helpers.fzf_exec()

  -- save current window context
  local window_opts_context = nvims.WindowOptsContext:save()

  --- @type integer
  local bufnr = vim.api.nvim_create_buf(false, true)
  -- setlocal bufhidden=wipe nobuflisted
  -- setft=fzf
  nvims.set_buf_option(bufnr, "bufhidden", "wipe")
  nvims.set_buf_option(bufnr, "buflisted", false)
  nvims.set_buf_option(bufnr, "filetype", "fzf")

  local merged_win_opts = vim.tbl_deep_extend(
    "force",
    vim.deepcopy(conf.get_config().popup.win_opts),
    vim.deepcopy(win_opts or {})
  )
  local popup_window_config = _make_window_config(merged_win_opts)

  --- @type integer
  local winnr = vim.api.nvim_open_win(bufnr, true, popup_window_config)

  --- setlocal nospell nonumber
  --- set winhighlight='Pmenu:,Normal:Normal'
  --- set colorcolumn=''
  nvims.set_win_option(winnr, "spell", false)
  nvims.set_win_option(winnr, "number", false)
  nvims.set_win_option(winnr, "winhighlight", "Pmenu:,Normal:Normal")
  nvims.set_win_option(winnr, "colorcolumn", "")

  local o = {
    window_opts_context = window_opts_context,
    bufnr = bufnr,
    winnr = winnr,
    _saved_win_opts = merged_win_opts,
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

--- @class Popup
--- @field popup_window PopupWindow?
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

--- @alias OnPopupExit fun(last_query:string):nil
--- @param win_opts fzfx.Options?
--- @param source string
--- @param fzf_opts fzfx.Options
--- @param actions fzfx.Options
--- @param context PipelineContext
--- @param on_popup_exit OnPopupExit?
--- @return Popup
function Popup:new(win_opts, source, fzf_opts, actions, context, on_popup_exit)
  local result = vim.fn.tempname() --[[@as string]]
  local fzf_command = _make_fzf_command(fzf_opts, actions, result)
  local popup_window = PopupWindow:new(win_opts)

  local function on_fzf_exit(jobid2, exitcode, event)
    log.debug(
      "|fzfx.popup - Popup:new| fzf exit, jobid2:%s, exitcode:%s, event:%s",
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
      "|fzfx.popup - Popup:new.on_fzf_exit| result %s must be readable",
      vim.inspect(result)
    )
    local lines = fs.readlines(result --[[@as string]]) --[[@as table]]
    log.debug(
      "|fzfx.popup - Popup:new| fzf exit, result:%s, lines:%s",
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
      local action_callback = actions[action_key]
      if type(action_callback) ~= "function" then
        log.throw(
          "wrong action type on key: %s, must be function(%s): %s",
          vim.inspect(action_key),
          type(action_callback),
          vim.inspect(action_callback)
        )
      else
        local ok, cb_err = pcall(action_callback, action_lines, context)
        if not ok then
          log.throw(
            "failed to run action on callback(%s) with lines(%s)! %s",
            vim.inspect(action_callback),
            vim.inspect(action_lines),
            vim.inspect(cb_err)
          )
        end
      end
    else
      log.err("unknown action key: %s", vim.inspect(action_key))
    end
    if type(on_popup_exit) == "function" then
      on_popup_exit(last_query)
    end
  end

  -- save shell opts
  local shell_opts_context = nvims.ShellOptsContext:save()
  local prev_fzf_default_opts = vim.env.FZF_DEFAULT_OPTS
  local prev_fzf_default_command = vim.env.FZF_DEFAULT_COMMAND
  vim.env.FZF_DEFAULT_OPTS = fzf_helpers.make_fzf_default_opts()
  vim.env.FZF_DEFAULT_COMMAND = source
  log.debug(
    "|fzfx.popup - Popup:new| $FZF_DEFAULT_OPTS:%s",
    vim.inspect(vim.env.FZF_DEFAULT_OPTS)
  )
  log.debug(
    "|fzfx.popup - Popup:new| $FZF_DEFAULT_COMMAND:%s",
    vim.inspect(vim.env.FZF_DEFAULT_COMMAND)
  )
  log.debug("|fzfx.popup - Popup:new| fzf_command:%s", vim.inspect(fzf_command))

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

--- @return table<integer, PopupWindow>
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
  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    pattern = { "*" },
    callback = resize_all_popup_window_instances,
  })
end

local M = {
  _make_window_size = _make_window_size,
  _make_window_center_shift = _make_window_center_shift,
  _make_cursor_window_config = _make_cursor_window_config,
  _make_center_window_config = _make_center_window_config,
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
