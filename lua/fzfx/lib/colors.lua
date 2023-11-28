local M = {}

--- @param code string
--- @param fg boolean
--- @return string
M.csi = function(code, fg)
  local control = fg and 38 or 48
  local r, g, b = code:match("#(..)(..)(..)")
  if r and g and b then
    r = tonumber(r, 16)
    g = tonumber(g, 16)
    b = tonumber(b, 16)
    local result = string.format("%d;2;%d;%d;%d", control, r, g, b)
    return result
  else
    local result = string.format("%d;5;%s", control, code)
    return result
  end
end

-- css color: https://www.quackit.com/css/css_color_codes.cfm
--- @type table<string, string>
local AnsiCode = {
  black = "0;30",
  grey = M.csi("#808080", true),
  silver = M.csi("#c0c0c0", true),
  white = M.csi("#ffffff", true),
  red = "0;31",
  magenta = "0;35",
  fuchsia = M.csi("#FF00FF", true),
  purple = M.csi("#800080", true),
  yellow = "0;33",
  orange = M.csi("#FFA500", true),
  olive = M.csi("#808000", true),
  green = "0;32",
  lime = M.csi("#00FF00", true),
  teal = M.csi("#008080", true),
  cyan = "0;36",
  aqua = M.csi("#00FFFF", true),
  blue = "0;34",
  navy = M.csi("#000080", true),
}

--- @param attr "fg"|"bg"
--- @param group string?
--- @return string? rbg code, e.g., #808080
M.hlcode = function(attr, group)
  if type(group) ~= "string" then
    return nil
  end
  local gui = vim.fn.has("termguicolors") > 0 and vim.o.termguicolors
  local family = gui and "gui" or "cterm"
  local pattern = gui and "^#[%l%d]+" or "^[%d]+$"
  local code =
    vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)), attr, family) --[[@as string]]
  if string.find(code, pattern) then
    return code
  end
  return nil
end

--- @param text string
--- @param name string
--- @param hl string?
--- @return string
M.ansi = function(text, name, hl)
  local fgfmt = nil
  local fgcode = M.hlcode("fg", hl)
  if type(fgcode) == "string" then
    fgfmt = M.csi(fgcode, true)
  else
    fgfmt = AnsiCode[name]
  end

  local fmt = nil
  local bgcode = M.hlcode("bg", hl)
  if type(bgcode) == "string" then
    local bgcolor = M.csi(bgcode, false)
    fmt = string.format("%s;%s", fgfmt, bgcolor)
  else
    fmt = fgfmt
  end
  return string.format("[%sm%s[0m", fmt, text)
end

--- @param s string?
--- @return string?
M.erase = function(s)
  if type(s) ~= "string" then
    return s
  end
  local result, pos = s:gsub("\x1b%[%d+m\x1b%[K", "")
    :gsub("\x1b%[m\x1b%[K", "")
    :gsub("\x1b%[%d+;%d+;%d+;%d+;%d+m", "")
    :gsub("\x1b%[%d+;%d+;%d+;%d+m", "")
    :gsub("\x1b%[%d+;%d+;%d+m", "")
    :gsub("\x1b%[%d+;%d+m", "")
    :gsub("\x1b%[%d+m", "")
  return result
end

do
  for name, code in pairs(AnsiCode) do
    --- @param text string
    --- @param hl string?
    --- @return string
    M[name] = function(text, hl)
      return M.ansi(text, name, hl)
    end
  end
end

--- @alias fzfx.ColorRenderer fun(text:string,hl:string?):string
--- @param fmt string
--- @param renderer fzfx.ColorRenderer
--- @param hl string?
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
