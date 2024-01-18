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

--- @type table<string, string[]>
local BAT_BUILTIN_THEMES = {}

M.get_bat_builtin_themes = function()
  local bat_themes = {}
  local sp = spawn.run({ "bat", "--list-themes" }, {
    on_stdout = function(line)
      if strings.not_empty(line) and strings.startswith(line, "Theme:") then
        table.insert(bat_themes, strings.trim(string.sub(line, 7)))
      end
    end,
    on_stderr = function(line)
      log.debug("|get_bat_builtin_themes| on_stderr:%s", vim.inspect(line))
    end,
  })
  sp:wait()
  log.debug("|get_bat_builtin_themes| themes:%s", vim.inspect(bat_themes))
  return bat_themes
end

--- @param name string
--- @return string[]
M._normalize_name = function(name)
  --- @param s string|string[]
  --- @param delimiter string
  --- @return string[]
  local function normalize_by(s, delimiter)
    if strings.not_empty(s) then
      s = {
        s --[[@as string]],
      }
    end
    local ns = {}
    for i, v in
      ipairs(s --[[@as table]])
    do
      if strings.find(v, delimiter) then
        local splits = strings.split(v, delimiter, { trimempty = true })
        for j, sp in ipairs(splits) do
          table.insert(ns, sp:lower())
        end
      else
        table.insert(ns, v:lower())
      end
    end
  end

  local result = normalize_by(name, "-")
  result = normalize_by(name, "+")
  result = normalize_by(name, "_")
  result = normalize_by(name, " ")
  result = normalize_by(name, ".")
  return result
end

--- @return string?
M.get_matched_theme = function()
  local color_name_splits = M._normalize_name(vim.g.colors_name)
  for builtin_theme, builtin_theme_splits in pairs(BAT_BUILTIN_THEMES) do
    for p, c in ipairs(color_name_splits) do
      for q, b in ipairs(builtin_theme_splits) do
        if
          strings.not_empty(c)
          and strings.not_empty(b)
          and (
            strings.startswith(c, b)
            or strings.endswith(c, b)
            or strings.startswith(b, c)
            or strings.endswith(b, c)
          )
        then
          return builtin_theme
        end
      end
    end
  end
  return nil
end

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
  CARET = "#07000000",
  FOREGROUND = "#07000000",
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

