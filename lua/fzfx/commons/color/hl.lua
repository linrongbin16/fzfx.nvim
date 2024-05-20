local M = {}

--- @param highlight string
--- @param attr "fg"|"bg"|string
--- @return string?
M.get_color = function(highlight, attr)
  assert(type(highlight) == "string")
  assert(attr == "fg" or attr == "bg" or attr == "sp")

  local api = require("fzfx.commons.api")
  local hl_value = api.get_hl(highlight)
  if type(hl_value) == "table" and type(hl_value[attr]) == "number" then
    return string.format("#%06x", hl_value[attr])
  end
  return nil
end

--- @param highlights string|string[]
--- @param attr "fg"|"bg"|string
--- @param fallback_color string?
--- @return string?, integer, string?
M.get_color_with_fallback = function(highlights, attr, fallback_color)
  assert(type(highlights) == "string" or type(highlights) == "table")
  assert(type(attr) == "string")
  local api = require("fzfx.commons.api")
  local hls = type(highlights) == "string" and { highlights } or highlights --[[@as table]]

  for i, hl in ipairs(hls) do
    local hl_value = api.get_hl(hl)
    if type(hl_value) == "table" and type(hl_value[attr]) == "number" then
      return string.format("#%06x", hl_value[attr]), i, hl
    end
  end

  return fallback_color, -1, nil
end

return M
