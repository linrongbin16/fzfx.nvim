local paths = require("fzfx.commons.paths")
local termcolors = require("fzfx.commons.termcolors")
local strings = require("fzfx.commons.strings")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")

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

-- The 'theme_template.tmTheme' is forked from: https://github.com/sharkdp/bat/blob/98a2b6bc177050c845f2e12133458826ad1fca72/assets/themes/base16.tmTheme
-- default color is forked from: https://github.com/chriskempson/base16-textmate/blob/0e51ddd568bdbe17189ac2a07eb1c5f55727513e/Themes/base16-default-dark.tmTheme
local COLOR_CONFIGS = {
  -- gutterSettings
  GUTTER_BACKGROUND = {
    group = "LineNr",
    attr = "bg",
    default = "#282828",
  },
  GUTTER_DIVIDER = {
    group = "LineNr",
    attr = "bg",
    default = "#282828",
  },
  GUTTER_FOREGROUND = {
    group = "LineNr",
    attr = "fg",
    default = "#585858",
  },
  GUTTER_SELECTION_FOREGROUND = {
    group = "CursorLineNr",
    attr = "fg",
    default = "#b8b8b8",
  },
  GUTTER_SELECTION_BACKGROUND = {
    group = "CursorLineNr",
    attr = "bg",
    default = "#383838",
  },
  -- settings
  BACKGROUND = {
    group = "Normal",
    attr = "bg",
    default = "#181818",
  },
  CARET = {
    group = "Cursor",
    attr = "fg",
    default = "#d8d8d8",
  },
  BLOCK_CARET = {
    group = "Cursor",
    attr = "fg",
    default = "#d8d8d8",
  },
  FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = "#d8d8d8",
  },
  INVISIBLES = {
    group = "NonText",
    attr = "bg",
    default = "#585858",
  },
  LINE_HIGHLIGHT = { group = "CursorLine", attr = "bg", default = "#58585855" },
  SELECTION = { group = "Visual", attr = "bg", default = "#383838" },
  FIND_HIGHLIGHT = {
    group = { "Search", "IncSearch" },
    attr = "bg",
    default = "#dc9656",
  },
  FIND_HIGHLIGHT_FOREGROUND = {
    group = { "Search", "IncSearch" },
    attr = "fg",
    default = "#d8d8d8",
  },
  BRACKETS_FOREGROUND = {
    group = { "Normal" },
    attr = "fg",
    default = "#d8d8d8",
  },
  BRACKET_CONTENTS_FOREGROUND = {
    group = { "Normal" },
    attr = "fg",
    default = "#d8d8d8",
  },

  COMMENT_FOREGROUND = { group = "Comment", attr = "fg", default = "#585858" },
  STRINGS_FOREGROUND = { group = "String", attr = "fg", default = "#a1b56c" },
  NUMBERS_FOREGROUND = { group = "Number", attr = "fg", default = "#dc9656" },

  CONSTANT_LANGUAGE_FOREGROUND = {
    group = "Constant",
    attr = "fg",
    default = "#dc9656",
  },
  CONSTANT_CHARACTER_OTHER_FOREGROUND = {
    group = "Constant",
    attr = "fg",
    default = "#dc9656",
  },

  VARIABLE_FOREGROUND = {
    group = "Identifier",
    attr = "fg",
    default = "#ab4642",
  },
  VARIABLE_OTHER_READWRITE_INSTANCE_FOREGROUND = {
    group = {
      "DiagnosticSignWarn",
      "LspDiagnosticsSignWarn",
      "WarningMsg",
    },
    attr = "fg",
    default = "#ab4642",
  },
  STRING_INTERPOLATION_FOREGROUND = {
    group = { "Character" },
    attr = "fg",
    default = "#ab4642",
  },
  RUBY_REGEXP_FOREGROUND = {
    group = {
      "DiffDelete",
      "DiffRemoved",
      "ErrorMsg",
    },
    attr = "fg",
    default = "#ab4642",
  },
  KEYWORDS_FOREGROUND = {
    group = "Keyword",
    attr = "fg",
    default = "#ba8baf",
  },
  STORAGE_FOREGROUND = {
    group = { "StorageClass", "SpecialKey" },
    attr = "fg",
    default = "#ba8baf",
  },
  STORAGE_TYPE_FOREGROUND = {
    group = {
      "SpecialComment",
      "DiagnosticSignInfo",
      "LspDiagnosticsSignInfo",
      "Tag",
    },
    attr = "fg",
    default = "#7cafc2",
  },
  STORAGE_TYPE_NAMESPACE_FOREGROUND = {
    group = {
      "SpecialComment",
      "DiagnosticSignInfo",
      "LspDiagnosticsSignInfo",
      "Tag",
    },
    attr = "fg",
    default = "#7cafc2",
  },
  STORAGE_TYPE_CLASS_FOREGROUND = {
    group = {
      "Typedef",
      "SpecialKey",
    },
    attr = "fg",
    default = "#7cafc2",
  },
  ENTITY_NAME_CLASS_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = "#7cafc2",
  },
  META_PATH_FOREGROUND = {
    group = "helpHyperTextJump",
    attr = "fg",
    default = "#7cafc2",
  },
  ENTITY_OTHER_INHERITED_CLASS = {
    group = { "DiagnosticInfo", "LspDiagnosticsDefaultInformation", "Tag" },
    attr = "fg",
    default = "#7cafc2",
  },
  ENTITY_FUNCTION_NAME_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = "#7cafc2",
  },
  ENTITY_NAME_TAG_FOREGROUND = {
    group = { "SpecialKey", "Tag" },
    attr = "fg",
    default = "#7cafc2",
  },
  ENTITY_OTHER_ATTRIBUTE_NAME_FOREGROUND = {
    group = { "Tag" },
    attr = "fg",
    default = "#a1b56c",
  },
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
  VARIABLE_FUNCTION_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = "#7cafc2",
  },
  VARIABLE_OTHER_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = "#d8d8d8",
  },
  VARIABLE_LANGUAGE_FOREGROUND = {
    group = { "WildMenu", "helpCommand" },
    attr = "fg",
    default = "#dc9656",
  },
  ENTITY_NAME_FOREGROUND = {
    group = "Pmenu",
    attr = "fg",
    default = "#7cafc2",
  },
  ENTITY_NAME_LABEL_FOREGROUND = {
    group = "Label",
    attr = "fg",
    default = "#a16946",
  },
  META_CLASS_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = "#f8f8f8",
  },
  KEYWORD_OPERATOR_FOREGROUND = {
    group = "Operator",
    attr = "fg",
    default = "#d8d8d8",
  },
  OTHER_KEYWORDS_FOREGROUND = {
    group = { "PreProc", "Function" },
    attr = "fg",
    default = "#7cafc2",
  },
  METHODS_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = "#7cafc2",
  },
  OTHER_SYMBOLS_FOREGROUND = {
    group = { "Directory", "String" },
    attr = "fg",
    default = "#a1b56c",
  },
  FLOATS_FOREGROUND = { group = "Float", attr = "fg", default = "#dc9656" },
  BOOLEAN_FOREGROUND = { group = "Boolean", attr = "fg", default = "#dc9656" },
  CONSTANTS_FOREGROUND = {
    group = "Constant",
    attr = "fg",
    default = "#dc9656",
  },
  ATTRIBUTE_IDS_FOREGROUND = {
    group = "Macro",
    attr = "fg",
    default = "#7cafc2",
  },
  SELECTOR_FOREGROUND = { group = "Operator", attr = "fg", default = "#ba8baf" },
  VALUES_FOREGROUND = { group = "Constant", attr = "fg", default = "#dc9656" },
  HEADINGS_FOREGROUND = { group = "Title", attr = "fg", default = "#7cafc2" },
  UNITS_FOREGROUND = {
    group = { "PreProc", "Function" },
    attr = "fg",
    default = "#dc9656",
  },
  BOLD_FOREGROUND = { group = "Search", attr = "fg", default = "#f7ca88" },
  ITALIC_FOREGROUND = {
    group = "Conditional",
    attr = "fg",
    default = "#ba8baf",
  },
  CODE_FOREGROUND = { group = "String", attr = "fg", default = "#a1b56c" },
  LINK_TEXT_FOREGROUND = {
    group = "WildMenu",
    attr = "fg",
    default = "#ab4642",
  },
  LINK_URL_FOREGROUND = {
    group = "Constant",
    attr = "fg",
    default = "#dc9656",
  },
  LISTS_FOREGROUND = { group = "Character", attr = "fg", default = "#ab4642" },
  QUOTES_FOREGROUND = {
    group = "Constant",
    attr = "fg",
    default = "#dc9656",
  },
  SEPARATOR_BACKGROUND = {
    group = "StatusLine",
    attr = "bg",
    default = "#383838",
  },
  SEPARATOR_FOREGROUND = {
    group = "StatusLine",
    attr = "fg",
    default = "#d8d8d8",
  },
  COLORS_FOREGROUND = {
    group = "FoldColumn",
    attr = "fg",
    default = "#86c1b9",
  },
  REGULAR_EXPRESSIONS_FOREGROUND = {
    group = "Special",
    attr = "fg",
    default = "#86c1b9",
  },
  ESCAPE_CHARACTERS_FOREGROUND = {
    group = "Special",
    attr = "fg",
    default = "#86c1b9",
  },
  EMBEDDED_FOREGROUND = {
    group = "Define",
    attr = "fg",
    default = "#ba8baf",
  },
  BROKEN_BACKGROUND = {
    group = { "WarningMsg", "IncSearch" },
    attr = "bg",
    default = "#dc9656",
  },
  BROKEN_FOREGROUND = {
    group = { "WarningMsg", "IncSearch" },
    attr = "fg",
    default = "#dc9656",
  },
  UNIMPLEMENTED_BACKGROUND = {
    group = "Comment",
    attr = "bg",
    default = "#585858",
  },
  UNIMPLEMENTED_FOREGROUND = {
    group = "Comment",
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
  payload = payload:gsub("{NAME}", theme_name)

  local hl_caches = {}

  local function cached_retrieve(hl)
    if hl_caches[hl] == nil then
      hl_caches[hl] = termcolors.retrieve(hl)
    end
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
