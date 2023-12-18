local M = {}

--- @param code string
--- @param fg boolean
--- @return string
M.csi = function(code, fg)
  return require("fzfx.commons.termcolors").escape(fg and "fg" or "bg", code)
end

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
