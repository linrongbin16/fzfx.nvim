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
local switches = require("fzfx.lib.switches")
local log = require("fzfx.lib.log")

local bat_themes_helper = require("fzfx.helper.bat_themes")

local M = {}

--- @type boolean?
M._nvim_treesitter_exists = nil

--- @param ind integer
--- @param fmt string
--- @param ... any
--- @return string
M._indent = function(ind, fmt, ...)
  fmt = string.rep(" ", ind) .. fmt
  return string.format(fmt, ...)
end

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
--- @return string[]|nil
function _BatThemeGlobalRenderer:render()
  if str.empty(self.key) or str.empty(self.value) then
    return nil
  end

  local IND_10 = 10
  return tbl.List
    :of(
      M._indent(IND_10, "<key>%s</key>", self.key),
      M._indent(IND_10, "<string>%s</string>", self.value)
    )
    :data()
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

--- @param hl string
--- @return boolean
local function _is_treesitter_hl(hl)
  local result = str.not_empty(hl) and str.startswith(hl, "@") and not str.startswith(hl, "@lsp")
  -- log.debug(
  --   string.format("is_treesitter_hl - hl:%s,result:%s", vim.inspect(hl), vim.inspect(result))
  -- )
  return result
end

--- @param hls string[]
--- @param scope string|string[]
--- @return fzfx._BatThemeScopeRenderer
function _BatThemeScopeRenderer:new(hls, scope)
  assert(type(hls) == "table")

  local new_hls = {}
  for _, hl in ipairs(hls) do
    -- If "nvim-treesitter" doesn't exist, and `hl` is a treesitter hl, skip it.
    -- Otherwise, add it to `new_hls` list.
    if not (not M._nvim_treesitter_exists and _is_treesitter_hl(hl)) then
      table.insert(new_hls, hl)
    end
  end
  -- log.debug(
  --   string.format(
  --     "BatThemeScopeRenderer:new-0 - ts_exist:%s,(old)hls:%s,new_hls:%s",
  --     vim.inspect(M._nvim_treesitter_exists),
  --     vim.inspect(hls),
  --     vim.inspect(new_hls)
  --   )
  -- )
  hls = new_hls

  local value
  for _, hl in ipairs(hls) do
    local ok, hl_codes = pcall(color_hl.get_hl, hl)
    -- log.debug(
    --   string.format(
    --     "BatThemeScopeRenderer:new-1 - hl:%s,hl_codes:%s",
    --     vim.inspect(hl),
    --     vim.inspect(hl_codes)
    --   )
    -- )
    if ok and tbl.tbl_not_empty(hl_codes) then
      local scope_value = M._make_scope_value(hl, scope, hl_codes)
      if scope_value then
        value = scope_value
        -- log.debug(
        --   string.format(
        --     "BatThemeScopeRenderer:new-2 - hl:%s,hl_codes:%s,value:%s",
        --     vim.inspect(hl),
        --     vim.inspect(hl_codes),
        --     vim.inspect(value)
        --   )
        -- )
        break
      end
    end
  end

  local o = {
    scope = scope,
    value = value,
  }
  -- log.debug(
  --   string.format("BatThemeScopeRenderer:new-3 - hls:%s,o:%s", vim.inspect(hls), vim.inspect(o))
  -- )

  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param value fzfx._BatThemeScopeValue?
