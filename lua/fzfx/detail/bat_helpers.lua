local paths = require("fzfx.commons.paths")
local termcolors = require("fzfx.commons.termcolors")
local strings = require("fzfx.commons.strings")
local jsons = require("fzfx.commons.jsons")
local fileios = require("fzfx.commons.fileios")
local tables = require("fzfx.commons.tables")
local spawn = require("fzfx.commons.spawn")

local constants = require("fzfx.lib.constants")
local shells = require("fzfx.lib.shells")
local log = require("fzfx.lib.log")
local yanks = require("fzfx.detail.yanks")
local config = require("fzfx.config")

local M = {}

--- @return string
M.get_bat_themes_config_dir = function()
  local bat_themes_config_dir = ""
  local sp = spawn.run({ "bat", "--config-dir" }, {
    on_stdout = function(line)
      bat_themes_config_dir = bat_themes_config_dir .. line
    end,
    on_stderr = function(line)
      log.debug("|get_bat_themes_config_dir| on_stderr:%s", vim.inspect(line))
    end,
  })
  sp:wait()
  bat_themes_config_dir = bat_themes_config_dir
    .. (constants.IS_WINDOWS and "\\themes" or "/themes")
  log.debug(
    "|get_bat_themes_config_dir| config dir:%s",
    vim.inspect(bat_themes_config_dir)
  )
  return bat_themes_config_dir
end

