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
  bat_themes_config_dir = paths.join(bat_themes_config_dir, "themes")
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
      local splits = { s }
      splits = upper_firsts(splits)
      return table.concat(splits, "")
    end
  end

  local result = name
  log.debug(
    "|get_custom_theme_name| name:%s, 1-result:%s",
    vim.inspect(name),
    vim.inspect(result)
  )
  result = normalize_by(result, "-")
  log.debug("|get_custom_theme_name| 2-result:%s", vim.inspect(result))
  result = normalize_by(result, "+")
  log.debug("|get_custom_theme_name| 3-result:%s", vim.inspect(result))
  result = normalize_by(result, "_")
  log.debug("|get_custom_theme_name| 4-result:%s", vim.inspect(result))
  result = normalize_by(result, ".")
  log.debug("|get_custom_theme_name| 5-result:%s", vim.inspect(result))
  result = normalize_by(result, " ")
  log.debug("|get_custom_theme_name| 6-result:%s", vim.inspect(result))
  return "FzfxNvim" .. result
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
  TEXT_FOREGROUND = { group = "Normal", attr = "fg", default = "#d8d8d8" },
  COMMENT_FOREGROUND = { group = "Comment", attr = "fg", default = "#585858" },
  PUNCTUATION_FOREGROUND = {
    group = "Normal",
    attr = "fg",
    default = "#d8d8d8",
  },
  DELIMITERS_FOREGROUND = {
    group = "Delimiter",
    attr = "fg",
    default = "#d8d8d8",
  },
  OPERATORS_FOREGROUND = {
    group = "Operator",
    attr = "fg",
    default = "#d8d8d8",
  },
  KEYWORDS_FOREGROUND = {
    group = "Keyword",
    attr = "fg",
    default = "#ba8baf",
  },
  VARIABLES_FOREGROUND = {
    group = "Identifier",
    attr = "fg",
    default = "#ab4642",
  },
  ENTITY_NAME_FOREGROUND = {
    group = "Pmenu",
    attr = "fg",
    default = "#7cafc2",
  },
  FUNCTIONS_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = "#7cafc2",
  },
  LABELS_FOREGROUND = { group = "Label", attr = "fg", default = "#a16946" },
  CLASSES_FOREGROUND = {
    group = "StorageClass",
    attr = "fg",
    default = "#f7ca88",
  },
  META_CLASSES_FOREGROUND = {
    group = "Type",
    attr = "fg",
    default = "#f8f8f8",
  },
  METHODS_FOREGROUND = {
    group = "Function",
    attr = "fg",
    default = "#7cafc2",
  },
  STORAGE_FOREGROUND = {
    group = "Structure",
    attr = "fg",
    default = "#ba8baf",
  },
  SUPPORT_FOREGROUND = {
    group = "Include",
    attr = "fg",
    default = "#86c1b9",
  },
  STRINGS_FOREGROUND = { group = "String", attr = "fg", default = "#a1b56c" },
  OTHER_SYMBOLS_FOREGROUND = {
    group = { "Directory", "String" },
    attr = "fg",
    default = "#a1b56c",
  },
  INTEGERS_FOREGROUND = { group = "Number", attr = "fg", default = "#dc9656" },
  FLOATS_FOREGROUND = { group = "Float", attr = "fg", default = "#dc9656" },
  BOOLEAN_FOREGROUND = { group = "Boolean", attr = "fg", default = "#dc9656" },
  CONSTANTS_FOREGROUND = {
    group = "Constant",
    attr = "fg",
    default = "#dc9656",
  },
  TAGS_FOREGROUND = { group = "Tag", attr = "fg", default = "#ab4642" },
  ATTRIBUTES_FOREGROUND = {
    group = "PreProc",
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
  UNITS_FOREGROUND = { group = "Keyword", attr = "fg", default = "#dc9656" },
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
  INSERTED_FOREGROUND = {
    group = { "GitSignsAdd", "GitGutterAdd", "DiffAdd", "DiffAdded" },
    attr = "fg",
    default = "#a1b56c",
  },
  DELETED_FOREGROUND = {
    group = { "GitSignsDelete", "GitGutterDelete", "DiffDelete", "DiffRemoved" },
    attr = "fg",
    default = "#ab4642",
  },
  CHANGED_FOREGROUND = {
    group = { "GitGutterChange", "GitSignsChange", "DiffChange" },
    attr = "fg",
    default = "#ba8baf",
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
  ILLEGAL_BACKGROUND = {
    group = { "Exception", "ErrorMsg", "Error" },
    attr = "bg",
    default = "#ab4642",
  },
  ILLEGAL_FOREGROUND = {
    group = { "Exception", "ErrorMsg", "Error" },
    attr = "fg",
    default = "#ab4642",
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
  DEPRECATED_BACKGROUND = {
    group = "Delimiter",
    attr = "bg",
    default = "#a16946",
  },
  DEPRECATED_FOREGROUND = {
    group = "Delimiter",
    attr = "fg",
    default = "#f8f8f8",
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

local building_bat_theme = false
M.build_theme = function()
  if building_bat_theme then
    return
  end
  building_bat_theme = true
  local theme = M.get_custom_theme()
  local theme_dir = M.get_bat_themes_config_dir()
  local sp1 = spawn.run({ "mkdir", "-p", theme_dir }, {
    on_stdout = function(line)
      log.debug("|setup| mkdir on_stderr:%s", vim.inspect(line))
    end,
    on_stderr = function(line)
      log.debug("|setup| mkdir on_stderr:%s", vim.inspect(line))
    end,
  })
  sp1:wait()
  fileios.writefile(
    paths.join(theme_dir, theme.name .. ".tmTheme"),
    theme.payload
  )
  local sp2 = spawn.run({ "bat", "cache", "--build" }, {
    on_stdout = function(line)
      log.debug("|setup| bat cache on_stderr:%s", vim.inspect(line))
    end,
    on_stderr = function(line)
      log.debug("|setup| bat cache on_stderr:%s", vim.inspect(line))
    end,
  })
  sp2:wait()
  vim.schedule(function()
    vim.schedule(function()
      building_bat_theme = false
    end)
  end)
end

M.setup = function()
  M.build_theme()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = M.build_theme })
end

return M
