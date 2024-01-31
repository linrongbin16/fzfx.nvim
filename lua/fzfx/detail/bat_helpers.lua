local paths = require("fzfx.commons.paths")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")
local strings = require("fzfx.commons.strings")
local tables = require("fzfx.commons.tables")
local apis = require("fzfx.commons.apis")

local env = require("fzfx.lib.env")
local log = require("fzfx.lib.log")

local M = {}

--- @return string
M.get_color_name_cache = function()
  return paths.join(env.cache_dir(), "_last_color_name_cache")
end

--- @return string?
M.get_color_name = function()
  return fileios.readfile(M.get_color_name_cache(), { trim = true })
end

--- @param colorname string?
M.dump_color_name = function(colorname)
  if strings.not_empty(colorname) then
    fileios.asyncwritefile(
      M.get_color_name_cache(),
      colorname --[[@as string]],
      function() end
    )
  end
end

--- @return string
M.get_themes_config_dir_cache = function()
  return paths.join(env.cache_dir(), "_last_bat_themes_dir_cache")
end

--- @return string?
M.cached_theme_dir = function()
  return fileios.readfile(M.get_themes_config_dir_cache(), { trim = true })
end

--- @param value string
M.dump_theme_dir_cache = function(value)
  return fileios.asyncwritefile(
    M.get_themes_config_dir_cache(),
    value,
    function() end
  )
end

--- @return string
M.get_bat_themes_config_dir = function()
  local theme_dir = M.cached_theme_dir() --[[@as string]]
  if strings.empty(theme_dir) then
    theme_dir = ""
    spawn
      .run({ "bat", "--config-dir" }, {
        on_stdout = function(line)
          theme_dir = theme_dir .. line
        end,
        on_stderr = function(line)
          -- log.debug("|get_bat_themes_config_dir| on_stderr:%s", vim.inspect(line))
        end,
      }, function() end)
      :wait()
    M.dump_theme_dir_cache(theme_dir)
    return theme_dir
  else
    return theme_dir
  end
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

--- @param name string
--- @return string?
M.get_custom_theme_name = function(name)
  assert(type(name) == "string" and string.len(name) > 0)
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

--- @param colorname string
--- @return string?
M.get_custom_theme_template_file = function(colorname)
  local theme_name = M.get_custom_theme_name(colorname)
  if strings.empty(theme_name) then
    return nil
  end
  local theme_dir = M.get_bat_themes_config_dir()
  if strings.empty(theme_dir) then
    return nil
  end
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
  _BatTmThemeGlobalRenderer:new("LineNr", "gutterForeground", "fg"),
  _BatTmThemeGlobalRenderer:new("Visual", "selection", "bg"),
  _BatTmThemeGlobalRenderer:new("Visual", "selectionForeground", "fg"),
  _BatTmThemeGlobalRenderer:new("Search", "findHighlight", "bg"),
  _BatTmThemeGlobalRenderer:new("Search", "findHighlightForeground", "fg"),
}