--- @return string[]|nil
M._render_scope = function(value)
  if value == nil or tbl.tbl_empty(value) then
    return nil
  end

  local IND_6 = 6
  local IND_8 = 8
  local IND_10 = 10

  local builder = tbl.List:of()
  builder:push(M._indent(IND_6, "<dict>"))

  -- value.scope
  local scope_str
  if type(value.scope) == "table" then
    scope_str = table.concat(value.scope --[[@as string[] ]], ", ")
  else
    scope_str = value.scope --[[@as string]]
  end

  builder:push(M._indent(IND_8, "<key>name</key>"))
  builder:push(M._indent(IND_8, "<string>%s</string>", scope_str))
  builder:push(M._indent(IND_8, "<key>scope</key>"))
  builder:push(M._indent(IND_8, "<string>%s</string>", scope_str))

  builder:push(M._indent(IND_8, "<key>settings</key>"))
  builder:push(M._indent(IND_8, "<dict>"))

  -- value.foreground
  if value.foreground then
    builder:push(M._indent(IND_10, "<key>foreground</key>"))
    builder:push(M._indent(IND_10, "<string>%s</string>", value.foreground))
  end

  -- value.background
  if value.background then
    builder:push(M._indent(IND_10, "<key>background</key>"))
    builder:push(M._indent(IND_10, "<string>%s</string>", value.background))
  end

  -- value.font_style
  if type(value.font_style) == "table" and #value.font_style > 0 then
    builder:push(M._indent(IND_10, "<key>fontStyle</key>"))
    builder:push(M._indent(IND_10, "<string>%s</string>", table.concat(value.font_style, ", ")))
  end

  builder:push(M._indent(IND_8, "</dict>"))
  builder:push(M._indent(IND_6, "</dict>"))

  return builder:data()
end

--- @return string[]|nil
function _BatThemeScopeRenderer:render()
  return M._render_scope(self.value)
end

M._BatThemeScopeRenderer = _BatThemeScopeRenderer

