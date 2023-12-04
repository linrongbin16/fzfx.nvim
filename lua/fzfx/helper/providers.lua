local consts = require("fzfx.lib.constants")
local strs = require("fzfx.lib.strings")
local nvims = require("fzfx.lib.nvims")
local cmds = require("fzfx.lib.commands")
local colors = require("fzfx.lib.colors")
local paths = require("fzfx.lib.paths")
local fs = require("fzfx.lib.filesystems")
local tbls = require("fzfx.lib.tables")

local log = require("fzfx.log")
local LogLevels = require("fzfx.log").LogLevels

local parsers_helper = require("fzfx.helper.parsers")
local queries_helper = require("fzfx.helper.queries")
local actions_helper = require("fzfx.helper.actions")
local labels_helper = require("fzfx.helper.previewer_labels")

local M = {}

-- common error message

M.INVALID_BUFFER_ERROR = "invalid buffer(%s)."

-- files {

-- "fd . -cnever -tf -tl -L -i"
M.RESTRICTED_FD = {
  consts.FD,
  ".",
  "-cnever",
  "-tf",
  "-tl",
  "-L",
  "-i",
}

-- "fd . -cnever -tf -tl -L -i -u"
M.UNRESTRICTED_FD = {
  consts.FD,
  ".",
  "-cnever",
  "-tf",
  "-tl",
  "-L",
  "-i",
  "-u",
}

-- 'find -L . -type f -not -path "*/.*"'
M.RESTRICTED_FIND = consts.IS_WINDOWS
    and {
      consts.FIND,
      "-L",
      ".",
      "-type",
      "f",
    }
  or {
    consts.FIND,
    "-L",
    ".",
    "-type",
    "f",
    "-not",
    "-path",
    [[*/.*]],
  }

-- "find -L . -type f"
M.UNRESTRICTED_FIND = {
  consts.FIND,
  "-L",
  ".",
  "-type",
  "f",
}

M.provide_files_restricted_mode = consts.HAS_FD and M.RESTRICTED_FD
  or M.RESTRICTED_FIND
M.provide_files_unrestricted_mode = consts.HAS_FD and M.UNRESTRICTED_FD
  or M.UNRESTRICTED_FIND

-- files }

-- live grep {

-- "rg --column -n --no-heading --color=always -S"
M.RESTRICTED_RG = {
  "rg",
  "--column",
  "-n",
  "--no-heading",
  "--color=always",
  "-H",
  "-S",
}

-- "rg --column -n --no-heading --color=always -S -uu"
M.UNRESTRICTED_RG = {
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
M.RESTRICTED_GREP = {
  consts.GREP,
  "--color=always",
  "-n",
  "-H",
  "-r",
  "--exclude-dir=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]]),
  "--exclude=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]]),
}

-- "grep --color=always -n -H -r"
M.UNRESTRICTED_GREP = {
  consts.GREP,
  "--color=always",
  "-n",
  "-H",
  "-r",
}

--- @param bufnr integer
--- @return string?
local function _get_buf_path(bufnr)
  local bufpath = nvims.buf_is_valid(bufnr)
      and paths.reduce(vim.api.nvim_buf_get_name(bufnr))
    or nil
  if strs.empty(bufpath) then
    log.echo(LogLevels.INFO, M.INVALID_BUFFER_ERROR, vim.inspect(bufnr))
    return nil
  end
  return bufpath
end

--- @param opts {unrestricted:boolean?,buffer:boolean?}?
--- @return fun(query:string,context:fzfx.PipelineContext):string[]|nil
local function _make_provide_live_grep(opts)
  --- @param query string
  --- @param context fzfx.PipelineContext
  --- @return string[]|nil
  local function impl(query, context)
    local parsed = queries_helper.parse_flagged(query or "")
    local payload = parsed.payload
    local option = parsed.option

    local bufpath = nil
    local args = nil
    if consts.HAS_RG then
      ---@diagnostic disable-next-line: need-check-nil
      if tbls.tbl_not_empty(opts) and opts.unrestricted then
        args = vim.deepcopy(M.UNRESTRICTED_RG)
      ---@diagnostic disable-next-line: need-check-nil
      elseif tbls.tbl_not_empty(opts) and opts.buffer then
        args = vim.deepcopy(M.UNRESTRICTED_RG)
        bufpath = _get_buf_path(context.bufnr)
        if not bufpath then
          return nil
        end
      else
        args = vim.deepcopy(M.RESTRICTED_RG)
      end
    elseif consts.HAS_GREP then
      ---@diagnostic disable-next-line: need-check-nil
      if tbls.tbl_not_empty(opts) and opts.unrestricted then
        args = vim.deepcopy(M.UNRESTRICTED_GREP)
      ---@diagnostic disable-next-line: need-check-nil
      elseif tbls.tbl_not_empty(opts) and opts.buffer then
        args = vim.deepcopy(M.UNRESTRICTED_GREP)
        bufpath = _get_buf_path(context.bufnr)
        if not bufpath then
          return nil
        end
      else
        args = vim.deepcopy(M.RESTRICTED_GREP)
      end
    else
      log.echo(LogLevels.INFO, "no rg/grep command found.")
      return nil
    end
    if strs.not_empty(option) then
      local option_splits = strs.split(option --[[@as string]], " ")
      for _, o in ipairs(option_splits) do
        if strs.not_empty(o) then
          table.insert(args, o)
        end
      end
    end
    ---@diagnostic disable-next-line: need-check-nil
    if tbls.tbl_not_empty(opts) and opts.buffer then
      assert(strs.not_empty(bufpath))
      table.insert(args, payload)
      table.insert(args, bufpath)
    else
      table.insert(args, payload)
    end
    return args
  end
  return impl
end

M.provide_live_grep_restricted_mode = _make_provide_live_grep()
M.provide_live_grep_unrestricted_mode =
  _make_provide_live_grep({ unrestricted = true })
M.provide_live_grep_buffer_mode = _make_provide_live_grep({ buffer = true })

-- live grep }

return M