-- tm theme name conversions: https://macromates.com/manual/en/language_grammars#naming_conventions
local SCOPE_RENDERERS = {
  -- comment {
  _BatTmThemeScopeRenderer:new({ "@comment", "Comment" }, "comment"),
  -- comment }

  -- constant {
  _BatTmThemeScopeRenderer:new({ "@number", "Number" }, "constant.numeric"),
  _BatTmThemeScopeRenderer:new(
    { "@number.float", "Float" },
    "constant.numeric.float"
  ),
  _BatTmThemeScopeRenderer:new({ "@boolean", "Boolean" }, "constant.language"),
  _BatTmThemeScopeRenderer:new(
    { "@character", "Character" },
    { "constant.character" }
  ),
  _BatTmThemeScopeRenderer:new(
    { "@string.escape" },
    { "constant.character.escaped", "constant.character.escape" }
  ),
  -- constant }

  -- entity {
  _BatTmThemeScopeRenderer:new({
    "@function",
    "Function",
  }, "entity.name.function"),
  _BatTmThemeScopeRenderer:new({
    "@type",
    "Type",
  }, {
    "entity.name.type",
  }),
  _BatTmThemeScopeRenderer:new({
    "@tag",
  }, "entity.name.tag"),
  _BatTmThemeScopeRenderer:new({
    "@markup.heading",
    "htmlTitle",
  }, "entity.name.section"),
  _BatTmThemeScopeRenderer:new({
    "Structure",
  }, {
    "entity.name.enum",
    "entity.name.union",
  }),
  _BatTmThemeScopeRenderer:new({
    "@type",
    "Type",
  }, "entity.other.inherited-class"),
  _BatTmThemeScopeRenderer:new({
    "@label",
    "Label",
  }, "entity.name.label"),
  _BatTmThemeScopeRenderer:new({
    "@constant",
    "Constant",
  }, "entity.name.constant"),
  _BatTmThemeScopeRenderer:new({
    "@module",
  }, "entity.name.namespace"),
  -- entity }

  -- invalid {
  _BatTmThemeScopeRenderer:new({
    "Error",
  }, "invalid.illegal"),
  -- invalid }

  -- keyword {
  -- _BatTmThemeScopeRenderer:new({ "@keyword", "Keyword" }, "keyword"),
  _BatTmThemeScopeRenderer:new({ "@keyword", "Keyword" }, "keyword"),
  _BatTmThemeScopeRenderer:new({ "@keyword", "Keyword" }, "keyword.local"),
  _BatTmThemeScopeRenderer:new(
    { "@keyword.conditional", "Conditional" },
    "keyword.control.conditional"
  ),
  _BatTmThemeScopeRenderer:new(
    { "@keyword.operator" },
    "keyword.operator.word"
  ),
  _BatTmThemeScopeRenderer:new({ "@operator", "Operator" }, "keyword.operator"),
  _BatTmThemeScopeRenderer:new({ "@keyword.import" }, "keyword.control.import"),
  -- keyword }

  -- markup {
  _BatTmThemeScopeRenderer:new({
    "@markup.link.url",
  }, "markup.underline.link"),
  _BatTmThemeScopeRenderer:new({
    "@markup.underline",
  }, "markup.underline"),
  _BatTmThemeScopeRenderer:new({
    "@markup.strong",
  }, "markup.bold"),
  _BatTmThemeScopeRenderer:new({
    "@markup.italic",
  }, "markup.italic"),
  _BatTmThemeScopeRenderer:new({
    "@markup.heading",
  }, "markup.heading"),
  _BatTmThemeScopeRenderer:new({
    "@markup.list",
  }, "markup.list"),
  _BatTmThemeScopeRenderer:new({
    "@markup.raw",
  }, "markup.raw"),
  _BatTmThemeScopeRenderer:new({
    "@markup.quote",
  }, "markup.quote"),
  _BatTmThemeScopeRenderer:new({
    "GitSignsAdd",
    "GitGutterAdd",
    "DiffAdd",
    "DiffAdded",
    "@diff.plus",
    "Added",
  }, "markup.inserted"),
  _BatTmThemeScopeRenderer:new({
    "GitSignsDelete",
    "GitGutterDelete",
    "DiffDelete",
    "DiffRemoved",
    "@diff.minus",
    "Removed",
  }, "markup.deleted"),
  _BatTmThemeScopeRenderer:new({
    "GitGutterChange",
    "GitSignsChange",
    "DiffChange",
    "@diff.delta",
    "Changed",
  }, "diff.changed"),
  -- markup }

  -- meta {
  -- _BatTmThemeScopeRenderer:new({
  --   "@keyword.function",
  -- }, "meta.function"),
  -- _BatTmThemeScopeRenderer:new({
  --   "@punctuation.bracket",
  -- }, { "meta.block", "meta.braces" }),
  -- meta }

  -- storage {
  _BatTmThemeScopeRenderer:new({
    "@keyword.function",
  }, { "storage.type.function", "keyword.declaration.function" }),
  _BatTmThemeScopeRenderer:new({
    "Structure",
  }, {
    "storage.type.struct",
    "storage.type.enum",
    "keyword.declaration.struct",
    "keyword.declaration.enum",
  }),
  _BatTmThemeScopeRenderer:new({
    "@type.builtin",
    "@type",
    "Type",
  }, { "storage.type", "keyword.declaration.type" }),
  _BatTmThemeScopeRenderer:new({ "StorageClass" }, "storage.modifier"),
  -- storage }

  -- string {
  _BatTmThemeScopeRenderer:new(
    { "@string", "String" },
    { "string", "string.quoted" }
  ),
  _BatTmThemeScopeRenderer:new({
    "@string.regexp",
  }, { "string.regexp" }),
  -- string }

  -- support {
  _BatTmThemeScopeRenderer:new({
    "@function",
    "Function",
  }, "support.function"),
  _BatTmThemeScopeRenderer:new({
    "@constant",
    "Constant",
  }, "support.constant"),
  _BatTmThemeScopeRenderer:new({
    "@type",
    "Type",
  }, "support.type"),
  _BatTmThemeScopeRenderer:new({
    "@type",
    "Type",
  }, "support.class"),
  _BatTmThemeScopeRenderer:new({
    "@module",
  }, "support.module"),
  -- support }

  -- variable {
  _BatTmThemeScopeRenderer:new({
    "@function.call",
  }, "variable.function"),
  _BatTmThemeScopeRenderer:new({
    "@variable.parameter",
  }, { "variable.parameter" }),
  _BatTmThemeScopeRenderer:new({
    "@variable.builtin",
  }, { "variable.language" }),
  -- _BatTmThemeScopeRenderer:new({
  --   "@constant",
  -- }, { "variable.other.constant" }),
  _BatTmThemeScopeRenderer:new({
    "@variable",
    "Identifier",
  }, "variable"),
  _BatTmThemeScopeRenderer:new({
    "@variable",
    "Identifier",
  }, "variable.other"),
  -- _BatTmThemeScopeRenderer:new({
  --   "@variable.member",
  -- }, "variable.other.member"),
  -- variable }

  -- punctuation {
  _BatTmThemeScopeRenderer:new({
    "@punctuation.bracket",
  }, {
    "punctuation.section.brackets.begin",
    "punctuation.section.brackets.end",
    "punctuation.section.braces.begin",
    "punctuation.section.braces.end",
    "punctuation.section.parens.begin",
    "punctuation.section.parens.end",
  }),
  _BatTmThemeScopeRenderer:new({
    "@punctuation.special",
  }, {
    "punctuation.section.interpolation.begin",
    "punctuation.section.interpolation.end",
  }),
  _BatTmThemeScopeRenderer:new({
    "@punctuation.delimiter",
  }, {
    "punctuation.separator",
    "punctuation.terminator",
  }),
  _BatTmThemeScopeRenderer:new({
    "@tag.delimiter",
  }, {
    "punctuation.definition.generic.begin",
    "punctuation.definition.generic.end",
  }),
  -- punctuation }
}

