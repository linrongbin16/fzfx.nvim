-- TextMate theme docs:
--  * Basic description: https://macromates.com/manual/en/language_grammars#naming_conventions
--  * Global: https://www.sublimetext.com/docs/color_schemes.html#global-settings
--  * Scope: https://www.sublimetext.com/docs/scope_naming.html#minimal-scope-coverage
--
-- Neovim Highlight docs:
--  * Basic syntax: https://neovim.io/doc/user/syntax.html#group-name
--
-- Neovim Treesitter Highlight docs:
--  * Basic syntax: https://neovim.io/doc/user/syntax.html#group-name
--  * Treesitter: https://neovim.io/doc/user/treesitter.html#treesitter-highlight
--
-- Neovim Lsp Semantic Highlight docs:
--  * Neovim semantic highlight: https://neovim.io/doc/user/lsp.html#lsp-semantic-highlight
--  * Lsp semantic tokens: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_semanticTokens
--  * Lsp nvim-lspconfig: https://github.com/neovim/neovim/blob/9f15a18fa57f540cb3d0d9d2f45d872038e6f990/src/nvim/highlight_group.c#L288
--  * Detailed explanation: https://gist.github.com/swarn/fb37d9eefe1bc616c2a7e476c0bc0316
--
-- `@lsp.type` is mapping to `SemanticTokenTypes` in specification.
-- `@lsp.mod` is mapping to `SemanticTokenModifiers` in specification.

local str = require("fzfx.commons.str")
local tbl = require("fzfx.commons.tbl")
local color_hl = require("fzfx.commons.color.hl")
local path = require("fzfx.commons.path")
local fileio = require("fzfx.commons.fileio")
local spawn = require("fzfx.commons.spawn")

local consts = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")

local M = {}

-- Utilities {

-- Create directory if it doesn't exist.
-- Returns false if it's already existed, returns true if it's created.
--- @param dir string
--- @return boolean
M._create_dir_if_not_exist = function(dir)
  if path.isdir(dir) then
    return false
  end
  vim.fn.mkdir(dir, "p")
  return true
end

--- @type string?
local cached_theme_dir = nil

-- Returns cached theme dir
--- @return string?
M.get_theme_dir = function()
  if str.not_empty(cached_theme_dir) then
    M._create_dir_if_not_exist(cached_theme_dir --[[@as string]])
  end
  return cached_theme_dir
end

-- Async get bat theme directory, and invoke `callback` function to consume the value.
--- @param callback fun(theme_dir:string?):nil
M.async_get_theme_dir = function(callback)
  log.ensure(consts.HAS_BAT, string.format("|async_get_theme_dir| cannot find %s", consts.BAT))
  log.ensure(
    type(callback) == "function",
    string.format("|async_get_theme_dir| callback(%s) is not a function", vim.inspect(callback))
  )

  local theme_dir = ""
  spawn.run({ consts.BAT, "--config-dir" }, {
    on_stdout = function(line)
      theme_dir = theme_dir .. line
    end,
    on_stderr = function() end,
  }, function(completed)
    cached_theme_dir = path.join(theme_dir, "themes")
    vim.schedule(function()
      M._create_dir_if_not_exist(cached_theme_dir)
      callback(cached_theme_dir)
    end)
  end)
end

-- Vim colorscheme name => bat theme name
--- @type table<string, string>
local THEME_NAMES_MAP = {}

--- @param names string[]
--- @return string[]
M._upper_first = function(names)
  assert(
    type(names) == "table" and #names > 0,
    string.format("|_upper_firsts| invalid names:%s", vim.inspect(names))
  )
  local new_names = {}
  for i, n in ipairs(names) do
    assert(
      type(n) == "string" and string.len(n) > 0,
      string.format("|_upper_firsts| invalid name(%d):%s", vim.inspect(i), vim.inspect(n))
    )
    local new_name = string.sub(n, 1, 1):upper() .. (string.len(n) > 1 and string.sub(n, 2) or "")
    table.insert(new_names, new_name)
  end
  return new_names
end

--- @param s string
--- @param delimiter string
--- @return string
M._normalize_by = function(s, delimiter)
  local splits
  if str.find(s, delimiter) then
    splits = str.split(s, delimiter, { plain = true, trimempty = true })
  else
    splits = { s }
  end
  splits = M._upper_first(splits)
  return table.concat(splits, "")
end

-- Convert vim colorscheme name to bat theme (TextMate) name.
--- @param colorname string
--- @return string
M.get_theme_name = function(colorname)
  assert(type(colorname) == "string" and string.len(colorname) > 0)
  if THEME_NAMES_MAP[colorname] == nil then
    local result = colorname
    result = M._normalize_by(result, "-")
    result = M._normalize_by(result, "+")
    result = M._normalize_by(result, "_")
    result = M._normalize_by(result, ".")
    result = M._normalize_by(result, " ")
    THEME_NAMES_MAP[colorname] = "FzfxNvim" .. result
  end

  return THEME_NAMES_MAP[colorname]
end

-- Convert vim colorscheme name to bat theme's config file name.
--- @param colorname string
--- @return string?
M.get_theme_config_filename = function(colorname)
  local theme_dir = M.get_theme_dir()
  if str.empty(theme_dir) then
    return nil
  end

  local theme_name = M.get_theme_name(colorname)
  log.ensure(
    str.not_empty(theme_name),
    "|get_theme_config_file| failed to get bat theme name from nvim colorscheme name:"
      .. vim.inspect(colorname)
  )
  -- log.debug(
  --   "|get_theme_config_file| theme_dir:%s, theme_name:%s",
  --   vim.inspect(theme_dir),
  --   vim.inspect(theme_name)
  -- )
  return path.join(theme_dir, theme_name .. ".tmTheme")
end

-- Utilities }

