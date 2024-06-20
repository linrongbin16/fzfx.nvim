-- Prepend file type icons at the beginning of a line.
-- Works for files and grep results (or other query results followed this pattern).
-- Such as `FzfxFiles`, `FzfxLiveGrep`, `FzfxBuffers`, `FzfxGLiveGrep`, `FzfxLspDiagnostics` etc.

local str = require("fzfx.commons.str")
local color_term = require("fzfx.commons.color.term")

local DEVICONS = nil
if str.not_empty(vim.env._FZFX_NVIM_DEVICONS_PATH) then
  vim.opt.runtimepath:append(vim.env._FZFX_NVIM_DEVICONS_PATH)
  local ok, dev = pcall(require, "nvim-web-devicons")
  if ok and dev ~= nil then
    DEVICONS = dev
  end
end

local M = {}

--- @param line string
--- @param delimiter string?
--- @param index integer?
--- @return string
M._decorate = function(line, delimiter, index)
  if not DEVICONS then
    return line
  end

  local filename = nil
  if str.not_empty(delimiter) and type(index) == "number" then
    local splits = str.split(line, delimiter --[[@as string]])
    filename = splits[index]
  else
    filename = line
  end
  -- remove ansi color codes
  -- see: https://stackoverflow.com/a/55324681/4438921
  if str.not_empty(filename) then
    filename = color_term.erase(filename)
  end
  local ext = vim.fn.fnamemodify(filename --[[@as string]], ":e")
  local icon_text, icon_color = DEVICONS.get_icon_color(filename, ext)
  -- log_debug(
  --     "|fzfx.shell_helpers - render_line_with_icon| ext:%s, icon:%s, icon_color:%s",
  --     vim.inspect(ext),
  --     vim.inspect(icon),
  --     vim.inspect(icon_color)
  -- )
  if str.not_empty(icon_text) then
    local rendered_text = color_term.render(icon_text, icon_color)
    return rendered_text .. " " .. line
  else
    if vim.fn.isdirectory(filename) > 0 then
      return string.format("%s %s", vim.env._FZFX_NVIM_FILE_FOLDER_ICON, line)
    else
      return string.format("%s %s", vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON, line)
    end
  end
end

return M