--- @return {name:string,payload:string}
M.get_custom_theme = function()
  local name = M.get_custom_theme_name()
  local template_path = paths.join(
    vim.env._FZFX_NVIM_SELF_PATH --[[@as string]],
    "assets",
    "bat",
    "theme_template.tmTheme"
  )
  local payload = fileios.readfile(template_path, { trim = true }) --[[@as string]]
  payload = payload:gsub("{NAME}", name)

  local normal = termcolors.retrieve("Normal")
  payload = payload:gsub(
    "{BACKGROUND}",
    strings.not_empty(normal.bg) and normal.bg
      or DEFAULT_BASE16_COLORS.BACKGROUND
  )
  payload = payload:gsub(
    "{FOREGROUND}",
    strings.not_empty(normal.fg) and normal.fg
      or DEFAULT_BASE16_COLORS.FOREGROUND
  )
  payload = payload:gsub(
    "{CARET}",
    strings.not_empty(normal.fg) and normal.fg or DEFAULT_BASE16_COLORS.CARET
  )
  payload = payload:gsub(
    "{INVISIBLES}",
    strings.not_empty(normal.bg) and normal.bg
      or DEFAULT_BASE16_COLORS.INVISIBLES
  )
  local cursor_line = termcolors.retrieve("CursorLine")
  payload = payload:gsub(
    "{LINE_HIGHLIGHT}",
    strings.not_empty(cursor_line.fg) and cursor_line.fg
      or DEFAULT_BASE16_COLORS.LINE_HIGHLIGHT
  )
  local visual = termcolors.retrieve("Visual")
  payload = payload:gsub(
    "{SELECTION}",
    strings.not_empty(visual.fg) and visual.fg
      or DEFAULT_BASE16_COLORS.SELECTION
  )
  local line_nr = termcolors.retrieve("LineNr")
  payload = payload:gsub(
    "{GUTTER}",
    strings.not_empty(line_nr.bg) and line_nr.bg or DEFAULT_BASE16_COLORS.GUTTER
  )
  payload = payload:gsub(
    "{GUTTER_FOREGROUND}",
    strings.not_empty(line_nr.fg) and line_nr.fg
      or DEFAULT_BASE16_COLORS.GUTTER_FOREGROUND
  )
  payload = payload:gsub(
    "{TEXT_FOREGROUND}",
    strings.not_empty(normal.fg) and normal.fg
      or DEFAULT_BASE16_COLORS.TEXT_FOREGROUND
  )
  local comment = termcolors.retrieve("Comment")
  payload = payload:gsub(
    "{COMMENT_FOREGROUND}",
    strings.not_empty(comment.fg) and comment.fg
      or DEFAULT_BASE16_COLORS.COMMENT_FOREGROUND
  )
  payload = payload:gsub(
    "{PUNCTUATION_FOREGROUND}",
    strings.not_empty(normal.fg) and normal.fg
      or DEFAULT_BASE16_COLORS.PUNCTUATION_FOREGROUND
  )
  local delimiter = termcolors.retrieve("Delimiter")
  payload = payload:gsub(
    "{DELIMITERS_FOREGROUND}",
    strings.not_empty(delimiter.fg) and delimiter.fg
      or DEFAULT_BASE16_COLORS.DELIMITERS_FOREGROUND
  )
  local operator = termcolors.retrieve("Operator")
  payload = payload:gsub(
    "{OPERATORS_FOREGROUND}",
    strings.not_empty(operator.fg) and operator.fg
      or DEFAULT_BASE16_COLORS.OPERATORS_FOREGROUND
  )
  local keyword = termcolors.retrieve("Keyword")
  payload = payload:gsub(
    "{KEYWORDS_FOREGROUND}",
    strings.not_empty(keyword.fg) and keyword.fg
      or DEFAULT_BASE16_COLORS.KEYWORDS_FOREGROUND
  )
  local identifier = termcolors.retrieve("Identifier")
  payload = payload:gsub(
    "{VARIABLES_FOREGROUND}",
    strings.not_empty(identifier.fg) and identifier.fg
      or DEFAULT_BASE16_COLORS.VARIABLES_FOREGROUND
  )
  local function1 = termcolors.retrieve("Function")
  payload = payload:gsub(
    "{FUNCTIONS_FOREGROUND}",
    strings.not_empty(function1.fg) and function1.fg
      or DEFAULT_BASE16_COLORS.FUNCTIONS_FOREGROUND
  )
  local label = termcolors.retrieve("Label")
  payload = payload:gsub(
    "{LABELS_FOREGROUND}",
    strings.not_empty(label.fg) and label.fg
      or DEFAULT_BASE16_COLORS.LABELS_FOREGROUND
  )
  local structure = termcolors.retrieve("Structure")
  payload = payload:gsub(
    "{CLASSES_FOREGROUND}",
    strings.not_empty(structure.fg) and structure.fg
      or DEFAULT_BASE16_COLORS.CLASSES_FOREGROUND
  )
  local type1 = termcolors.retrieve("Type")
  payload = payload:gsub(
    "{META_CLASSES_FOREGROUND}",
    strings.not_empty(type1.fg) and type1.fg
      or DEFAULT_BASE16_COLORS.META_CLASSES_FOREGROUND
  )
  payload = payload:gsub(
    "{METHODS_FOREGROUND}",
    strings.not_empty(function1.fg) and function1.fg
      or DEFAULT_BASE16_COLORS.METHODS_FOREGROUND
  )
  local storage_class = termcolors.retrieve("StorageClass")
  payload = payload:gsub(
    "{STORAGE_FOREGROUND}",
    strings.not_empty(storage_class.fg) and storage_class.fg
      or DEFAULT_BASE16_COLORS.STORAGE_FOREGROUND
  )
  payload = payload:gsub(
    "{SUPPORT_FOREGROUND}",
    strings.not_empty(function1.fg) and function1.fg
      or DEFAULT_BASE16_COLORS.SUPPORT_FOREGROUND
  )
  local string1 = termcolors.retrieve("String")
  payload = payload:gsub(
    "{STRINGS_FOREGROUND}",
    strings.not_empty(string1.fg) and string1.fg
      or DEFAULT_BASE16_COLORS.STRINGS_FOREGROUND
  )
  local number1 = termcolors.retrieve("Number")
  payload = payload:gsub(
    "{INTEGERS_FOREGROUND}",
    strings.not_empty(number1.fg) and number1.fg
      or DEFAULT_BASE16_COLORS.INTEGERS_FOREGROUND
  )
  local float1 = termcolors.retrieve("Float")
  payload = payload:gsub(
    "{FLOATS_FOREGROUND}",
    strings.not_empty(float1.fg) and float1.fg
      or DEFAULT_BASE16_COLORS.FLOATS_FOREGROUND
  )
  local boolean1 = termcolors.retrieve("Boolean")
  payload = payload:gsub(
    "{BOOLEAN_FOREGROUND}",
    strings.not_empty(boolean1.fg) and boolean1.fg
      or DEFAULT_BASE16_COLORS.BOOLEAN_FOREGROUND
  )
  local constant1 = termcolors.retrieve("Constant")
  payload = payload:gsub(
    "{CONSTANTS_FOREGROUND}",
    strings.not_empty(constant1.fg) and constant1.fg
      or DEFAULT_BASE16_COLORS.CONSTANTS_FOREGROUND
  )
  local tag = termcolors.retrieve("Tag")
  payload = payload:gsub(
    "{TAGS_FOREGROUND}",
    strings.not_empty(tag.fg) and tag.fg
      or DEFAULT_BASE16_COLORS.TAGS_FOREGROUND
  )
  local macro = termcolors.retrieve("Macro")
  payload = payload:gsub(
    "{ATTRIBUTES_FOREGROUND}",
    strings.not_empty(macro.fg) and macro.fg
      or DEFAULT_BASE16_COLORS.ATTRIBUTES_FOREGROUND
  )
  payload = payload:gsub(
    "{ATTRIBUTE_IDS_FOREGROUND}",
    strings.not_empty(identifier.fg) and identifier.fg
      or DEFAULT_BASE16_COLORS.ATTRIBUTE_IDS_FOREGROUND
  )
  payload = payload:gsub(
    "{SELECTOR_FOREGROUND}",
    strings.not_empty(visual.fg) and visual.fg
      or DEFAULT_BASE16_COLORS.SELECTOR_FOREGROUND
  )
  payload = payload:gsub(
    "{VALUES_FOREGROUND}",
    strings.not_empty(constant1.fg) and constant1.fg
      or DEFAULT_BASE16_COLORS.SELECTOR_FOREGROUND
  )
  local title = termcolors.retrieve("Title")
  payload = payload:gsub(
    "{HEADINGS_FOREGROUND}",
    strings.not_empty(title.fg) and title.fg
      or DEFAULT_BASE16_COLORS.HEADINGS_FOREGROUND
  )
  payload = payload:gsub(
    "{UNITS_FOREGROUND}",
    strings.not_empty(keyword.fg) and keyword.fg
      or DEFAULT_BASE16_COLORS.UNITS_FOREGROUND
  )
  payload = payload:gsub(
    "{BOLD_FOREGROUND}",
    strings.not_empty(normal.fg) and normal.fg
      or DEFAULT_BASE16_COLORS.BOLD_FOREGROUND
  )
  payload = payload:gsub(
    "{ITALIC_FOREGROUND}",
    strings.not_empty(normal.fg) and normal.fg
      or DEFAULT_BASE16_COLORS.ITALIC_FOREGROUND
  )
  local preproc = termcolors.retrieve("PreProc")
  payload = payload:gsub(
    "{CODE_FOREGROUND}",
    strings.not_empty(preproc.fg) and preproc.fg
      or DEFAULT_BASE16_COLORS.CODE_FOREGROUND
  )

  local help_command = termcolors.retrieve("helpCommand")
  payload = payload:gsub(
    "{LINK_TEXT_FOREGROUND}",
    strings.not_empty(help_command.fg) and help_command.fg
      or DEFAULT_BASE16_COLORS.LINK_TEXT_FOREGROUND
  )
  local help_hyper = termcolors.retrieve("helpHyperTextJump")
  payload = payload:gsub(
    "{LINK_URL_FOREGROUND}",
    strings.not_empty(help_hyper.fg) and help_hyper.fg
      or DEFAULT_BASE16_COLORS.LINK_URL_FOREGROUND
  )
  local character = termcolors.retrieve("Character")
  payload = payload:gsub(
    "{QUOTES_FOREGROUND}",
    strings.not_empty(character.fg) and character.fg
      or DEFAULT_BASE16_COLORS.QUOTES_FOREGROUND
  )
  local tabline = termcolors.retrieve("TabLine")
  payload = payload:gsub(
    "{SEPARATOR_BACKGROUND}",
    strings.not_empty(tabline.bg) and tabline.bg
      or DEFAULT_BASE16_COLORS.SEPARATOR_BACKGROUND
  )
  payload = payload:gsub(
    "{SEPARATOR_FOREGROUND}",
    strings.not_empty(tabline.fg) and tabline.fg
      or DEFAULT_BASE16_COLORS.SEPARATOR_FOREGROUND
  )
  local diff_add = termcolors.retrieve("DiffAdd")
  local diff_added = termcolors.retrieve("DiffAdded")
  payload = payload:gsub(
    "{INSERTED_FOREGROUND}",
    strings.not_empty(diff_add.fg) and diff_add.fg
      or (
        strings.not_empty(diff_added.fg) and diff_added.fg
        or DEFAULT_BASE16_COLORS.INSERTED_FOREGROUND
      )
  )
  local diff_delete = termcolors.retrieve("DiffDelete")
  local diff_removed = termcolors.retrieve("DiffRemoved")
  payload = payload:gsub(
    "{DELETED_FOREGROUND}",
    strings.not_empty(diff_delete.fg) and diff_delete.fg
      or (
        strings.not_empty(diff_removed).fg and diff_removed.fg
        or DEFAULT_BASE16_COLORS.DELETED_FOREGROUND
      )
  )
  local diff_change = termcolors.retrieve("DiffChange")
  payload = payload:gsub(
    "{CHANGED_FOREGROUND}",
    strings.not_empty(diff_change.fg) and diff_change.fg
      or DEFAULT_BASE16_COLORS.CHANGED_FOREGROUND
  )
  local color_column = termcolors.retrieve("ColorColumn")
  payload = payload:gsub(
    "{COLORS_FOREGROUND}",
    strings.not_empty(color_column.fg) and color_column.fg
      or DEFAULT_BASE16_COLORS.COLORS_FOREGROUND
  )
  payload = payload:gsub(
    "{REGULAR_EXPRESSIONS_FOREGROUND}",
    strings.not_empty(string1.fg) and string1.fg
      or DEFAULT_BASE16_COLORS.REGULAR_EXPRESSIONS_FOREGROUND
  )
  payload = payload:gsub(
    "{ESCAPE_CHARACTERS_FOREGROUND}",
    strings.not_empty(character.fg) and character.fg
      or DEFAULT_BASE16_COLORS.ESCAPE_CHARACTERS_FOREGROUND
  )
  payload = payload:gsub(
    "{EMBEDDED_FOREGROUND}",
    strings.not_empty(normal.fg) and normal.fg
      or DEFAULT_BASE16_COLORS.EMBEDDED_FOREGROUND
  )
  local error1 = termcolors.retrieve("Error")
  payload = payload:gsub(
    "{ILLEGAL_BACKGROUND}",
    strings.not_empty(error1.bg) and error1.bg
      or DEFAULT_BASE16_COLORS.ILLEGAL_BACKGROUND
  )
  payload = payload:gsub(
    "{ILLEGAL_FOREGROUND}",
    strings.not_empty(error1.fg) and error1.fg
      or DEFAULT_BASE16_COLORS.ILLEGAL_FOREGROUND
  )
  payload = payload:gsub(
    "{BROKEN_BACKGROUND}",
    strings.not_empty(error1.bg) and error1.bg
      or DEFAULT_BASE16_COLORS.BROKEN_BACKGROUND
  )
  payload = payload:gsub(
    "{BROKEN_FOREGROUND}",
    strings.not_empty(error1.fg) and error1.fg
      or DEFAULT_BASE16_COLORS.BROKEN_FOREGROUND
  )
  payload = payload:gsub(
    "{DEPRECATED_BACKGROUND}",
    strings.not_empty(comment.fg) and comment.fg
      or DEFAULT_BASE16_COLORS.DEPRECATED_BACKGROUND
  )
  payload = payload:gsub(
    "{DEPRECATED_FOREGROUND}",
    strings.not_empty(comment.fg) and comment.fg
      or DEFAULT_BASE16_COLORS.DEPRECATED_FOREGROUND
  )
  payload = payload:gsub(
    "{UNIMPLEMENTED_BACKGROUND}",
    strings.not_empty(comment.bg) and comment.bg
      or DEFAULT_BASE16_COLORS.UNIMPLEMENTED_BACKGROUND
  )
  payload = payload:gsub(
    "{UNIMPLEMENTED_FOREGROUND}",
    strings.not_empty(comment.fg) and comment.fg
      or DEFAULT_BASE16_COLORS.UNIMPLEMENTED_FOREGROUND
  )
  return {
    name = name,
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
