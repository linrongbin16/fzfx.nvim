local paths = require("fzfx.commons.paths")
local strings = require("fzfx.commons.strings")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")
local apis = require("fzfx.commons.apis")
local tables = require("fzfx.commons.tables")

-- local log = require("fzfx.lib.log")

local M = {}

local THEMES_CONFIG_DIR = nil

--- @return string
M.get_bat_themes_config_dir = function()
  if THEMES_CONFIG_DIR == nil then
    local bat_themes_config_dir = ""
    local sp = spawn.run({ "bat", "--config-dir" }, {
      on_stdout = function(line)
        bat_themes_config_dir = bat_themes_config_dir .. line
      end,
      on_stderr = function(line)
        -- log.debug("|get_bat_themes_config_dir| on_stderr:%s", vim.inspect(line))
      end,
    })
    sp:wait()
    THEMES_CONFIG_DIR =
      paths.join(strings.trim(bat_themes_config_dir), "themes")
    -- log.debug(
    --   "|get_bat_themes_config_dir| config dir:%s",
    --   vim.inspect(THEMES_CONFIG_DIR)
    -- )
  end
  return THEMES_CONFIG_DIR
end

-- Vim colorscheme name => bat theme name
--- @type table<string, string>
local CUSTOMS_THEME_NAME_MAPPINGS = {}

--- @param names string[]
--- @return string[]
M._upper_first_chars = function(names)
  assert(
    type(names) == "table" and #names > 0,
    string.format("|_upper_firsts| invalid names:%s", vim.inspect(names))
  )
  local new_names = {}
  for i, n in ipairs(names) do
    assert(
      type(n) == "string" and string.len(n) > 0,
      string.format(
        "|_upper_firsts| invalid name(%d):%s",
        vim.inspect(i),
        vim.inspect(n)
      )
    )
    local new_name = string.sub(n, 1, 1):upper()
      .. (string.len(n) > 1 and string.sub(n, 2) or "")
    table.insert(new_names, new_name)
  end
  return new_names
end

--- @param s string
--- @param delimiter string
--- @return string
M._normalize_by = function(s, delimiter)
  local splits = strings.find(s, delimiter)
      and strings.split(s, delimiter, { trimempty = true })
    or { s }
  splits = M._upper_first_chars(splits)
  return table.concat(splits, "")
end

--- @param name string?
--- @return string?
M.get_custom_theme_name = function(name)
  name = name or vim.g.colors_name
  if strings.empty(name) then
    return nil
  end

  if CUSTOMS_THEME_NAME_MAPPINGS[name] == nil then
    local result = name
    result = M._normalize_by(result, "-")
    result = M._normalize_by(result, "+")
    result = M._normalize_by(result, "_")
    result = M._normalize_by(result, ".")
    result = M._normalize_by(result, " ")
    CUSTOMS_THEME_NAME_MAPPINGS[name] = "FzfxNvim" .. result
  end

  return CUSTOMS_THEME_NAME_MAPPINGS[name]
end

--- @return string?
M.get_custom_theme_file = function()
  local theme_name = M.get_custom_theme_name()
  if strings.empty(theme_name) then
    return nil
  end
  local theme_dir = M.get_bat_themes_config_dir()
  return paths.join(theme_dir, theme_name .. ".tmTheme")
end

-- renderer for tmTheme globals
--- @class fzfx._BatTmThemeGlobalRenderer
--- @field key string
--- @field value string
--- @field empty boolean
local _BatTmThemeGlobalRenderer = {}