--- @return {globals:fzfx._BatThemeGlobalRenderer[],scopes:fzfx._BatThemeScopeRenderer[]}
M._make_renderers = function()
  -- Detect if "nvim-treesitter" is installed
  local ok, nvim_ts = pcall(require, "nvim-treesitter")
  if ok and nvim_ts then
    M._nvim_treesitter_exists = true
  else
    M._nvim_treesitter_exists = false
  end

  -- Global theme
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

  -- Scope theme
  local SCOPE_RENDERERS = {
    -- comment {
    _BatThemeScopeRenderer:new({ "@lsp.type.comment", "@comment", "Comment" }, "comment"),
    -- comment }

    -- constant {
    _BatThemeScopeRenderer:new({ "@constant", "Constant" }, "constant"),
    _BatThemeScopeRenderer:new({ "@number", "Number" }, "constant.numeric"),
    _BatThemeScopeRenderer:new({ "@number.float", "Float" }, "constant.numeric.float"),
    _BatThemeScopeRenderer:new({ "@constant.builtin", "Boolean" }, "constant.language"),
    _BatThemeScopeRenderer:new(
      { "@character", "Character" },
      { "constant.character", "character" }
    ),
    _BatThemeScopeRenderer:new({ "@string", "String" }, { "string", "string.quoted" }),
    _BatThemeScopeRenderer:new({ "@string.regexp" }, { "string.regexp" }),
    _BatThemeScopeRenderer:new(
      { "@string.escape", "Special" },
      { "constant.character.escaped", "constant.character.escape" }
    ),
    -- constant }

    -- entity {
    _BatThemeScopeRenderer:new(
      { "@lsp.typemod.static.declaration", "@constant", "Constant" },
      "entity.name.constant"
    ),
    _BatThemeScopeRenderer:new(
      { "@lsp.type.method", "@lsp.type.function", "@function.call", "Function" },
      { "variable.function" }
    ),
    _BatThemeScopeRenderer:new({ "@lsp.type.method" }, { "entity.name.function" }),
    _BatThemeScopeRenderer:new({ "@lsp.type.macro", "@function.macro" }, { "support.macro" }),
    _BatThemeScopeRenderer:new(
      { "@lsp.typemod.function.defaultLibrary", "@function.builtin" },
      { "support.function.builtin" }
    ),
    _BatThemeScopeRenderer:new({ "@type", "Type" }, { "storage.type", "support.type" }),
    _BatThemeScopeRenderer:new(
      { "@lsp.typemod.keyword.documentation" },
      { "entity.name.tag.documentation" }
    ),
    _BatThemeScopeRenderer:new({ "@lsp.type.property" }, { "meta.property" }),
    -- entity }

    -- variable {
    _BatThemeScopeRenderer:new({ "@variable" }, "variable.other"),
    _BatThemeScopeRenderer:new({ "@variable.member" }, { "variable.other.member" }),
    _BatThemeScopeRenderer:new(
      { "@lsp.type.parameter", "@variable.parameter" },
      { "variable.parameter" }
    ),
    _BatThemeScopeRenderer:new({ "@variable.builtin" }, { "variable.language" }),
    _BatThemeScopeRenderer:new(
      { "@lsp.typemod.variable.defaultLibrary", "@module.builtin" },
      { "support.constant.builtin" }
    ),
    -- variable }

    -- Puncuation {
    _BatThemeScopeRenderer:new({ "@puncuation.bracket", "Delimiter" }, "puncuation.brackets"),
    _BatThemeScopeRenderer:new({ "@puncuation.delimiter", "Delimiter" }, "puncuation.terminator"),
    -- Puncuation }

    -- keyword {
    _BatThemeScopeRenderer:new({ "@keyword", "Keyword" }, "keyword"),
    _BatThemeScopeRenderer:new({ "@keyword", "StorageClass" }, "keyword.declaration.variable"),
    _BatThemeScopeRenderer:new({ "@keyword.modifier", "StorageClass" }, "storage.modifier"),
    _BatThemeScopeRenderer:new({ "@keyword.import" }, "keyword.declaration.import"),
    _BatThemeScopeRenderer:new(
      { "@operator", "Operator" },
      { "keyword.operator.assignment", "keyword.operator" }
    ),
    _BatThemeScopeRenderer:new({ "@keyword.conditional", "Conditional" }, "keyword.control"),
    -- keyword }

    -- meta {
    _BatThemeScopeRenderer:new({ "@lsp.type.namespace", "@module" }, "meta.path"),
    -- meta }

    -- markup {
    _BatThemeScopeRenderer:new(
      { "htmlTag" },
      { "puncuation.definition.tag.begin.html", "puncuation.definition.tag.end.html" }
    ),
    _BatThemeScopeRenderer:new({ "htmlString" }, { "string.quoted.double.html" }),
    _BatThemeScopeRenderer:new(
      { "htmlTagName" },
      { "entity.name.tag.block.any.html", "entity.name.tag.inline.any.html" }
    ),
    _BatThemeScopeRenderer:new({ "htmlArg" }, "entity.other.attribute-name.html"),
    _BatThemeScopeRenderer:new(
      { "@markup.link", "markdownUrl", "markdownLink" },
      "markup.underline.link.markdown"
    ),
    -- _BatThemeScopeRenderer:new({ "markdownUrl", "markdownLink" }, "markup.underline.link.markdown"),
    _BatThemeScopeRenderer:new(
      { "@markup.link.label", "markdownLinkText" },
      "meta.link.inline.description.markdown"
    ),
    _BatThemeScopeRenderer:new(
      { "@markup.link", "markdownLinkTextDelimiter" },
      { "puncuation.definition.link.begin.markdown", "puncuation.definition.link.end.markdown" }
    ),
    _BatThemeScopeRenderer:new(
      { "markdownBlockquote" },
      { "puncuation.definition.blockquote.markdown" }
    ),
    _BatThemeScopeRenderer:new({ "@markup.strong", "markdownBold" }, "markup.bold"),
    _BatThemeScopeRenderer:new({ "@markup.italic", "markdownItalic" }, "markup.italic"),
    _BatThemeScopeRenderer:new({ "markdownHeadingDelimiter" }, {
      "puncuation.definition.heading.begin.markdown",
      "puncuation.definition.heading.end.markdown",
    }),
    _BatThemeScopeRenderer:new(
      { "@markup.heading.1.markdown", "markdownH1" },
      { "markup.heading.1.markdown" }
    ),
    _BatThemeScopeRenderer:new(
      { "@markup.heading.2.markdown", "markdownH2" },
      { "markup.heading.2.markdown" }
    ),
    _BatThemeScopeRenderer:new(
      { "@markup.heading.3.markdown", "markdownH3" },
      { "markup.heading.3.markdown" }
    ),
    _BatThemeScopeRenderer:new(
      { "@markup.heading.4.markdown", "markdownH4" },
      { "markup.heading.4.markdown" }
    ),
    _BatThemeScopeRenderer:new(
      { "@markup.heading.5.markdown", "markdownH5" },
      { "markup.heading.5.markdown" }
    ),
    _BatThemeScopeRenderer:new(
      { "@markup.heading.6.markdown", "markdownH6" },
      { "markup.heading.6.markdown" }
    ),
    -- _BatThemeScopeRenderer:new(
    --   { "@markup.list.markdown", "markdownListMarker" },
    --   { "puncuation.definition.list_item.markdown" }
    -- ),
    -- _BatThemeScopeRenderer:new({ "@markup.list.markdown" }, { "markup.list.unnumbered" }),
    -- _BatThemeScopeRenderer:new({ "@markup.list.markdown" }, { "markup.list.numbered" }),
    _BatThemeScopeRenderer:new({ "@markup.raw.block.markdown", "markdownCodeDelimiter" }, {
      "puncuation.definition.raw.code-fence.begin.markdown",
      "puncuation.definition.raw.code-fence.end.markdown",
    }),
    _BatThemeScopeRenderer:new({
      "GitSignsAdd",
      "GitGutterAdd",
      "DiffAdd",
      "DiffAdded",
      "@diff.plus",
      "Added",
    }, { "markup.inserted" }),
    _BatThemeScopeRenderer:new({
      "GitSignsChange",
      "GitGutterChange",
      "DiffChange",
      "@diff.delta",
      "Changed",
    }, { "markup.changed" }),
    _BatThemeScopeRenderer:new({
      "GitSignsDelete",
      "GitGutterDelete",
      "DiffDelete",
      "DiffRemoved",
      "@diff.minus",
      "Removed",
    }, { "markup.deleted" }),
    -- markup }
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
    <!-- names -->
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
      <!-- globals -->
      <dict>
        <key>settings</key>
        <dict>
{GLOBAL}
        </dict>
      </dict>

      <!-- scopes -->
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
    if type(result) == "table" then
      for _, l in ipairs(result) do
        table.insert(globals, l)
      end
    end
  end
  local scopes = {}
  for _, r in ipairs(self.scopes) do
    local result = r:render()
    if type(result) == "table" then
      for _, l in ipairs(result) do
        table.insert(scopes, l)
      end
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

  local theme_dir = bat_themes_helper.get_theme_dir() --[[@as string]]
  if str.empty(theme_dir) then
    return
  end

  log.ensure(
    path.isdir(theme_dir),
    string.format("|_build_theme| bat theme dir(%s) not exist", vim.inspect(theme_dir))
  )

  local theme_name = bat_themes_helper.get_theme_name(colorname)
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

  local theme_config_file = bat_themes_helper.get_theme_config_filename(colorname) --[[@as string]]
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
        on_stdout = function(line)
          -- log.debug(string.format("Build bat theme cache(stdout):[%s]", line))
        end,
        on_stderr = function(line)
          log.debug(string.format("Build bat theme cache(stderr):[%s]", line))
        end,
      }, function()
        vim.schedule(function()
          building_bat_theme = false
        end)
      end)
    end, 10)
  end)
end

M.setup = function()
  if not switches.bat_theme_autogen_enabled() then
    return
  end

  if not consts.HAS_BAT then
    return
  end

  bat_themes_helper.async_get_theme_dir(function()
    vim.schedule(function()
      local colorname = bat_themes_helper.get_color_name()
      if str.not_empty(colorname) then
        M._build_theme(colorname)
      end
    end)
  end)

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      vim.schedule(function()
        local colorname = bat_themes_helper.get_color_name()
        if str.not_empty(colorname) then
          M._build_theme(colorname)
        end
      end)
    end,
  })
end

return M
