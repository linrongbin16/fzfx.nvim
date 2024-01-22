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
--- @field value string?
--- @field fallback string
local _BatTmThemeGlobalRenderer = {}

--- @param hl string
--- @param tm_key string
--- @param attr "fg"|"bg"
--- @param fallback string
--- @return fzfx._BatTmThemeGlobalRenderer
function _BatTmThemeGlobalRenderer:new(hl, tm_key, attr, fallback)
  local values = apis.get_hl(hl)
  local fg = type(values.fg) == "number" and string.format("#%06x", values.fg)
    or nil
  local bg = type(values.bg) == "number" and string.format("#%06x", values.bg)
    or nil
  local o = {
    key = tm_key,
    value = attr == "fg" and fg or bg,
    fallback = fallback,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return string
function _BatTmThemeGlobalRenderer:render()
  return string.format(
    [[
          <key>%s</key>
          <string>%s</string>
]],
    self.key,
    self.value or self.fallback
  )
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
local _BatTmThemeScopeRenderer = {}

--- @param hl string
--- @param tm_scope string|string[]
--- @param fallback string
--- @return fzfx._BatTmThemeScopeRenderer
function _BatTmThemeScopeRenderer:new(hl, tm_scope)
  local values = apis.get_hl(hl)
  local o = {
    scope = tm_scope,
    foreground = values.fg and string.format("#%06x", values.fg) or nil,
    background = values.bg and string.format("#%06x", values.bg) or nil,
    font_style = {},
    bold = values.bold,
    italic = values.italic,
    underline = values.underline,
    empty = tables.tbl_empty(values),
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
    "\n      <dict>",
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
      type(self.scope) == "table" and table.concat(self.scope, ", ")
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
  if self.background then
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
    table.insert(builder, "          <key>font_style</key>")
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

-- The 'theme_template.tmTheme' is forked from: https://github.com/sharkdp/bat/blob/98a2b6bc177050c845f2e12133458826ad1fca72/assets/themes/base16.tmTheme
local COLOR_CONFIGS = {

  -- settings
  BACKGROUND = {
    group = "Normal",
    attr = "bg",
    default = BASE16_COLORS.black,
  },
  FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  CARET = {
    group = "Cursor",
    attr = "bg",
    default = BASE16_COLORS.white,
  },
  BLOCK_CARET = {
    group = "Cursor",
    attr = "bg",
    default = BASE16_COLORS.white,
  },
  INVISIBLES = {
    group = "NonText",
    attr = "bg",
    default = BASE16_COLORS.black,
  },
  LINE_HIGHLIGHT = {
    group = "CursorLine",
    attr = "bg",
    default = BASE16_COLORS.grey_sRGB,
  },
  MISSPELLING = {
    group = { "SpellBad", "Normal" },
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  GUTTER = {
    group = "LineNr",
    attr = "bg",
    default = BASE16_COLORS.black,
  },
  GUTTER_FOREGROUND = {
    group = "LineNr",
    attr = "fg",
    default = BASE16_COLORS.grey,
  },
  SELECTION = {
    group = "Visual",
    attr = "bg",
    default = BASE16_COLORS.yellow,
  },
  SELECTION_FOREGROUND = {
    group = "Visual",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  FIND_HIGHLIGHT = {
    group = "Search",
    attr = "bg",
    default = BASE16_COLORS.yellow,
  },
  FIND_HIGHLIGHT_FOREGROUND = {
    group = "Search",
    attr = "fg",
    default = BASE16_COLORS.white,
  },

  -- comment
  COMMENT_FOREGROUND = {
    group = "Comment",
    attr = "fg",
    default = BASE16_COLORS.grey,
  },
  COMMENT_BACKGROUND = {
    group = "Comment",
    attr = "bg",
    default = BASE16_COLORS.black,
  },

  -- constant
  CONSTANT_NUMERIC_FOREGROUND = {
    group = { "Number" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },
  CONSTANT_NUMERIC_FLOAT_FOREGROUND = {
    group = { "Float", "Number" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },
  CONSTANT_LANGUAGE_FOREGROUND = {
    group = { "Boolean" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },
  CONSTANT_CHARACTER_ESCAPE_FOREGROUND = {
    group = { "SpecialChar", "Constant" },
    attr = "fg",
    default = BASE16_COLORS.magenta,
  },
  CONSTANT_CHARACTER_OTHER_FOREGROUND = {
    group = "Character",
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },

  -- string
  STRING_FOREGROUND = {
    group = "String",
    attr = "fg",
    default = BASE16_COLORS.green,
  },
  STRING_REGEXP_FOREGROUND = {
    group = {
      "rubyRegexp",
      "rubyRegexpDelimiter",
      "DiagnosticWarn",
      "LspDiagnosticsDefaultWarning",
      "WarningMsg",
    },
    attr = "fg",
    default = BASE16_COLORS.red,
  },
  RUBY_STRING_REGEXP_FOREGROUND = {
    group = {
      "rubyRegexp",
      "rubyRegexpDelimiter",
      "DiagnosticWarn",
      "LspDiagnosticsDefaultWarning",
      "WarningMsg",
    },
    attr = "fg",
    default = BASE16_COLORS.red,
  },
  STRING_INTERPOLATION_FOREGROUND = {
    group = { "Boolean" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },

  -- variable
  VARIABLE_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  VARIABLE_LANGUAGE_FOREGROUND = {
    group = {
      "@variable.builtin",
      "ErrorMsg",
    },
    attr = "fg",
    default = BASE16_COLORS.red,
  },
  VARIABLE_FUNCTION_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  VARIABLE_PARAMETER_FOREGROUND = {
    group = { "@parameter", "Normal" },
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  VARIABLE_OTHER_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  -- VARIABLE_OTHER_CONSTANT_FOREGROUND = {
  --   group = "Boolean",
  --   attr = "fg",
  --   default = BASE16_COLORS.yellow,
  -- },
  VARIABLE_OTHER_READWRITE_INSTANCE_FOREGROUND = {
    group = {
      "DiagnosticSignWarn",
      "LspDiagnosticsSignWarn",
      "WarningMsg",
    },
    attr = "fg",
    default = BASE16_COLORS.red,
  },

  -- keyword
  KEYWORDS_FOREGROUND = {
    group = "Define",
    attr = "fg",
    default = BASE16_COLORS.magenta,
  },
  KEYWORD_CONTROL_FOREGROUND = {
    group = { "Conditional" },
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  KEYWORD_OPERATOR_FOREGROUND = {
    group = "Operator",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  KEYWORD_OTHER_FOREGROUND = {
    group = "PreProc",
    attr = "fg",
    default = BASE16_COLORS.white,
  },

  -- storage
  STORAGE_FOREGROUND = {
    group = { "Boolean" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },
  STORAGE_TYPE_FOREGROUND = {
    group = { "Identifier", "StorageClass" },
    attr = "fg",
    default = BASE16_COLORS.magenta,
  },

  -- entity
  ENTITY_NAME_FOREGROUND = {
    group = "Pmenu",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  ENTITY_NAME_CLASS_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  EENTITY_OTHER_INHERITED_CLASS_FOREGROUND = {
    group = { "Tag", "Type" },
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  ENTITY_NAME_FUNCTION_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  ENTITY_NAME_LABEL_FOREGROUND = {
    group = "Label",
    attr = "fg",
    default = BASE16_COLORS.orange,
  },
  ENTITY_NAME_TAG_FOREGROUND = {
    group = { "Tag" },
    attr = "fg",
    default = BASE16_COLORS.orange,
  },
  ENTITY_OTHER_ATTRIBUTE_NAME_FOREGROUND = {
    group = { "Tag" },
    attr = "fg",
    default = BASE16_COLORS.orange,
  },

  -- support
  SUPPORT_FUNCTION_FOREGROUND = {
    group = { "Function" },
    attr = "fg",
    default = "#86c1b9",
  },
  SUPPORT_CONSTANT_FOREGROUND = {
    group = "Constant",
    attr = "fg",
    default = "#dc9656",
  },
  SUPPORT_TYPE_AND_CLASS_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = "#7cafc2",
  },
  SUPPORT_OTHER_NAMESPACE_FOREGROUND = {
    group = {
      "SpecialComment",
      "DiagnosticSignInfo",
      "LspDiagnosticsSignInfo",
      "Tag",
    },
    attr = "fg",
    default = "#7cafc2",
  },

  FUNCTIONS_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  META_PATH_FOREGROUND = {
    group = "helpHyperTextJump",
    attr = "fg",
    default = "#7cafc2",
  },
  INVALID_BACKGROUND = {
    group = { "Exception", "Error" },
    attr = "bg",
    default = "#ab4642",
  },
  INVALID_FOREGROUND = {
    group = { "Exception", "Error" },
    attr = "fg",
    default = "#ab4642",
  },
  INVALID_DEPRECATED_BACKGROUND = {
    group = { "Directory", "helpCommand" },
    attr = "bg",
    default = "#a16946",
  },
  INVALID_DEPRECATED_FOREGROUND = {
    group = { "Directory", "helpCommand" },
    attr = "fg",
    default = "#f8f8f8",
  },
  DIFF_HEADER_FOREGROUND = {
    group = { "LineNr", "SignColumn", "Comment" },
    attr = "fg",
    default = "#585858",
  },
  MARKUP_DELETED_FOREGROUND = {
    group = { "GitSignsDelete", "GitGutterDelete", "DiffDelete", "DiffRemoved" },
    attr = "fg",
    default = "#ab4642",
  },
  MARKUP_INSERTED_FOREGROUND = {
    group = { "GitSignsAdd", "GitGutterAdd", "DiffAdd", "DiffAdded" },
    attr = "fg",
    default = "#a1b56c",
  },
  MARKUP_CHANGED_FOREGROUND = {
    group = { "GitGutterChange", "GitSignsChange", "DiffChange" },
    attr = "fg",
    default = "#ba8baf",
  },
  ENTITY_NAME_FILENAME_FOREGROUND = {
    group = { "Directory", "Tag" },
    attr = "fg",
    default = "#a1b56c",
  },
  PUNCTUATION_ACCESSOR_FOREGROUND = {
    group = { "SpecialKey", "Character", "Special" },
    attr = "fg",
    default = "#ba8baf",
  },
  META_FUNCTION_RETURN_TYPE_FOREGROUND = {
    group = { "PreProc", "Macro", "Special" },
    attr = "fg",
    default = "#ba8baf",
  },
  PUNCTUATION_SECTION_BLOCK_BEGIN_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = "#d8d8d8",
  },
  PUNCTUATION_SECTION_BLOCK_END_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = "#d8d8d8",
  },
  META_CLASS_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = "#f8f8f8",
  },
}

local VIM_COLOR_CONFIGS = {
  -- global
  ["Normal"] = {},
  BACKGROUND = {
    group = "Normal",
    attr = "bg",
    default = BASE16_COLORS.black,
  },
  FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  CARET = {
    group = "Cursor",
    attr = "bg",
    default = BASE16_COLORS.white,
  },
  BLOCK_CARET = {
    group = "Cursor",
    attr = "bg",
    default = BASE16_COLORS.white,
  },
  INVISIBLES = {
    group = "NonText",
    attr = "bg",
    default = BASE16_COLORS.black,
  },
  LINE_HIGHLIGHT = {
    group = "CursorLine",
    attr = "bg",
    default = BASE16_COLORS.grey_sRGB,
  },
  MISSPELLING = {
    group = { "SpellBad", "Normal" },
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  GUTTER = {
    group = "LineNr",
    attr = "bg",
    default = BASE16_COLORS.black,
  },
  GUTTER_FOREGROUND = {
    group = "LineNr",
    attr = "fg",
    default = BASE16_COLORS.grey,
  },
  SELECTION = {
    group = "Visual",
    attr = "bg",
    default = BASE16_COLORS.yellow,
  },
  SELECTION_FOREGROUND = {
    group = "Visual",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  FIND_HIGHLIGHT = {
    group = "Search",
    attr = "bg",
    default = BASE16_COLORS.yellow,
  },
  FIND_HIGHLIGHT_FOREGROUND = {
    group = "Search",
    attr = "fg",
    default = BASE16_COLORS.white,
  },

  -- comment
  COMMENT_FOREGROUND = {
    group = "Comment",
    attr = "fg",
    default = BASE16_COLORS.grey,
  },
  COMMENT_BACKGROUND = {
    group = "Comment",
    attr = "bg",
    default = BASE16_COLORS.black,
  },

  -- constant
  CONSTANT_NUMERIC_FOREGROUND = {
    group = { "Number" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },
  CONSTANT_NUMERIC_FLOAT_FOREGROUND = {
    group = { "Float", "Number" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },
  CONSTANT_LANGUAGE_FOREGROUND = {
    group = { "Boolean" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },
  CONSTANT_CHARACTER_ESCAPE_FOREGROUND = {
    group = { "SpecialChar", "Constant" },
    attr = "fg",
    default = BASE16_COLORS.magenta,
  },
  CONSTANT_CHARACTER_OTHER_FOREGROUND = {
    group = "Character",
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },

  -- string
  STRING_FOREGROUND = {
    group = "String",
    attr = "fg",
    default = BASE16_COLORS.green,
  },
  STRING_REGEXP_FOREGROUND = {
    group = {
      "rubyRegexp",
      "rubyRegexpDelimiter",
      "DiagnosticWarn",
      "LspDiagnosticsDefaultWarning",
      "WarningMsg",
    },
    attr = "fg",
    default = BASE16_COLORS.red,
  },
  RUBY_STRING_REGEXP_FOREGROUND = {
    group = {
      "rubyRegexp",
      "rubyRegexpDelimiter",
      "DiagnosticWarn",
      "LspDiagnosticsDefaultWarning",
      "WarningMsg",
    },
    attr = "fg",
    default = BASE16_COLORS.red,
  },
  STRING_INTERPOLATION_FOREGROUND = {
    group = { "Boolean" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },

  -- variable
  VARIABLE_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  VARIABLE_LANGUAGE_FOREGROUND = {
    group = {
      "@variable.builtin",
      "ErrorMsg",
    },
    attr = "fg",
    default = BASE16_COLORS.red,
  },
  VARIABLE_FUNCTION_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  VARIABLE_PARAMETER_FOREGROUND = {
    group = { "@parameter", "Normal" },
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  VARIABLE_OTHER_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  -- VARIABLE_OTHER_CONSTANT_FOREGROUND = {
  --   group = "Boolean",
  --   attr = "fg",
  --   default = BASE16_COLORS.yellow,
  -- },
  VARIABLE_OTHER_READWRITE_INSTANCE_FOREGROUND = {
    group = {
      "DiagnosticSignWarn",
      "LspDiagnosticsSignWarn",
      "WarningMsg",
    },
    attr = "fg",
    default = BASE16_COLORS.red,
  },

  -- keyword
  KEYWORDS_FOREGROUND = {
    group = "Define",
    attr = "fg",
    default = BASE16_COLORS.magenta,
  },
  KEYWORD_CONTROL_FOREGROUND = {
    group = { "Conditional" },
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  KEYWORD_OPERATOR_FOREGROUND = {
    group = "Operator",
    attr = "fg",
    default = BASE16_COLORS.white,
  },
  KEYWORD_OTHER_FOREGROUND = {
    group = "PreProc",
    attr = "fg",
    default = BASE16_COLORS.white,
  },

  -- storage
  STORAGE_FOREGROUND = {
    group = { "Boolean" },
    attr = "fg",
    default = BASE16_COLORS.yellow,
  },
  STORAGE_TYPE_FOREGROUND = {
    group = { "Identifier", "StorageClass" },
    attr = "fg",
    default = BASE16_COLORS.magenta,
  },

  -- entity
  ENTITY_NAME_FOREGROUND = {
    group = "Pmenu",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  ENTITY_NAME_CLASS_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  EENTITY_OTHER_INHERITED_CLASS_FOREGROUND = {
    group = { "Tag", "Type" },
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  ENTITY_NAME_FUNCTION_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  ENTITY_NAME_LABEL_FOREGROUND = {
    group = "Label",
    attr = "fg",
    default = BASE16_COLORS.orange,
  },
  ENTITY_NAME_TAG_FOREGROUND = {
    group = { "Tag" },
    attr = "fg",
    default = BASE16_COLORS.orange,
  },
  ENTITY_OTHER_ATTRIBUTE_NAME_FOREGROUND = {
    group = { "Tag" },
    attr = "fg",
    default = BASE16_COLORS.orange,
  },

  -- support
  SUPPORT_FUNCTION_FOREGROUND = {
    group = { "Function" },
    attr = "fg",
    default = "#86c1b9",
  },
  SUPPORT_CONSTANT_FOREGROUND = {
    group = "Constant",
    attr = "fg",
    default = "#dc9656",
  },
  SUPPORT_TYPE_AND_CLASS_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = "#7cafc2",
  },
  SUPPORT_OTHER_NAMESPACE_FOREGROUND = {
    group = {
      "SpecialComment",
      "DiagnosticSignInfo",
      "LspDiagnosticsSignInfo",
      "Tag",
    },
    attr = "fg",
    default = "#7cafc2",
  },

  FUNCTIONS_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = BASE16_COLORS.cyan,
  },
  META_PATH_FOREGROUND = {
    group = "helpHyperTextJump",
    attr = "fg",
    default = "#7cafc2",
  },
  INVALID_BACKGROUND = {
    group = { "Exception", "Error" },
    attr = "bg",
    default = "#ab4642",
  },
  INVALID_FOREGROUND = {
    group = { "Exception", "Error" },
    attr = "fg",
    default = "#ab4642",
  },
  INVALID_DEPRECATED_BACKGROUND = {
    group = { "Directory", "helpCommand" },
    attr = "bg",
    default = "#a16946",
  },
  INVALID_DEPRECATED_FOREGROUND = {
    group = { "Directory", "helpCommand" },
    attr = "fg",
    default = "#f8f8f8",
  },
  DIFF_HEADER_FOREGROUND = {
    group = { "LineNr", "SignColumn", "Comment" },
    attr = "fg",
    default = "#585858",
  },
  MARKUP_DELETED_FOREGROUND = {
    group = { "GitSignsDelete", "GitGutterDelete", "DiffDelete", "DiffRemoved" },
    attr = "fg",
    default = "#ab4642",
  },
  MARKUP_INSERTED_FOREGROUND = {
    group = { "GitSignsAdd", "GitGutterAdd", "DiffAdd", "DiffAdded" },
    attr = "fg",
    default = "#a1b56c",
  },
  MARKUP_CHANGED_FOREGROUND = {
    group = { "GitGutterChange", "GitSignsChange", "DiffChange" },
    attr = "fg",
    default = "#ba8baf",
  },
  ENTITY_NAME_FILENAME_FOREGROUND = {
    group = { "Directory", "Tag" },
    attr = "fg",
    default = "#a1b56c",
  },
  PUNCTUATION_ACCESSOR_FOREGROUND = {
    group = { "SpecialKey", "Character", "Special" },
    attr = "fg",
    default = "#ba8baf",
  },
  META_FUNCTION_RETURN_TYPE_FOREGROUND = {
    group = { "PreProc", "Macro", "Special" },
    attr = "fg",
    default = "#ba8baf",
  },
  PUNCTUATION_SECTION_BLOCK_BEGIN_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = "#d8d8d8",
  },
  PUNCTUATION_SECTION_BLOCK_END_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = "#d8d8d8",
  },
  META_CLASS_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = "#f8f8f8",
  },
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

  local hl_caches = {}

  local function cached_retrieve(hl)
    return hl_caches[hl]
  end

  for config_name, configs in pairs(COLOR_CONFIGS) do
    local group = type(configs.group) == "string" and { configs.group }
      or configs.group --[[@as string[] ]]
    local attr = configs.attr
    local default = configs.default
    local placeholder = string.format("{%s}", config_name)
    local found_match = false
    for i, g in ipairs(group) do
      local codes = cached_retrieve(g)
      if strings.not_empty(codes[attr]) then
        payload = payload:gsub(string.format("%s", placeholder), codes[attr])
        found_match = true
        break
      end
    end
    if not found_match then
      payload = payload:gsub(string.format("%s", placeholder), default)
    end
  end
  return {
    name = theme_name,
    payload = payload,
  }
end

return M
