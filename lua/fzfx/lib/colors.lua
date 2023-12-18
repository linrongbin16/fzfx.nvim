local M = {}

--- @param code string
--- @param fg boolean
--- @return string
M.csi = function(code, fg)
  return require("fzfx.commons.termcolors").escape(fg and "fg" or "bg", code)
end

-- css color: https://www.quackit.com/css/css_color_codes.cfm
--- @type table<string, string>
local AnsiCode = {
  black = "0;30",
  grey = M.csi("#808080", true),
  silver = M.csi("#c0c0c0", true),
  white = M.csi("#ffffff", true),
  violet = M.csi("#EE82EE", true),
  magenta = "0;35",
  fuchsia = M.csi("#FF00FF", true),
  red = "0;31",
  purple = M.csi("#800080", true),
  indigo = M.csi("#4B0082", true),
  yellow = "0;33",
  gold = M.csi("#FFD700", true),
  orange = M.csi("#FFA500", true),
  chocolate = M.csi("#D2691E", true),
  olive = M.csi("#808000", true),
  green = "0;32",
  lime = M.csi("#00FF00", true),
  teal = M.csi("#008080", true),
  cyan = "0;36",
  aqua = M.csi("#00FFFF", true),
  blue = "0;34",
  navy = M.csi("#000080", true),
  slateblue = M.csi("#6A5ACD", true),
  steelblue = M.csi("#4682B4", true),
}

--- @param attr "fg"|"bg"
--- @param hl string?
--- @return string? rbg code, e.g., #808080
M.hlcode = function(attr, hl)
  local strings = require("fzfx.commons.strings")
  local termcolors = require("fzfx.commons.termcolors")
  if strings.empty(hl) then
    return nil
  end
  return termcolors.retrieve(attr, hl --[[@as string]])
end

--- @param text string
--- @param name string
--- @param hl string?
--- @return string
M.ansi = function(text, name, hl)
  local termcolors = require("fzfx.commons.termcolors")
  return termcolors.render(text, name, hl)
end

--- @param text string?
--- @return string?
M.erase = function(text)
  local strings = require("fzfx.commons.strings")
  local termcolors = require("fzfx.commons.termcolors")
  if strings.empty(text) then
    return text
  end
  return termcolors.erase(text)
end

do
  local predefined_colors = require("fzfx.commons.termcolors").COLOR_NAMES
  for _, name in ipairs(predefined_colors) do
    --- @param text string
    --- @param hl string?
    --- @return string
    M[name] = function(text, hl)
      local termcolors = require("fzfx.commons.termcolors")
      return termcolors[name](text, hl)
    end
  end
end

--- @alias fzfx.ColorRenderer fun(text:string,hl:string?):string
--- @param renderer fzfx.ColorRenderer
--- @param hl string?
--- @param fmt string
--- @param ... any
--- @return string
M.render = function(renderer, hl, fmt, ...)
  local args = {}
  for _, a in ipairs({ ... }) do
    table.insert(args, renderer(a, hl))
  end
  ---@diagnostic disable-next-line: deprecated
  return string.format(fmt, unpack(args))
end

return M