--- @param colorname string
--- @return {name:string,payload:string}?
M.calculate_custom_theme = function(colorname)
  local theme_name = M.get_custom_theme_name(colorname) --[[@as string]]
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
  payload = strings.replace(payload, "{NAME}", theme_name)

  local global_builder = {}
  for i, renderer in ipairs(GLOBAL_RENDERERS) do
    table.insert(global_builder, renderer:render())
  end
  local scope_builder = {}
  for i, renderer in ipairs(SCOPE_RENDERERS) do
    table.insert(scope_builder, renderer:render())
  end
  payload =
    strings.replace(payload, "{GLOBAL}", table.concat(global_builder, "\n"))
  payload =
    strings.replace(payload, "{SCOPE}", table.concat(scope_builder, "\n"))
  return {
    name = theme_name,
    payload = payload,
  }
end

local building_bat_theme = false

--- @param colorname string
M.build_custom_theme = function(colorname)
  local theme_template = M.get_custom_theme_template_file(colorname) --[[@as string]]
  log.debug(
    "|build_custom_theme| colorname:%s, theme_template:%s",
    vim.inspect(colorname),
    vim.inspect(theme_template)
  )
  if strings.empty(theme_template) then
    return
  end
  local theme_dir = M.get_bat_themes_config_dir() --[[@as string]]
  log.debug("|build_custom_theme| theme_dir:%s", vim.inspect(theme_dir))
  if strings.empty(theme_dir) then
    return
  end
  local theme = M.calculate_custom_theme(colorname) --[[@as string]]
  log.debug("|build_custom_theme| theme:%s", vim.inspect(theme))
  if tables.tbl_empty(theme) then
    return
  end

  if building_bat_theme then
    return
  end
  building_bat_theme = true

  if not paths.isdir(theme_dir) then
    spawn
      .run({ "mkdir", "-p", theme_dir }, {
        on_stdout = function() end,
        on_stderr = function() end,
      })
      :wait()
  end

  fileios.writefile(theme_template, theme.payload)
  log.debug(
    "|build_custom_theme| dump theme payload, theme_template:%s",
    vim.inspect(theme_template)
  )

  spawn.run({ "bat", "cache", "--build" }, {
    on_stdout = function(line)
      log.debug("|setup| bat cache on_stderr:%s", vim.inspect(line))
    end,
    on_stderr = function(line)
      log.debug("|setup| bat cache on_stderr:%s", vim.inspect(line))
    end,
  }, function()
    vim.schedule(function()
      building_bat_theme = false
    end)
  end)
end

M.setup = function()
  local colorname = vim.g.colors_name
  if strings.not_empty(colorname) then
    M.build_custom_theme(colorname)
    M.dump_color_name(colorname)
  end
  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      -- log.debug("|setup| event:%s", vim.inspect(event))
      if strings.not_empty(tables.tbl_get(event, "match")) then
        -- vim.g.colors_name = event.match
        M.build_custom_theme(event.match)
        M.dump_color_name(event.match)
      end
    end,
  })
end

return M
