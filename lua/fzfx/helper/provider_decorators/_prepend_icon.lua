local colors = require("fzfx.lib.colors")
local strs = require("fzfx.lib.strings")

local DEVICONS_OK = nil
local DEVICONS = nil
if strs.not_empty(vim.env._FZFX_NVIM_DEVICONS_PATH) then
  vim.opt.runtimepath:append(vim.env._FZFX_NVIM_DEVICONS_PATH)
  DEVICONS_OK, DEVICONS = pcall(require, "nvim-web-devicons")
end

local M = {}

--- @param line string
--- @param delimiter string?
--- @param index integer?
--- @return string
M._decorate = function(line, delimiter, index)
  if not DEVICONS_OK or DEVICONS == nil then
    return line
  end

  local filename = nil
  if strs.not_empty(delimiter) and type(index) == "number" then
    local splits = strs.split(line, delimiter --[[@as string]])
    filename = splits[index]
  else
    filename = line
  end
  -- remove ansi color codes
  -- see: https://stackoverflow.com/a/55324681/4438921
  if strs.not_empty(filename) then
    filename = colors.erase(filename)
  end
  local ext = vim.fn.fnamemodify(filename, ":e")
  local icon, icon_color = DEVICONS.get_icon_color(filename, ext)
  -- log_debug(
  --     "|fzfx.shell_helpers - render_line_with_icon| ext:%s, icon:%s, icon_color:%s",
  --     vim.inspect(ext),
  --     vim.inspect(icon),
  --     vim.inspect(icon_color)
  -- )
  if strs.not_empty(icon) then
    local fmt = colors.csi(icon_color, true)
    if fmt then
      return string.format("[%sm%s[0m %s", fmt, icon, line)
    else
      return string.format("%s %s", icon, line)
    end
  else
    if vim.fn.isdirectory(filename) > 0 then
      return string.format("%s %s", vim.env._FZFX_NVIM_FILE_FOLDER_ICON, line)
    else
      return string.format("%s %s", vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON, line)
    end
  end
end

return M
