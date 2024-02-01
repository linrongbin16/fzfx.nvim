local paths = require("fzfx.commons.paths")
local fileios = require("fzfx.commons.fileios")
local spawn = require("fzfx.commons.spawn")
local strings = require("fzfx.commons.strings")
local tables = require("fzfx.commons.tables")
local apis = require("fzfx.commons.apis")
local versions = require("fzfx.commons.versions")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")

local colorschemes_helper = require("fzfx.helper.colorschemes")
local bat_themes_helper = require("fzfx.helper.bat_themes")

local M = {}

-- renderer for tmTheme globals
--
--- @class fzfx._BatTmGlobalRenderer
--- @field key string
--- @field value string?
local _BatTmGlobalRenderer = {}

--- @param hl string|string[]
--- @param key string
--- @param attr "fg"|"bg"
--- @return fzfx._BatTmGlobalRenderer
function _BatTmGlobalRenderer:new(hl, key, attr)
  local hls = type(hl) == "table" and hl or {
    hl --[[@as string]],
  }

  local value = nil
  for i, h in ipairs(hls) do
    local ok, hl_codes = pcall(apis.get_hl, h)
    if ok and tables.tbl_not_empty(hl_codes) then
      if attr == "fg" and hl_codes.fg then
        value = string.format("#%06x", hl_codes.fg)
      elseif attr == "bg" and hl_codes.bg then
        value = string.format("#%06x", hl_codes.bg)
      end
      if value then
        break
      end
    end
  end

  local o = {
    key = key,
    value = value,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return string
function _BatTmGlobalRenderer:render()
  if not self.value then
    return "\n"
  end
  log.ensure(
    type(self.key) == "string" and string.len(self.key) > 0,
    "|_BatTmGlobalRenderer:render| invalid key:%s",
    vim.inspect(self)
  )
  log.ensure(
    type(self.value) == "string" and string.len(self.value) > 0,
    "|_BatTmGlobalRenderer:render| invalid value:%s",
    vim.inspect(self)
  )
  local builder = {
    string.format("          <key>%s</key>", self.key),
    string.format("          <string>%s</string>", self.value),
  }
  return table.concat(builder, "\n")
end

-- renderer for tmTheme scope
--
--- @alias fzfx._BatTmScopeValue {hl:string,scope:string[],foreground:string?,background:string?,font_style:string[],bold:boolean?,italic:boolean?,is_empty:boolean}
--
--- @class fzfx._BatTmScopeRenderer
--- @field value fzfx._BatTmScopeValue
local _BatTmScopeRenderer = {}

--- @param hl string|string[]
--- @param scope string|string[]
--- @return fzfx._BatTmScopeRenderer
function _BatTmScopeRenderer:new(hl, scope)
  local hls = type(hl) == "table" and hl or {
    hl --[[@as string]],
  }

  local value = nil
  for i, h in ipairs(hls) do
    local ok, hl_codes = pcall(apis.get_hl, h)
    if ok and tables.tbl_not_empty(hl_codes) then
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
      if hl_codes.fg then
        local v = {
          hl = h,
          scope = scope,
          foreground = hl_codes.fg and string.format("#%06x", hl_codes.fg)
            or nil,
          background = hl_codes.bg and string.format("#%06x", hl_codes.bg)
            or nil,
          font_style = font_style,
        }
        value = v
        break
      end
    end
  end

  local o = {
    value = value,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param value fzfx._BatTmScopeValue
--- @return string
local function _render_scope(value)
  if tables.tbl_empty(value) then
    return "\n"
  end
  local builder = {
    "      <dict>",
  }

  local scope_str = type(value.scope) == "table"
      and table.concat(value.scope --[[@as string[] ]], ", ")
    or value.scope
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
  if value.foreground then
    table.insert(builder, "          <key>foreground</key>")
    table.insert(
      builder,
      string.format("          <string>%s</string>", value.foreground)
    )
  end
  if value.background then
    table.insert(builder, "          <key>background</key>")
    table.insert(
      builder,
      string.format("          <string>%s</string>", value.background)
    )
  end
  if value.background then
    table.insert(builder, "          <key>background</key>")
    table.insert(
      builder,
      string.format("          <string>%s</string>", value.background)
    )
  end
  if #value.font_style > 0 then
    table.insert(builder, "          <key>fontStyle</key>")
    table.insert(
      builder,
      string.format(
        "          <string>%s</string>",
        table.concat(value.font_style, ", ")
      )
    )
  end
  table.insert(builder, "        </dict>")
  table.insert(builder, "      </dict>\n")
  return table.concat(builder, "\n")
end

--- @return string?
function _BatTmScopeRenderer:render()
  return self.value and _render_scope(self.value) or nil
end

-- lsp semantic tokens renderer for tmTheme scope
--
--- @class fzfx._BatTmLspScopeRenderer
--- @field value fzfx._BatTmScopeValue
local _BatTmLspScopeRenderer = {}

--- @param hl string|string[]
--- @param scope string|string[]
--- @return fzfx._BatTmLspScopeRenderer
function _BatTmLspScopeRenderer:new(hl, scope)
  local hls = type(hl) == "table" and hl or {
    hl --[[@as string]],
  }

  local value = nil
  for i, h in ipairs(hls) do
    local ok, hl_codes = pcall(apis.get_hl, h)
    if ok and tables.tbl_not_empty(hl_codes) then
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
      if hl_codes.fg then
        local v = {
          hl = h,
          scope = scope,
          foreground = hl_codes.fg and string.format("#%06x", hl_codes.fg)
            or nil,
          background = hl_codes.bg and string.format("#%06x", hl_codes.bg)
            or nil,
          font_style = font_style,
        }
        value = v
        break
      end
    end
  end

  local o = {
    value = value,
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return string?
function _BatTmLspScopeRenderer:render()
  return self.value and _render_scope(self.value) or nil
end

-- TextMate theme docs:
--  * Basic description: https://macromates.com/manual/en/language_grammars#naming_conventions
--  * Global: https://www.sublimetext.com/docs/color_schemes.html#global-settings
--  * Scope: https://www.sublimetext.com/docs/scope_naming.html#minimal-scope-coverage
--
-- Neovim highlight docs:
--  * Basic syntax: https://neovim.io/doc/user/syntax.html#group-name
--
-- syntax map
local GLOBAL_RENDERERS = {
  _BatTmGlobalRenderer:new("Normal", "background", "bg"),
  _BatTmGlobalRenderer:new("Normal", "foreground", "fg"),
  _BatTmGlobalRenderer:new("Cursor", "caret", "bg"),
  _BatTmGlobalRenderer:new("Cursor", "block_caret", "bg"),
  _BatTmGlobalRenderer:new("NonText", "invisibles", "fg"),
  _BatTmGlobalRenderer:new("Visual", "lineHighlight", "bg"),
  _BatTmGlobalRenderer:new("LineNr", "gutter", "bg"),
  _BatTmGlobalRenderer:new("LineNr", "gutterForeground", "fg"),
  _BatTmGlobalRenderer:new("CursorLineNr", "gutterForegroundHighlight", "fg"),
  _BatTmGlobalRenderer:new("Visual", "selection", "bg"),
  _BatTmGlobalRenderer:new("Visual", "selectionForeground", "fg"),
  _BatTmGlobalRenderer:new("Search", "findHighlight", "bg"),
  _BatTmGlobalRenderer:new("Search", "findHighlightForeground", "fg"),
  _BatTmGlobalRenderer:new({
    "GitSignsAdd",
    "GitGutterAdd",
    "DiffAdd",
    "DiffAdded",
    "@diff.plus",
    "Added",
  }, "lineDiffAdded", "fg"),
  _BatTmGlobalRenderer:new({
    "GitSignsChange",
    "GitGutterChange",
    "DiffChange",
    "@diff.delta",
    "Changed",
  }, "lineDiffModified", "fg"),
  _BatTmGlobalRenderer:new({
    "GitSignsDelete",
    "GitGutterDelete",
    "DiffDelete",
    "DiffRemoved",
    "@diff.minus",
    "Removed",
  }, "lineDiffDeleted", "fg"),
}

-- Neovim highlight docs:
--  * Basic syntax: https://neovim.io/doc/user/syntax.html#group-name
--  * Treesitter: https://neovim.io/doc/user/treesitter.html#treesitter-highlight
--
-- syntax and treesitter map
local SCOPE_RENDERERS = {
  -- comment {
  _BatTmScopeRenderer:new({ "@comment", "Comment" }, "comment"),
  _BatTmScopeRenderer:new(
    { "@comment.documentation" },
    "comment.block.documentation"
  ),
  -- comment }

  -- constant {
  _BatTmScopeRenderer:new({ "@number", "Number" }, "constant.numeric"),
  _BatTmScopeRenderer:new(
    { "@number.float", "Float" },
    "constant.numeric.float"
  ),
  _BatTmScopeRenderer:new({ "@boolean", "Boolean" }, "constant.language"),
  _BatTmScopeRenderer:new(
    { "@character", "Character" },
    { "constant.character" }
  ),
  _BatTmScopeRenderer:new(
    { "@string.escape" },
    { "constant.character.escaped", "constant.character.escape" }
  ),
  -- constant }

  -- entity {
  _BatTmScopeRenderer:new({
    "@function",
    "Function",
  }, "entity.name.function"),
  _BatTmScopeRenderer:new({
    "@function.call",
  }, "entity.name.function.call"),
  _BatTmScopeRenderer:new({
    "@constructor",
  }, "entity.name.function.constructor"),
  _BatTmScopeRenderer:new({
    "@type",
    "Type",
  }, {
    "entity.name.type",
  }),
  _BatTmScopeRenderer:new({
    "@tag",
  }, "entity.name.tag"),
  _BatTmScopeRenderer:new({
    "@tag.attribute",
  }, "entity.other.attribute-name"),
  _BatTmScopeRenderer:new({
    "@markup.heading",
  }, "entity.name.section"),
  _BatTmScopeRenderer:new({
    "Structure",
  }, {
    "entity.name.enum",
    "entity.name.union",
  }),
  _BatTmScopeRenderer:new({
    "@type",
    "Type",
  }, "entity.other.inherited-class"),
  _BatTmScopeRenderer:new({
    "@label",
    "Label",
  }, "entity.name.label"),
  _BatTmScopeRenderer:new({
    "@constant",
    "Constant",
  }, "entity.name.constant"),
  _BatTmScopeRenderer:new({
    "@module",
  }, "entity.name.namespace"),
  -- entity }

  -- invalid {
  _BatTmScopeRenderer:new({
    "Error",
  }, "invalid.illegal"),
  -- invalid }

  -- keyword {
  _BatTmScopeRenderer:new({ "@keyword", "Keyword" }, "keyword"),
  _BatTmScopeRenderer:new(
    { "@keyword.conditional", "Conditional" },
    "keyword.control"
  ),
  -- _BatTmScopeRenderer:new(
  --   { "@keyword.conditional", "Conditional" },
  --   "keyword.control.conditional"
  -- ),
  _BatTmScopeRenderer:new({ "@keyword.import" }, "keyword.control.import"),
  _BatTmScopeRenderer:new({ "@operator", "Operator" }, "keyword.operator"),
  _BatTmScopeRenderer:new({ "@keyword.operator" }, "keyword.operator.word"),
  _BatTmScopeRenderer:new(
    { "@keyword.conditional.ternary" },
    "keyword.operator.ternary"
  ),
  -- keyword }

  -- markup {
  _BatTmScopeRenderer:new({
    "@markup.link.url",
  }, "markup.underline.link"),
  _BatTmScopeRenderer:new({
    "@markup.underline",
  }, "markup.underline"),
  _BatTmScopeRenderer:new({
    "@markup.strong",
  }, "markup.bold"),
  _BatTmScopeRenderer:new({
    "@markup.italic",
  }, "markup.italic"),
  _BatTmScopeRenderer:new({
    "@markup.heading",
  }, "markup.heading"),
  _BatTmScopeRenderer:new({
    "@markup.list",
  }, "markup.list"),
  _BatTmScopeRenderer:new({
    "@markup.raw",
  }, "markup.raw"),
  _BatTmScopeRenderer:new({
    "@markup.quote",
  }, "markup.quote"),
  _BatTmScopeRenderer:new({
    "GitSignsAdd",
    "GitGutterAdd",
    "DiffAdd",
    "DiffAdded",
    "@diff.plus",
    "Added",
  }, { "markup.inserted" }),
  _BatTmScopeRenderer:new({
    "GitSignsDelete",
    "GitGutterDelete",
    "DiffDelete",
    "DiffRemoved",
    "@diff.minus",
    "Removed",
  }, { "markup.deleted" }),
  _BatTmScopeRenderer:new({
    "GitGutterChange",
    "GitSignsChange",
    "DiffChange",
    "@diff.delta",
    "Changed",
  }, { "markup.changed" }),
  -- markup }

  -- meta {
  _BatTmScopeRenderer:new({
    "@attribute",
  }, { "meta.annotation" }),
  _BatTmScopeRenderer:new({
    "@constant.macro",
  }, { "meta.preprocessor" }),
  -- meta }

  -- storage {
  _BatTmScopeRenderer:new({
    "@keyword.function",
    "Keyword",
  }, { "storage.type.function", "keyword.declaration.function" }),
  _BatTmScopeRenderer:new({
    "Structure",
  }, {
    "storage.type.enum",
    "keyword.declaration.enum",
  }),
  _BatTmScopeRenderer:new({
    "Structure",
  }, {
    "storage.type.struct",
    "keyword.declaration.struct",
  }),
  _BatTmScopeRenderer:new({
    "@type",
    "Type",
  }, { "storage.type", "keyword.declaration.type" }),
  _BatTmScopeRenderer:new(
    { "@keyword.storage", "StorageClass" },
    "storage.modifier"
  ),
  -- storage }

  -- string {
  _BatTmScopeRenderer:new(
    { "@string", "String" },
    { "string", "string.quoted" }
  ),
  _BatTmScopeRenderer:new({
    "@string.regexp",
  }, { "string.regexp" }),
  -- string }

  -- support {
  _BatTmScopeRenderer:new({
    "@function.builtin",
    "Function",
  }, "support.function"),
  _BatTmScopeRenderer:new({
    "@constant.builtin",
    "Constant",
  }, "support.constant"),
  _BatTmScopeRenderer:new({
    "@type.builtin",
    "Type",
  }, "support.type"),
  _BatTmScopeRenderer:new({
    "@type.builtin",
    "Type",
  }, "support.class"),
  _BatTmScopeRenderer:new({
    "@module.builtin",
  }, "support.module"),
  -- support }

  -- variable {
  _BatTmScopeRenderer:new({
    "@function",
    "Function",
  }, "variable.function"),
  _BatTmScopeRenderer:new({
    "@variable.parameter",
    "Identifier",
  }, { "variable.parameter" }),
  _BatTmScopeRenderer:new({
    "@variable.builtin",
  }, { "variable.language" }),
  _BatTmScopeRenderer:new({
    "@constant",
  }, { "variable.other.constant" }),
  _BatTmScopeRenderer:new({
    "@variable",
    "Identifier",
  }, "variable"),
  _BatTmScopeRenderer:new({
    "@variable",
    "Identifier",
  }, "variable.other"),
  _BatTmScopeRenderer:new({
    "@variable.member",
  }, "variable.other.member"),
  -- variable }

  -- punctuation {
  _BatTmScopeRenderer:new({
    "@punctuation.bracket",
  }, {
    "punctuation.section.braces.begin",
    "punctuation.section.braces.end",
    "punctuation.section.brackets.begin",
    "punctuation.section.brackets.end",
    "punctuation.section.parens.begin",
    "punctuation.section.parens.end",
  }),
  _BatTmScopeRenderer:new({
    "@punctuation.special",
  }, {
    "punctuation.section.interpolation.begin",
    "punctuation.section.interpolation.end",
  }),
  _BatTmScopeRenderer:new({
    "@punctuation.delimiter",
  }, {
    "punctuation.separator",
    "punctuation.terminator",
  }),
  _BatTmScopeRenderer:new({
    "@tag.delimiter",
  }, {
    "punctuation.definition.generic.begin",
    "punctuation.definition.generic.end",
  }),
  -- punctuation }
}

-- Neovim Lsp Semantic Highlight docs:
--  * Neovim semantic highlight: https://neovim.io/doc/user/lsp.html#lsp-semantic-highlight
--  * Lsp semantic tokens: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_semanticTokens
--  * Lsp nvim-lspconfig: https://github.com/neovim/neovim/blob/9f15a18fa57f540cb3d0d9d2f45d872038e6f990/src/nvim/highlight_group.c#L288
--  * Detailed explanation: https://gist.github.com/swarn/fb37d9eefe1bc616c2a7e476c0bc0316
--
-- `@lsp.type` is mapping to `SemanticTokenTypes` in specification.
-- `@lsp.mod` is mapping to `SemanticTokenModifiers` in specification.
--
-- lsp semnatic tokens map
local LSP_SCOPE_RENDERERS = {
  -- comment {
  _BatTmScopeRenderer:new({ "@lsp.type.comment" }, "comment"),
  -- comment }

  -- constant {
  -- constant }

  -- entity {
  _BatTmScopeRenderer:new({
    "@lsp.type.function",
  }, "entity.name.function"),
  _BatTmScopeRenderer:new({
    "@lsp.type.type",
  }, {
    "entity.name.type",
  }),
  _BatTmScopeRenderer:new({
    "@tag",
  }, "entity.name.tag"),
  _BatTmScopeRenderer:new({
    "@markup.heading",
    "htmlTitle",
  }, "entity.name.section"),
  _BatTmScopeRenderer:new({
    "@lsp.type.enum",
    "Structure",
  }, {
    "entity.name.enum",
    "entity.name.union",
  }),
  _BatTmScopeRenderer:new({
    "@type",
    "Type",
  }, "entity.other.inherited-class"),
  _BatTmScopeRenderer:new({
    "@label",
    "Label",
  }, "entity.name.label"),
  _BatTmScopeRenderer:new({
    -- "@lsp.type.enumMember",
    "@constant",
    "Constant",
  }, "entity.name.constant"),
  _BatTmScopeRenderer:new({
    "@lsp.type.namespace",
    "@module",
  }, "entity.name.namespace"),
  _BatTmScopeRenderer:new({
    "@lsp.type.class",
  }, { "entity.name.class" }),
  _BatTmScopeRenderer:new({
    "@lsp.type.struct",
  }, { "entity.name.struct" }),
  _BatTmScopeRenderer:new({
    "@lsp.type.interface",
  }, { "entity.name.interface" }),
  -- entity }

  -- invalid {
  _BatTmScopeRenderer:new({
    "Error",
  }, "invalid.illegal"),
  -- invalid }

  -- keyword {
  _BatTmScopeRenderer:new({ "@keyword", "Keyword" }, "keyword"),
  -- _BatTmScopeRenderer:new({ "@keyword", "Keyword" }, "keyword.local"),
  _BatTmScopeRenderer:new(
    { "@keyword.conditional", "Conditional" },
    "keyword.control.conditional"
  ),
  _BatTmScopeRenderer:new({ "@keyword.operator" }, "keyword.operator.word"),
  _BatTmScopeRenderer:new({ "@operator", "Operator" }, "keyword.operator"),
  _BatTmScopeRenderer:new({ "@keyword.import" }, "keyword.control.import"),
  -- keyword }

  -- markup {
  _BatTmScopeRenderer:new({
    "@markup.link.url",
  }, "markup.underline.link"),
  _BatTmScopeRenderer:new({
    "@markup.underline",
  }, "markup.underline"),
  _BatTmScopeRenderer:new({
    "@markup.strong",
  }, "markup.bold"),
  _BatTmScopeRenderer:new({
    "@markup.italic",
  }, "markup.italic"),
  _BatTmScopeRenderer:new({
    "@markup.heading",
  }, "markup.heading"),
  _BatTmScopeRenderer:new({
    "@markup.list",
  }, "markup.list"),
  _BatTmScopeRenderer:new({
    "@markup.raw",
  }, "markup.raw"),
  _BatTmScopeRenderer:new({
    "@markup.quote",
  }, "markup.quote"),
  _BatTmScopeRenderer:new({
    "GitSignsAdd",
    "GitGutterAdd",
    "DiffAdd",
    "DiffAdded",
    "@diff.plus",
    "Added",
  }, "markup.inserted"),
  _BatTmScopeRenderer:new({
    "GitSignsDelete",
    "GitGutterDelete",
    "DiffDelete",
    "DiffRemoved",
    "@diff.minus",
    "Removed",
  }, "markup.deleted"),
  _BatTmScopeRenderer:new({
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
  _BatTmScopeRenderer:new({
    "@lsp.type.decorator",
    "@attribute",
  }, { "meta.annotation" }),
  _BatTmScopeRenderer:new({
    "@lsp.type.macro",
    "@constant.macro",
  }, { "meta.preprocessor" }),
  -- meta }

  -- storage {
  _BatTmScopeRenderer:new({
    "@keyword.function",
  }, { "storage.type.function", "keyword.declaration.function" }),
  _BatTmScopeRenderer:new({
    "@lsp.type.enum",
    "Structure",
  }, {
    "storage.type.enum",
    "keyword.declaration.enum",
  }),
  _BatTmScopeRenderer:new({
    "@lsp.type.struct",
    "Structure",
  }, {
    "storage.type.struct",
    "keyword.declaration.struct",
  }),
  _BatTmScopeRenderer:new({
    "@type.builtin",
    "@type",
    "Type",
  }, { "storage.type", "keyword.declaration.type" }),
  _BatTmScopeRenderer:new({ "StorageClass" }, "storage.modifier"),
  -- storage }

  -- string {
  _BatTmScopeRenderer:new(
    { "@string", "String" },
    { "string", "string.quoted" }
  ),
  _BatTmScopeRenderer:new({
    "@string.regexp",
  }, { "string.regexp" }),
  -- string }

  -- support {
  _BatTmScopeRenderer:new({
    "@lsp.type.function",
    "@function",
    "Function",
  }, "support.function"),
  _BatTmScopeRenderer:new({
    -- "@lsp.type.enumMember",
    "@constant",
    "Constant",
  }, "support.constant"),
  _BatTmScopeRenderer:new({
    "@type",
    "Type",
  }, "support.type"),
  _BatTmScopeRenderer:new({
    "@type",
    "Type",
  }, "support.class"),
  _BatTmScopeRenderer:new({
    "@lsp.type.namespace",
    "@module",
  }, "support.module"),
  -- support }

  -- variable {
  _BatTmScopeRenderer:new({
    "@lsp.type.method",
    "@function.method",
  }, "variable.function"),
  _BatTmScopeRenderer:new({
    "@lsp.type.parameter",
    "@variable.parameter",
  }, { "variable.parameter" }),
  _BatTmScopeRenderer:new({
    "@variable.builtin",
  }, { "variable.language" }),
  _BatTmScopeRenderer:new({
    -- "@lsp.type.enumMember",
    "@constant",
  }, { "variable.other.constant" }),
  _BatTmScopeRenderer:new({
    "@lsp.type.variable",
    "@variable",
    "Identifier",
  }, "variable"),
  _BatTmScopeRenderer:new({
    "@lsp.type.variable",
    "@variable",
    "Identifier",
  }, "variable.other"),
  _BatTmScopeRenderer:new({
    "@variable.member",
  }, "variable.other.member"),
  -- variable }

  -- punctuation {
  _BatTmScopeRenderer:new({
    "@punctuation.bracket",
  }, {
    "punctuation.section.brackets.begin",
    "punctuation.section.brackets.end",
    "punctuation.section.braces.begin",
    "punctuation.section.braces.end",
    "punctuation.section.parens.begin",
    "punctuation.section.parens.end",
  }),
  _BatTmScopeRenderer:new({
    "@punctuation.special",
  }, {
    "punctuation.section.interpolation.begin",
    "punctuation.section.interpolation.end",
  }),
  _BatTmScopeRenderer:new({
    "@punctuation.delimiter",
  }, {
    "punctuation.separator",
    "punctuation.terminator",
  }),
  _BatTmScopeRenderer:new({
    "@tag.delimiter",
  }, {
    "punctuation.definition.generic.begin",
    "punctuation.definition.generic.end",
  }),
  -- punctuation }
}

-- tmTheme renderer
--
--- @class fzfx._BatTmRenderer
local _BatTmRenderer = {}

function _BatTmRenderer:new() end

function _BatTmRenderer:render() end

--- @param colorname string
--- @param skip_lsp_semantic boolean?
--- @return {name:string,payload:string}?
M._render_theme = function(colorname, skip_lsp_semantic)
  if strings.empty(colorname) then
    return nil
  end
  local theme_name = bat_themes_helper.get_theme_name(colorname) --[[@as string]]
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
    table.insert(scope_builder, renderer:render(skip_lsp_semantic))
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
--- @param opts {skip_lsp_semantic:boolean?}?
M._build_theme = function(colorname, opts)
  opts = opts or { skip_lsp_semantic = false }
  opts.skip_lsp_semantic = type(opts.skip_lsp_semantic) == "boolean"
      and opts.skip_lsp_semantic
    or false

  local theme_template = bat_themes_helper.get_theme_config_file(colorname) --[[@as string]]
  log.debug(
    "|build_custom_theme| colorname:%s, theme_template:%s",
    vim.inspect(colorname),
    vim.inspect(theme_template)
  )
  if strings.empty(theme_template) then
    return
  end
  local theme_dir = bat_themes_helper.get_theme_dir() --[[@as string]]
  log.debug("|build_custom_theme| theme_dir:%s", vim.inspect(theme_dir))
  if strings.empty(theme_dir) then
    return
  end
  local theme = M._render_theme(colorname, opts.skip_lsp_semantic) --[[@as string]]
  -- log.debug("|build_custom_theme| theme:%s", vim.inspect(theme))
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
      -- log.debug("|setup| bat build cache on_stderr:%s", vim.inspect(line))
    end,
    on_stderr = function(line)
      -- log.debug("|setup| bat build cache on_stderr:%s", vim.inspect(line))
    end,
  }, function()
    vim.schedule(function()
      building_bat_theme = false
    end)
  end)
end

M.setup = function()
  if not constants.HAS_BAT then
    return
  end

  local color = vim.g.colors_name
  if strings.not_empty(color) then
    M._build_theme(color, { skip_lsp_semantic = true })
  end

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      vim.schedule(function()
        log.debug("|setup| ColorScheme event:%s", vim.inspect(event))
        if strings.not_empty(tables.tbl_get(event, "match")) then
          M._build_theme(event.match, { skip_lsp_semantic = true })
        end
      end)
    end,
  })

  if versions.ge("0.9") and vim.fn.exists("##LspTokenUpdate") then
    vim.api.nvim_create_autocmd({ "LspTokenUpdate" }, {
      callback = function()
        vim.schedule(function()
          local bufcolor = colorschemes_helper.get_color_name() --[[@as string]]
          if strings.not_empty(bufcolor) then
            M._build_theme(bufcolor)
          end
        end)
      end,
    })
  end
end

return M