--- @return string
M.get_custom_theme_name = function()
  local name = vim.g.colors_name

  --- @param names string[]
  --- @return string[]
  local function upper_firsts(names)
    log.ensure(
      type(names) == "table" and #names > 0,
      "|get_custom_theme_name.upper_firsts| invalid names:%s",
      vim.inspect(names)
    )
    local new_names = {}
    for i, n in ipairs(names) do
      log.ensure(
        type(n) == "string" and string.len(n) > 0,
        "|get_custom_theme_name.upper_firsts| invalid name(%d):%s",
        vim.inspect(i),
        vim.inspect(n)
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
  local function normalize_by(s, delimiter)
    if strings.find(s, delimiter) then
      local splits = strings.split(s, delimiter, { trimempty = true })
      splits = upper_firsts(splits)
      return table.concat(splits, "")
    else
      return s
    end
  end

  local result = name
  result = normalize_by(result, "-")
  result = normalize_by(result, "+")
  result = normalize_by(result, "_")
  result = normalize_by(result, ".")
  result = normalize_by(result, " ")
  return "FzfxNvim" .. result
end

-- The 'theme_template.tmTheme' is forked from:
-- https://github.com/sharkdp/bat/blob/98a2b6bc177050c845f2e12133458826ad1fca72/assets/themes/base16.tmTheme
--
-- And default value is replaced with placeholders, this mapping table is the real value.
local DEFAULT_BASE16_COLORS = {
  BACKGROUND = "#00000000",
  FOREGROUND = "#07000000",
  CARET = "#07000000",
  INVISIBLES = "#08000000",
  LINE_HIGHLIGHT = "#08000000",
  SELECTION = "#0b000000",
  GUTTER = "#0a000000",
  GUTTER_FOREGROUND = "#08000000",
  TEXT_FOREGROUND = "#07000000",
  COMMENT_FOREGROUND = "#08000000",
  PUNCTUATION_FOREGROUND = "#07000000",
  DELIMITERS_FOREGROUND = "#07000000",
  OPERATORS_FOREGROUND = "#07000000",
  KEYWORDS_FOREGROUND = "#05000000",
  VARIABLES_FOREGROUND = "#07000000",
  FUNCTIONS_FOREGROUND = "#04000000",
  LABELS_FOREGROUND = "#0e000000",
  CLASSES_FOREGROUND = "#03000000",
  META_CLASSES_FOREGROUND = "#0f000000",
  METHODS_FOREGROUND = "#04000000",
  STORAGE_FOREGROUND = "#05000000",
  SUPPORT_FOREGROUND = "#06000000",
  STRINGS_FOREGROUND = "#02000000",
  INTEGERS_FOREGROUND = "#09000000",
  FLOATS_FOREGROUND = "#09000000",
  BOOLEAN_FOREGROUND = "#09000000",
  CONSTANTS_FOREGROUND = "#09000000",
  TAGS_FOREGROUND = "#01000000",
  ATTRIBUTES_FOREGROUND = "#09000000",
  ATTRIBUTE_IDS_FOREGROUND = "#04000000",
  SELECTOR_FOREGROUND = "#05000000",
  VALUES_FOREGROUND = "#09000000",
  HEADINGS_FOREGROUND = "#04000000",
  UNITS_FOREGROUND = "#09000000",
  BOLD_FOREGROUND = "#03000000",
  ITALIC_FOREGROUND = "#05000000",
  CODE_FOREGROUND = "#02000000",
  LINK_TEXT_FOREGROUND = "#01000000",
  LINK_URL_FOREGROUND = "#09000000",
  QUOTES_FOREGROUND = "#09000000",
  SEPARATOR_BACKGROUND = "#0b000000",
  SEPARATOR_FOREGROUND = "#07000000",
  INSERTED_FOREGROUND = "#02000000",
  DELETED_FOREGROUND = "#01000000",
  CHANGED_FOREGROUND = "#05000000",
  COLORS_FOREGROUND = "#06000000",
  REGULAR_EXPRESSIONS_FOREGROUND = "#06000000",
  ESCAPE_CHARACTERS_FOREGROUND = "#06000000",
  EMBEDDED_FOREGROUND = "#05000000",
  ILLEGAL_BACKGROUND = "#01000000",
  ILLEGAL_FOREGROUND = "#0f000000",
  BROKEN_BACKGROUND = "#09000000",
  BROKEN_FOREGROUND = "#00000000",
  DEPRECATED_BACKGROUND = "#0e000000",
  DEPRECATED_FOREGROUND = "#0f000000",
  UNIMPLEMENTED_BACKGROUND = "#08000000",
  UNIMPLEMENTED_FOREGROUND = "#0f000000",
}

local COLOR_CONFIGS = {
  BACKGROUND = { group = "Normal", attr = "bg", default = "#00000000" },
  FOREGROUND = { group = "Normal", attr = "fg", default = "#07000000" },
  CARET = { group = "Normal", attr = "fg", default = "#07000000" },
  INVISIBLES = { group = "Normal", attr = "bg", default = "#08000000" },
  LINE_HIGHLIGHT = { group = "CursorLine", attr = "fg", default = "#08000000" },
  SELECTION = { group = "Visual", attr = "bg", default = "#0b000000" },
  GUTTER = { group = "LineNr", attr = "bg", default = "#0a000000" },
  GUTTER_FOREGROUND = { group = "LineNr", attr = "fg", default = "#08000000" },
  TEXT_FOREGROUND = { group = "Normal", attr = "fg", default = "#07000000" },
  COMMENT_FOREGROUND = { group = "Comment", attr = "fg", default = "#08000000" },
  PUNCTUATION_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = "#07000000",
  },
  DELIMITERS_FOREGROUND = {
    group = "Delimiter",
    attr = "fg",
    default = "#07000000",
  },
  OPERATORS_FOREGROUND = {
    group = "Operator",
    attr = "fg",
    default = "#07000000",
  },
  KEYWORDS_FOREGROUND = {
    group = "Keyword",
    attr = "fg",
    default = "#05000000",
  },
  VARIABLES_FOREGROUND = {
    group = "Identifier",
    attr = "fg",
    default = "#07000000",
  },
  FUNCTIONS_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = "#04000000",
  },
  LABELS_FOREGROUND = { group = "Label", attr = "fg", default = "#0e000000" },
  CLASSES_FOREGROUND = {
    group = "Structure",
    attr = "fg",
    default = "#03000000",
  },
  META_CLASSES_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = "#0f000000",
  },
  METHODS_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = "#04000000",
  },
  STORAGE_FOREGROUND = {
    group = "StorageClass",
    attr = "fg",
    default = "#05000000",
  },
  SUPPORT_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = "#06000000",
  },
  STRINGS_FOREGROUND = { group = "String", attr = "fg", default = "#02000000" },
  INTEGERS_FOREGROUND = { group = "Number", attr = "fg", default = "#09000000" },
  FLOATS_FOREGROUND = { group = "Float", attr = "fg", default = "#09000000" },
  BOOLEAN_FOREGROUND = { group = "Boolean", attr = "fg", default = "#09000000" },
  CONSTANTS_FOREGROUND = {
    group = "Constant",
    attr = "fg",
    default = "#09000000",
  },
  TAGS_FOREGROUND = { group = "Tag", attr = "fg", default = "#01000000" },
  ATTRIBUTES_FOREGROUND = {
    group = "Macro",
    attr = "fg",
    default = "#09000000",
  },
  ATTRIBUTE_IDS_FOREGROUND = {
    group = "PreProc",
    attr = "fg",
    default = "#04000000",
  },
  SELECTOR_FOREGROUND = { group = "Visual", attr = "fg", default = "#05000000" },
  VALUES_FOREGROUND = { group = "Constant", attr = "fg", default = "#09000000" },
  HEADINGS_FOREGROUND = { group = "Title", attr = "fg", default = "#04000000" },
  UNITS_FOREGROUND = { group = "Keyword", attr = "fg", default = "#09000000" },
  BOLD_FOREGROUND = { group = "Title", attr = "fg", default = "#03000000" },
  ITALIC_FOREGROUND = { group = "Normal", attr = "fg", default = "#05000000" },
  CODE_FOREGROUND = { group = "Normal", attr = "fg", default = "#02000000" },
  LINK_TEXT_FOREGROUND = {
    group = "helpCommand",
    attr = "fg",
    default = "#01000000",
  },
  LINK_URL_FOREGROUND = {
    group = "helpHyperTextJump",
    attr = "fg",
    default = "#09000000",
  },
  QUOTES_FOREGROUND = {
    group = "Character",
    attr = "fg",
    default = "#09000000",
  },
  SEPARATOR_BACKGROUND = {
    group = "TabLine",
    attr = "bg",
    default = "#0b000000",
  },
  SEPARATOR_FOREGROUND = {
    group = "TabLine",
    attr = "fg",
    default = "#07000000",
  },
  INSERTED_FOREGROUND = {
    group = { "DiffAdd", "DiffAdded" },
    attr = "fg",
    default = "#02000000",
  },
  DELETED_FOREGROUND = { group = { "DiffDelete", "DiffRemoved" }, attr = "fg" },
  CHANGED_FOREGROUND = {
    group = "DiffChange",
    attr = "fg",
    default = "#01000000",
  },
  COLORS_FOREGROUND = {
    group = "ColorColumn",
    attr = "fg",
    default = "#06000000",
  },
  REGULAR_EXPRESSIONS_FOREGROUND = {
    group = "String",
    attr = "fg",
    default = "#06000000",
  },
  ESCAPE_CHARACTERS_FOREGROUND = {
    group = "Special",
    attr = "fg",
    default = "#06000000",
  },
  EMBEDDED_FOREGROUND = {
    group = "Statement",
    attr = "fg",
    default = "#05000000",
  },
  ILLEGAL_BACKGROUND = {
    group = { "Exception", "Error" },
    attr = "bg",
    default = "#01000000",
  },
  ILLEGAL_FOREGROUND = {
    group = { "Exception", "Error" },
    attr = "fg",
    default = "#0f000000",
  },
  BROKEN_BACKGROUND = {
    group = { "Exception", "Error" },
    attr = "bg",
    default = "#09000000",
  },
  BROKEN_FOREGROUND = {
    group = { "Exception", "Error" },
    attr = "fg",
    default = "#00000000",
  },
  DEPRECATED_BACKGROUND = {
    group = "Comment",
    attr = "bg",
    default = "#0e000000",
  },
  DEPRECATED_FOREGROUND = {
    group = "Comment",
    attr = "fg",
    default = "#0f000000",
  },
  UNIMPLEMENTED_BACKGROUND = {
    group = "Comment",
    attr = "bg",
    default = "#08000000",
  },
  UNIMPLEMENTED_FOREGROUND = {
    group = "Comment",
    attr = "fg",
    default = "#0f000000",
  },
}

--- @return {name:string,payload:string}
M.get_custom_theme = function()
  local theme_name = M.get_custom_theme_name()
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
    for i, g in ipairs(group) do
      local codes = cached_retrieve(g)
      if strings.not_empty(codes[attr]) then
        payload = payload:gsub(string.format("%s", placeholder), codes[attr])
      else
        payload = payload:gsub(string.format("%s", placeholder), default)
      end
    end
  end
  return {
    name = theme_name,
    payload = payload,
  }
end

local calculating_bat_colors = false
M.setup = function()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      if calculating_bat_colors then
        return
      end
      calculating_bat_colors = true
      vim.schedule(function()
        calculating_bat_colors = false
      end)
    end,
  })
end

return M
