local str = require("fzfx.commons.str")
local term_color = require("fzfx.commons.color.term")

local DEVICONS_OK = nil
local DEVICONS = nil
if str.not_empty(vim.env._FZFX_NVIM_DEVICONS_PATH) then
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
  if str.not_empty(delimiter) and type(index) == "number" then
    local splits = str.split(line, delimiter --[[@as string]])
    filename = splits[index]
  else
    filename = line
  end
  -- remove ansi color codes
  -- see: https://stackoverflow.com/a/55324681/4438921
  if str.not_empty(filename) then
    filename = term_color.erase(filename)
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
    local rendered_text = term_color.render(icon_text, icon_color)
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
