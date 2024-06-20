-- Prepend file type icons at the beginning of a line.
-- Works for files and grep results (or other query results followed this pattern).
-- Such as `FzfxFiles`, `FzfxLiveGrep`, `FzfxBuffers`, `FzfxGLiveGrep`, `FzfxLspDiagnostics` etc.

local str = require("fzfx.commons.str")
local path = require("fzfx.commons.path")
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

  --- @type string
  local filename
  if str.not_empty(delimiter) and type(index) == "number" then
    -- If specified the `delimiter` and `index`, then the `filename` is only part of the `line`.
    -- Need to first split by `delimiter`, then `filename` is the `index`-th part.
    local splits = str.split(line, delimiter --[[@as string]])
    filename = splits[index]
  else
    filename = line
  end

  -- remove (terminal) ansi color codes
  if str.not_empty(filename) then
    filename = color_term.erase(filename) --[[@as string]]
  end

  if path.isdir(filename) then
    -- If `filename` is a directory
    return string.format("%s %s", vim.env._FZFX_NVIM_FILE_FOLDER_ICON, line)
  else
    -- Try to query file type icon and color for it.
    local text, color = DEVICONS.get_icon_color(filename, nil, { default = true })

    -- log_debug(
    --     "|fzfx.shell_helpers - render_line_with_icon| ext:%s, icon:%s, icon_color:%s",
    --     vim.inspect(ext),
    --     vim.inspect(icon),
    --     vim.inspect(icon_color)
    -- )

    if str.not_empty(text) then
      if str.not_empty(color) and string.len(color) == 7 and str.startswith(color, "#") then
        local rendered_text = color_term.render(text, color)
        return rendered_text .. " " .. line
      else
        return text .. " " .. line
      end
    else
      return string.format("%s %s", vim.env._FZFX_NVIM_UNKNOWN_FILE_ICON, line)
    end
  end
end

return M