-- Render globals.
--
--- @class fzfx._BatThemeGlobalRenderer
--- @field key string
--- @field value string?
local _BatThemeGlobalRenderer = {}

--- @param hls string|string[]
--- @param key string
--- @param attr "fg"|"bg"
--- @return fzfx._BatThemeGlobalRenderer
function _BatThemeGlobalRenderer:new(hls, key, attr)
  local value = color_hl.get_color_with_fallback(hls, attr)
  local o = {
    key = key,
    value = value,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Render this object into string.
--- @return string?
function _BatThemeGlobalRenderer:render()
  if str.empty(self.key) or str.empty(self.value) then
    return nil
  end
  local builder = {
    string.format("          <key>%s</key>", self.key),
    string.format("          <string>%s</string>", self.value),
  }
  return table.concat(builder, "\n")
end

M._BatThemeGlobalRenderer = _BatThemeGlobalRenderer

-- Render scopes.
--
--- @alias fzfx._BatThemeScopeValue {hl:string,scope:string[],foreground:string?,background:string?,font_style:string[],bold:boolean?,italic:boolean?,is_empty:boolean}
--
--- @class fzfx._BatThemeScopeRenderer
--- @field value fzfx._BatThemeScopeValue?
local _BatThemeScopeRenderer = {}

--- @param hl string
--- @param scope string|string[]
--- @param hl_codes table
--- @return fzfx._BatThemeScopeValue?
M._make_scope_value = function(hl, scope, hl_codes)
  if tbl.tbl_empty(hl_codes) then
    return nil
  end
  if type(hl_codes.fg) ~= "number" then
    return nil
  end

  log.ensure(str.not_empty(hl), "|_make_scope_value| invalid hl name")
  log.ensure(
    str.not_empty(scope) or (tbl.tbl_not_empty(scope)),
    string.format("|_make_scope_value| invalid tm scope:%s", vim.inspect(scope))
  )

  local font_style = {}
  if hl_codes.bold then
    table.insert(font_style, "bold")
  end
  if hl_codes.italic then
    table.insert(font_style, "italic")
  end
  if hl_codes.underline then
    table.insert(font_style, "underline")
  end

  local value = {
    hl = hl,
    scope = scope,
    foreground = string.format("#%06x", hl_codes.fg),
    font_style = font_style,
  }

  if type(hl_codes.bg) == "number" then
    value.background = string.format("#%06x", hl_codes.bg)
  end

  return value
end

--- @param highlight string|string[]
--- @param scope string|string[]
--- @return fzfx._BatThemeScopeRenderer
function _BatThemeScopeRenderer:new(highlight, scope)
  local hls
  if type(highlight) == "table" then
    hls = highlight --[[@as string[] ]]
  else
    hls = {
      highlight --[[@as string]],
    }
  end

  local value

  for _, hl in ipairs(hls) do
    local ok, hl_codes = pcall(color_hl.get_hl, hl)
    if ok and tbl.tbl_not_empty(hl_codes) then
      local scope_value = M._make_scope_value(hl, scope, hl_codes)
      if scope_value then
        value = scope_value
        break
      end
    end
  end

  local o = {
    scope = scope,
    value = value,
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param value fzfx._BatThemeScopeValue?
--- @return string?
M._render_scope = function(value)
  if value == nil or tbl.tbl_empty(value) then
    return nil
  end

  local builder = {
    "      <dict>",
  }

  -- value.scope
  local scope_str
  if type(value.scope) == "table" then
    scope_str = table.concat(value.scope --[[@as string[] ]], ", ")
  else
    scope_str = value.scope --[[@as string]]
  end

  table.insert(
    builder,
    string.format(
      [[        <key>name</key>
        <string>%s</string>]],
      scope_str
    )
  )
  table.insert(
    builder,
    string.format(
      [[        <key>scope</key>
        <string>%s</string>]],
      scope_str
    )
  )
  table.insert(builder, "        <key>settings</key>")
  table.insert(builder, "        <dict>")

  -- value.foreground
  if value.foreground then
    table.insert(builder, "          <key>foreground</key>")
    table.insert(builder, string.format("          <string>%s</string>", value.foreground))
  end

  -- value.background
  if value.background then
    table.insert(builder, "          <key>background</key>")
    table.insert(builder, string.format("          <string>%s</string>", value.background))
  end

  -- value.font_style
  if #value.font_style > 0 then
    table.insert(builder, "          <key>fontStyle</key>")
    table.insert(
      builder,
      string.format("          <string>%s</string>", table.concat(value.font_style, ", "))
    )
  end
  table.insert(builder, "        </dict>")
  table.insert(builder, "      </dict>\n")

  return table.concat(builder, "\n")
end

--- @return string?
function _BatThemeScopeRenderer:render()
  return M._render_scope(self.value)
end

--- @return {globals:fzfx._BatThemeGlobalRenderer[],scopes:fzfx._BatThemeScopeRenderer[]}
M._make_renderers = function()
  -- Basic syntax
  local GLOBAL_RENDERERS = {
    _BatThemeGlobalRenderer:new("Normal", "background", "bg"),
    _BatThemeGlobalRenderer:new("Normal", "foreground", "fg"),
    _BatThemeGlobalRenderer:new("NonText", "invisibles", "fg"),
    _BatThemeGlobalRenderer:new({ "Visual" }, "lineHighlight", "bg"),
    _BatThemeGlobalRenderer:new({
      "GitSignsAdd",
      "GitGutterAdd",
      "DiffAdd",
      "DiffAdded",
      "@diff.plus",
      "Added",
    }, "lineDiffAdded", "fg"),
    _BatThemeGlobalRenderer:new({
      "GitSignsChange",
      "GitGutterChange",
      "DiffChange",
      "@diff.delta",
      "Changed",
    }, "lineDiffModified", "fg"),
    _BatThemeGlobalRenderer:new({
      "GitSignsDelete",
      "GitGutterDelete",
      "DiffDelete",
      "DiffRemoved",
      "@diff.minus",
      "Removed",
    }, "lineDiffDeleted", "fg"),
  }

  -- Treesitter syntax
  local SCOPE_RENDERERS = {
    -- comment {
    _BatThemeScopeRenderer:new({ "@comment", "Comment" }, "comment"),
    -- comment }

    -- constant {
    _BatThemeScopeRenderer:new({ "@number", "Number" }, "constant.numeric"),
    _BatThemeScopeRenderer:new({ "@number.float", "Float" }, "constant.numeric.float"),
    _BatThemeScopeRenderer:new({ "@boolean", "Boolean" }, "constant.language"),
    _BatThemeScopeRenderer:new({ "@character", "Character" }, { "constant.character" }),
    _BatThemeScopeRenderer:new(
      { "@string.escape" },
      { "constant.character.escaped", "constant.character.escape" }
    ),
    -- constant }

    -- entity {
    _BatThemeScopeRenderer:new({ "@function", "Function" }, "entity.name.function"),
    _BatThemeScopeRenderer:new({ "@function.call" }, "entity.name.function.call"),
    _BatThemeScopeRenderer:new({ "@constructor" }, "entity.name.function.constructor"),
    _BatThemeScopeRenderer:new({ "@type", "Type" }, { "entity.name.type" }),
    _BatThemeScopeRenderer:new({ "@tag" }, "entity.name.tag"),
    _BatThemeScopeRenderer:new({ "@tag.attribute" }, "entity.other.attribute-name"),
    _BatThemeScopeRenderer:new({ "Structure" }, { "entity.name.union" }),
    _BatThemeScopeRenderer:new({ "Structure" }, { "entity.name.enum" }),
    _BatThemeScopeRenderer:new({ "@markup.heading" }, "entity.name.section"),
    _BatThemeScopeRenderer:new({ "@label", "Label" }, "entity.name.label"),
    _BatThemeScopeRenderer:new({ "@constant", "Constant" }, "entity.name.constant"),
    _BatThemeScopeRenderer:new({ "@type", "Type" }, "entity.other.inherited-class"),
    -- entity }

    -- keyword {
    _BatThemeScopeRenderer:new({ "@keyword", "Keyword" }, "keyword"),
    _BatThemeScopeRenderer:new({ "@keyword.conditional", "Conditional" }, "keyword.control"),
    _BatThemeScopeRenderer:new({ "@keyword.import" }, "keyword.control.import"),
    _BatThemeScopeRenderer:new({ "@operator", "Operator" }, "keyword.operator"),
    _BatThemeScopeRenderer:new({ "@keyword.operator" }, "keyword.operator.word"),
    _BatThemeScopeRenderer:new({ "@keyword.conditional.ternary" }, "keyword.operator.ternary"),
    -- keyword }

    -- markup {
    _BatThemeScopeRenderer:new({
      "@markup.link.url",
    }, "markup.underline.link"),
    _BatThemeScopeRenderer:new({
      "@markup.underline",
    }, "markup.underline"),
    _BatThemeScopeRenderer:new({
      "@markup.strong",
    }, "markup.bold"),
    _BatThemeScopeRenderer:new({
      "@markup.italic",
    }, "markup.italic"),
    _BatThemeScopeRenderer:new({
      "@markup.heading",
    }, "markup.heading"),
    _BatThemeScopeRenderer:new({
      "@markup.list",
    }, "markup.list"),
    _BatThemeScopeRenderer:new({
      "@markup.raw",
    }, "markup.raw"),
    _BatThemeScopeRenderer:new({
      "@markup.quote",
    }, "markup.quote"),
    _BatThemeScopeRenderer:new({
      "GitSignsAdd",
      "GitGutterAdd",
      "DiffAdd",
      "DiffAdded",
      "@diff.plus",
      "Added",
    }, { "markup.inserted" }),
    _BatThemeScopeRenderer:new({
      "GitSignsDelete",
      "GitGutterDelete",
      "DiffDelete",
      "DiffRemoved",
      "@diff.minus",
      "Removed",
    }, { "markup.deleted" }),
    _BatThemeScopeRenderer:new({
      "GitGutterChange",
      "GitSignsChange",
      "DiffChange",
      "@diff.delta",
      "Changed",
    }, { "markup.changed" }),
    -- markup }

    -- meta {
    _BatThemeScopeRenderer:new({ "@attribute" }, { "meta.annotation" }),
    _BatThemeScopeRenderer:new({ "@constant.macro", "Macro" }, { "meta.preprocessor" }),
    -- meta }

    -- storage {
    _BatThemeScopeRenderer:new(
      { "@keyword.function", "Keyword" },
      { "storage.type.function", "keyword.declaration.function" }
    ),
    _BatThemeScopeRenderer:new({ "Structure" }, {
      "storage.type.enum",
      "keyword.declaration.enum",
    }),
    _BatThemeScopeRenderer:new({ "Structure" }, {
      "storage.type.struct",
      "keyword.declaration.struct",
    }),
    _BatThemeScopeRenderer:new({ "@type", "Type" }, { "storage.type", "keyword.declaration.type" }),
    _BatThemeScopeRenderer:new({ "@keyword.storage", "StorageClass" }, "storage.modifier"),
    -- storage }

    -- string {
    _BatThemeScopeRenderer:new({ "@string", "String" }, { "string", "string.quoted" }),
    _BatThemeScopeRenderer:new({ "@string.regexp" }, { "string.regexp" }),
    -- string }

    -- support {
    _BatThemeScopeRenderer:new({ "@function.builtin", "Function" }, "support.function"),
    _BatThemeScopeRenderer:new({ "@constant.builtin", "Constant" }, "support.constant"),
    _BatThemeScopeRenderer:new({ "@type.builtin", "Type" }, "support.type"),
    _BatThemeScopeRenderer:new({ "@type.builtin", "Type" }, "support.class"),
    _BatThemeScopeRenderer:new({ "@module.builtin" }, "support.module"),
    -- support }

    -- variable {
    _BatThemeScopeRenderer:new({ "@function", "Function" }, "variable.function"),
    _BatThemeScopeRenderer:new({ "@variable", "Identifier" }, "variable"),
    _BatThemeScopeRenderer:new({ "@variable.parameter" }, { "variable.parameter" }),
    _BatThemeScopeRenderer:new({ "@variable.builtin" }, { "variable.language" }),
    -- variable }
  }

  return {
    globals = GLOBAL_RENDERERS,
    scopes = SCOPE_RENDERERS,
  }
end

-- TextMate Theme (the `tmTheme` file) renderer.
--
--- @class fzfx._BatThemeRenderer
--- @field template string
--- @field globals fzfx._BatThemeGlobalRenderer[]
--- @field scopes fzfx._BatThemeScopeRenderer[]
local _BatThemeRenderer = {}

--- @return fzfx._BatThemeRenderer
function _BatThemeRenderer:new()
  -- There're 3 sections:
  --
  -- 1. {NAME}
  -- 2. {GLOBAL}
  -- 3. {SCOPE}

  local template = [[
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>author</key>
    <string>Lin Rongbin(linrongbin16@outlook.com)</string>
    <key>name</key>
    <string>{NAME}</string>
    <key>semanticClass</key>
    <string>{NAME}</string>
    <key>colorSpaceName</key>
    <string>sRGB</string>

    <key>settings</key>
    <array>
      <dict>
        <key>settings</key>
        <dict>
          {GLOBAL}
        </dict>
      </dict>

      {SCOPE}

    </array>
    <key>uuid</key>
    <string>uuid</string>
  </dict>
</plist>
]]

  local renderers = M._make_renderers()

  local o = {
    template = template,
    globals = renderers.globals,
    scopes = renderers.scopes,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Render a TextMate theme file (.tmTheme) based on current vim's colorscheme highlighting groups.
--- @param theme_name string
--- @return {name:string,payload:string}
function _BatThemeRenderer:render(theme_name)
  local payload = self.template

  payload = str.replace(payload, "{NAME}", theme_name)

  local globals = {}
  for _, r in ipairs(self.globals) do
    local result = r:render()
    if result then
      table.insert(globals, result)
    end
  end
  local scopes = {}
  for _, r in ipairs(self.scopes) do
    local result = r:render()
    if result then
      table.insert(scopes, result)
    end
  end

  payload = str.replace(payload, "{GLOBAL}", table.concat(globals, "\n"))
  payload = str.replace(payload, "{SCOPE}", table.concat(scopes, "\n"))

  return {
    name = theme_name,
    payload = payload,
  }
end

M._BatThemeRenderer = _BatThemeRenderer

M._BatThemeRendererInstance = nil

local building_bat_theme = false

-- Build a bat theme (`.tmTheme`) file to user's local bat config directory, based on current vim's colorscheme highlighting groups.
--- @param colorname string
M._build_theme = function(colorname)
  log.ensure(str.not_empty(colorname), "|_build_theme| colorname is empty string!")

  local theme_dir = M.get_theme_dir() --[[@as string]]
  if str.empty(theme_dir) then
    return
  end

  log.ensure(
    path.isdir(theme_dir),
    string.format("|_build_theme| bat theme dir(%s) not exist", vim.inspect(theme_dir))
  )

  local theme_name = M.get_theme_name(colorname)
  log.ensure(
    str.not_empty(theme_name),
    "|_build_theme| failed to convert theme name from vim colorscheme name: "
      .. vim.inspect(colorname)
  )

  M._BatThemeRendererInstance = _BatThemeRenderer:new()
  local rendered_result = M._BatThemeRendererInstance:render(theme_name)
  log.ensure(
    tbl.tbl_not_empty(rendered_result),
    "|_build_theme| rendered result is empty, color name:"
      .. vim.inspect(colorname)
      .. ", theme name:"
      .. vim.inspect(theme_name)
  )

  local theme_config_file = M.get_theme_config_filename(colorname) --[[@as string]]
  log.ensure(
    str.not_empty(theme_config_file),
    "|_build_theme| failed to get bat theme config file from nvim colorscheme name:"
      .. vim.inspect(colorname)
  )

  if building_bat_theme then
    return
  end
  building_bat_theme = true

  fileio.asyncwritefile(theme_config_file, rendered_result.payload, function()
    vim.defer_fn(function()
      -- log.debug(
      --   "|_build_theme| dump theme payload, theme_template:%s",
      --   vim.inspect(theme_config_file)
      -- )
      spawn.run({ consts.BAT, "cache", "--build" }, {
        on_stdout = function(line) end,
        on_stderr = function(line) end,
      }, function()
        vim.schedule(function()
          building_bat_theme = false
        end)
      end)
    end, 10)
  end)
end

M.setup = function()
  if not consts.HAS_BAT then
    return
  end

  M.async_get_theme_dir(function()
    vim.schedule(function()
      if str.not_empty(vim.g.colors_name) then
        M._build_theme(vim.g.colors_name)
      end
    end)
  end)

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      vim.schedule(function()
        if str.not_empty(vim.g.colors_name) then
          M._build_theme(vim.g.colors_name)
        end
      end)
    end,
  })
end

return M
