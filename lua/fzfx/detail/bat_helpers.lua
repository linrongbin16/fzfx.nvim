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

--- @param name string
--- @return string
M._normalize_theme_name = function(name)
  log.ensure(
    type(name) == "string" and string.len(name) > 0,
    "|_normalize_theme_name| invalid name:%s",
    vim.inspect(name)
  )

  --- @param names string[]
  --- @return string[]
  local function upper_firsts(names)
    log.ensure(
      type(names) == "table" and #names > 0,
      "|_normalize_theme_name.upper_firsts| invalid names:%s",
      vim.inspect(names)
    )
    local new_names = {}
    for i, n in ipairs(names) do
      log.ensure(
        type(n) == "string" and string.len(n) > 0,
        "|_normalize_theme_name.upper_firsts| invalid name(%d):%s",
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
  local name = M._normalize_theme_name(vim.g.colors_name)
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