--- @param hl string
--- @param tm_key string
--- @param attr "fg"|"bg"
--- @return fzfx._BatTmThemeGlobalRenderer
function _BatTmThemeGlobalRenderer:new(hl, tm_key, attr)
  local ok, values = pcall(apis.get_hl, hl)
  if not ok then
    values = {}
  end
  local fg = type(values.fg) == "number" and string.format("#%06x", values.fg)
    or nil
  local bg = type(values.bg) == "number" and string.format("#%06x", values.bg)
    or nil
  local o = {
    key = tm_key,
    value = attr == "fg" and fg or bg,
    empty = tables.tbl_empty(values),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return string
function _BatTmThemeGlobalRenderer:render()
  if self.empty then
    return "\n"
  end
  local builder = {
    string.format("          <key>%s</key>", self.key),
    string.format("          <string>%s</string>", self.value),
  }
  return table.concat(builder, "\n")
end

-- renderer for tmTheme scope
--- @class fzfx._BatTmThemeScopeRenderer
--- @field name string
--- @field scope string|string[]
--- @field foreground string?
--- @field background string?
--- @field bold boolean?
--- @field italic boolean?
--- @field empty boolean?
--- @field no_background boolean?
local _BatTmThemeScopeRenderer = {}

--- @param hl string|string[]
--- @param tm_scope string|string[]
--- @param no_background boolean?
--- @return fzfx._BatTmThemeScopeRenderer
function _BatTmThemeScopeRenderer:new(hl, tm_scope, no_background)
  local hls = type(hl) == "table" and hl or {
    hl --[[@as string]],
  }

  local ok
  local values = {}
  for _, h in ipairs(hls) do
    ok, values = pcall(apis.get_hl, h)
    if not ok then
      values = {}
    end
    if tables.tbl_not_empty(values) then
      break
    end
  end
  local o = {
    scope = tm_scope,
    foreground = values.fg and string.format("#%06x", values.fg) or nil,
    background = values.bg and string.format("#%06x", values.bg) or nil,
    font_style = {},
    bold = values.bold,
    italic = values.italic,
    underline = values.underline,
    empty = tables.tbl_empty(values),
    no_background = no_background,
  }
  if values.bold then
    table.insert(o.font_style, "bold")
  end
  if values.italic then
    table.insert(o.font_style, "italic")
  end
  if values.underline then
    table.insert(o.font_style, "underline")
  end
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return string
function _BatTmThemeScopeRenderer:render()
  if self.empty then
    return "\n"
  end
  local builder = {
    "      <dict>",
  }
  local name = type(self.scope) == "table" and self.scope[1] or self.scope --[[@as string]]
  table.insert(
    builder,
    string.format(
      [[        <key>name</key>
        <string>%s</string>]],
      table.concat(strings.split(name, ","), " ")
    )
  )
  table.insert(
    builder,
    string.format(
      [[        <key>scope</key>
        <string>%s</string>]],
      type(self.scope) == "table"
          and table.concat(self.scope --[[@as string[] ]], ", ")
        or self.scope
    )
  )
  table.insert(builder, "        <key>settings</key>")
  table.insert(builder, "        <dict>")
  if self.foreground then
    table.insert(builder, "          <key>foreground</key>")
    table.insert(
      builder,
      string.format("          <string>%s</string>", self.foreground)
    )
  end
  if not self.no_background and self.background then
    table.insert(builder, "          <key>background</key>")
    table.insert(
      builder,
      string.format("          <string>%s</string>", self.background)
    )
  end
  if self.background then
    table.insert(builder, "          <key>background</key>")
    table.insert(
      builder,
      string.format("          <string>%s</string>", self.background)
    )
  end
  if #self.font_style > 0 then
    table.insert(builder, "          <key>fontStyle</key>")
    table.insert(
      builder,
      string.format(
        "          <string>%s</string>",
        table.concat(self.font_style, ", ")
      )
    )
  end
  table.insert(builder, "        </dict>")
  table.insert(builder, "      </dict>\n")
  return table.concat(builder, "\n")
end

-- default base16
-- forked from: https://github.com/chriskempson/base16-textmate/blob/0e51ddd568bdbe17189ac2a07eb1c5f55727513e/Themes/base16-default-dark.tmTheme
local BASE16_COLORS = {
  black = "#181818",
  grey_sRGB = "#58585855",
  grey = "#585858",
  darkgrey = "#282828",
  white = "#d8d8d8",
  yellow = "#dc9656",
  orange = "##a16946",
  green = "#a1b56c",
  red = "#ab4642",
  blue = "#7cafc2",
  cyan = "#7cafc2",
  magenta = "#ba8baf",
}

local GLOBAL_RENDERERS = {
  _BatTmThemeGlobalRenderer:new("Normal", "background", "bg"),
  _BatTmThemeGlobalRenderer:new("Normal", "foreground", "fg"),
  _BatTmThemeGlobalRenderer:new("Cursor", "caret", "bg"),
  _BatTmThemeGlobalRenderer:new("Cursor", "block_caret", "bg"),
  _BatTmThemeGlobalRenderer:new("NonText", "invisibles", "fg"),
  _BatTmThemeGlobalRenderer:new("CursorLine", "lineHighlight", "bg"),
  _BatTmThemeGlobalRenderer:new("LineNr", "gutter", "bg"),
  _BatTmThemeGlobalRenderer:new("LineNr", "gutter_foreground", "fg"),
  _BatTmThemeGlobalRenderer:new("Visual", "selection", "bg"),
  _BatTmThemeGlobalRenderer:new("Visual", "selection_foreground", "fg"),
  _BatTmThemeGlobalRenderer:new("Search", "find_highlight", "bg"),
  _BatTmThemeGlobalRenderer:new("Search", "find_highlight_foreground", "fg"),
}

local SCOPE_RENDERERS = {
  -- comment
  _BatTmThemeScopeRenderer:new({ "@comment", "Comment" }, "comment", true),

  -- constant
  _BatTmThemeScopeRenderer:new({ "@constant", "Constant" }, "constant", true),
  _BatTmThemeScopeRenderer:new(
    { "@number", "Number" },
    "constant.numeric",
    true
  ),
  _BatTmThemeScopeRenderer:new(
    { "@float", "Float" },
    "constant.numeric.float",
    true
  ),
  _BatTmThemeScopeRenderer:new(
    { "@boolean", "Boolean" },
    "constant.language",
    true
  ),
  _BatTmThemeScopeRenderer:new(
    { "@character", "Character" },
    { "constant.character", "constant.other" },
    true
  ),
  _BatTmThemeScopeRenderer:new(
    { "@string.escape", "SpecialChar" },
    { "constant.character.escaped", "constant.character.escape" },
    true
  ),

  -- string
  _BatTmThemeScopeRenderer:new(
    { "@string", "String" },
    { "string", "string.quoted" },
    true
  ),
  _BatTmThemeScopeRenderer:new(
    { "DiagnosticWarn", "LspDiagnosticsDefaultWarning", "WarningMsg" },
    { "string.regexp" },
    true
  ),

  -- variable
  _BatTmThemeScopeRenderer:new(
    { "@function", "Function" },
    "variable.function",
    true
  ),
  _BatTmThemeScopeRenderer:new(
    { "@parameter", "Identifier" },
    "variable.parameter",
    true
  ),

  -- keyword
  _BatTmThemeScopeRenderer:new({ "@keyword", "Keyword" }, "keyword", true),
  _BatTmThemeScopeRenderer:new(
    { "@conditional", "Conditional" },
    "keyword.control.conditional",
    true
  ),
  _BatTmThemeScopeRenderer:new(
    { "@operator", "Operator" },
    "keyword.operator",
    true
  ),

  -- storage
  -- _BatTmThemeScopeRenderer:new({"", "StorageClass" }, "storage.type", true),
  _BatTmThemeScopeRenderer:new({ "@type", "Type" }, "storage.type", true),
  _BatTmThemeScopeRenderer:new(
    { "@storageclass", "StorageClass" },
    "storage.modifier",
    true
  ),

  -- entity
  _BatTmThemeScopeRenderer:new({
    "@structure",
    "Structure",
  }, {
    "entity.name.enum",
    "entity.name.union",
  }, true),
  _BatTmThemeScopeRenderer:new({
    "@type.definition",
    "Typedef",
  }, "entity.other.inherited-class", true),
  _BatTmThemeScopeRenderer:new({
    "@text.title",
    "Title",
  }, "entity.name.section", true),
  _BatTmThemeScopeRenderer:new({
    "@function",
    "Function",
  }, "entity.name.function", true),
  _BatTmThemeScopeRenderer:new({
    "@label",
    "Label",
  }, "entity.name.label", true),
  _BatTmThemeScopeRenderer:new({
    "htmlTag",
  }, "entity.name.tag", true),

  -- support
  _BatTmThemeScopeRenderer:new({
    "@function",
    "Function",
  }, "support.function", true),
  _BatTmThemeScopeRenderer:new({
    "@constant",
    "Constant",
  }, "support.constant", true),
  _BatTmThemeScopeRenderer:new({
    "@type",
    "Type",
  }, "support.type", true),
  _BatTmThemeScopeRenderer:new({
    "@type.definition",
    "Typedef",
  }, "support.class", true),

  -- invalid
  _BatTmThemeScopeRenderer:new({
    "Error",
  }, "invalid.illegal"),

  -- markup
  _BatTmThemeScopeRenderer:new({
    "@text.title",
    "Title",
  }, "markup.heading"),
  _BatTmThemeScopeRenderer:new(
    { "GitSignsAdd", "GitGutterAdd", "DiffAdd", "DiffAdded", "Added" },
    "markup.inserted"
  ),
  _BatTmThemeScopeRenderer:new({
    "GitSignsDelete",
    "GitGutterDelete",
    "DiffDelete",
    "DiffRemoved",
    "Removed",
  }, "markup.deleted"),
  _BatTmThemeScopeRenderer:new(
    { "GitGutterChange", "GitSignsChange", "DiffChange", "Changed" },
    "diff.changed"
  ),
}

--- @return {name:string,payload:string}?
M.calculate_custom_theme = function()
  local theme_name = M.get_custom_theme_name()
  if strings.empty(theme_name) then
    return nil
  end
  local template_path = paths.join(
    vim.env._FZFX_NVIM_SELF_PATH --[[@as string]],
    "assets",
    "bat",
    "theme_template.tmTheme"
  )
  local payload = fileios.readfile(template_path, { trim = true }) --[[@as string]]
  payload = payload:gsub("{NAME}", theme_name --[[@as string]])

  local global_builder = {}
  for i, renderer in ipairs(GLOBAL_RENDERERS) do
    table.insert(global_builder, renderer:render())
  end
  local scope_builder = {}
  for i, renderer in ipairs(SCOPE_RENDERERS) do
    table.insert(scope_builder, renderer:render())
  end
  payload = payload:gsub("{GLOBAL}", table.concat(global_builder, "\n"))
  payload = payload:gsub("{SCOPE}", table.concat(scope_builder, "\n"))
  return {
    name = theme_name,
    payload = payload,
  }
end

return M
