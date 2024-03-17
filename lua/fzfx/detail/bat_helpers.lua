local str = require("fzfx.commons.str")
local tbl = require("fzfx.commons.tbl")
local api = require("fzfx.commons.api")
local path = require("fzfx.commons.path")
local fileio = require("fzfx.commons.fileio")
local spawn = require("fzfx.commons.spawn")
local version = require("fzfx.commons.version")

local constants = require("fzfx.lib.constants")
local log = require("fzfx.lib.log")

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
    local ok, hl_codes = pcall(api.get_hl, h)
    if ok and tbl.tbl_not_empty(hl_codes) then
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

--- @return string?
function _BatTmGlobalRenderer:render()
  if not self.value then
    return nil
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
--- @field value fzfx._BatTmScopeValue?
--- @field lsp_value fzfx._BatTmScopeValue?
local _BatTmScopeRenderer = {}

--- @param hl string
--- @param scope string|string[]
--- @param hl_codes table
--- @return fzfx._BatTmScopeValue?
M._make_scope_value = function(hl, scope, hl_codes)
  if tbl.tbl_empty(hl_codes) then
    return nil
  end
  log.ensure(type(hl) == "string" and string.len(hl) > 0, "|_make_scope_value| invalid hl name")
  log.ensure(
    (type(scope) == "string" and string.len(scope) > 0) or (tbl.tbl_not_empty(scope)),
    "|_make_scope_value| invalid tm scope:%s",
    vim.inspect(scope)
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

  if type(hl_codes.fg) == "number" then
    local value = {
      hl = hl,
      scope = scope,
      foreground = hl_codes.fg and string.format("#%06x", hl_codes.fg) or nil,
      background = hl_codes.bg and string.format("#%06x", hl_codes.bg) or nil,
      font_style = font_style,
    }
    return value
  end

  return nil
end

--- @param hl string|string[]
--- @param scope string|string[]
--- @return fzfx._BatTmScopeRenderer
function _BatTmScopeRenderer:new(hl, scope)
  local hls = type(hl) == "table" and hl or {
    hl --[[@as string]],
  }

  local value = nil
  local lsp_value = nil
  for i, h in ipairs(hls) do
    local ok, hl_codes = pcall(api.get_hl, h)
    if ok and tbl.tbl_not_empty(hl_codes) then
      local item = M._make_scope_value(h, scope, hl_codes)
      if item then
        if str.startswith(h, "@lsp") then
          lsp_value = item
        else
          value = item
        end
        break
      end
    end
  end

  local o = {
    scope = scope,
    value = value,
    lsp_value = lsp_value,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param value fzfx._BatTmScopeValue
--- @return string?
M._render_scope = function(value)
  if tbl.tbl_empty(value) then
    return nil
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
    table.insert(builder, string.format("          <string>%s</string>", value.foreground))
  end
  if value.background then
    table.insert(builder, "          <key>background</key>")
    table.insert(builder, string.format("          <string>%s</string>", value.background))
  end
  if value.background then
    table.insert(builder, "          <key>background</key>")
    table.insert(builder, string.format("          <string>%s</string>", value.background))
  end
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
function _BatTmScopeRenderer:render()
  if self.lsp_value then
    return M._render_scope(self.lsp_value)
  end
  if self.value then
    return M._render_scope(self.value)
  end
  return nil
end

--- @return string?
function _BatTmScopeRenderer:lsp_hl_name()
  return tbl.tbl_get(self.lsp_value, "hl")
end

--- @return boolean
function _BatTmScopeRenderer:update_lsp_hl()
  if str.empty(tbl.tbl_get(self.lsp_value, "hl")) then
    -- log.debug(
    --   "|_BatTmScopeRenderer:update_lsp_hl| invalid self.lsp_value.hl:%s",
    --   vim.inspect(self.lsp_value)
    -- )
    return false
  end
  log.ensure(
    str.startswith(self.lsp_value.hl, "@lsp"),
    "|_BatTmScopeRenderer:update_lsp_highlight| invalid lsp highlight:%s",
    vim.inspect(self.lsp_value)
  )

  local ok, hl_codes = pcall(api.get_hl, self.lsp_value.hl)
  if not ok or tbl.tbl_empty(hl_codes) then
    -- log.debug(
    --   "|_BatTmScopeRenderer:update_lsp_hl| invalid hl_codes, hl:%s, error:%s",
    --   vim.inspect(self.lsp_value.hl),
    --   vim.inspect(hl_codes)
    -- )
    return false
  end

  local new_value = M._make_scope_value(self.lsp_value.hl, self.lsp_value.scope, hl_codes)
  if tbl.tbl_empty(new_value) then
    -- log.debug(
    --   "|_BatTmScopeRenderer:update_lsp_hl| empty new value, hl:%s, hl_codes:%s",
    --   vim.inspect(self.lsp_value.hl),
    --   vim.inspect(hl_codes)
    -- )
    return false
  end

  if vim.deep_equal(self.lsp_value, new_value) then
    -- log.debug(
    --   "|_BatTmScopeRenderer:update_lsp_hl| new value is still same, self.lsp_value:%s, new_value:%s",
    --   vim.inspect(self.lsp_value),
    --   vim.inspect(new_value)
    -- )
    return false
  end

  self.lsp_value = new_value
  -- log.debug(
  --   "|_BatTmScopeRenderer:update_lsp_hl| updated lsp hl:%s",
  --   vim.inspect(self.lsp_value)
  -- )

  return true
end

--- @return {globals:fzfx._BatTmGlobalRenderer[],scopes:fzfx._BatTmScopeRenderer[]}
M._make_render_map = function()
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
    _BatTmGlobalRenderer:new({ "Visual" }, "lineHighlight", "bg"),
    _BatTmGlobalRenderer:new({
      "GitSignsAdd",
      "GitGutterAdd",
      "DiffAdd",
      "DiffAdded",
      "Added",
    }, "lineDiffAdded", "fg"),
    _BatTmGlobalRenderer:new({
      "GitSignsChange",
      "GitGutterChange",
      "DiffChange",
      "Changed",
    }, "lineDiffModified", "fg"),
    _BatTmGlobalRenderer:new({
      "GitSignsDelete",
      "GitGutterDelete",
      "DiffDelete",
      "DiffRemoved",
      "Removed",
    }, "lineDiffDeleted", "fg"),
  }

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
  --
  -- syntax and treesitter map
  local SCOPE_RENDERERS = {
    -- comment {
    _BatTmScopeRenderer:new("Comment", "comment"),
    -- comment }

    -- constant {
    _BatTmScopeRenderer:new("Number", "constant.numeric"),
    _BatTmScopeRenderer:new("Float", "constant.numeric.float"),
    _BatTmScopeRenderer:new("Boolean", "constant.language"),
    _BatTmScopeRenderer:new("Character", { "constant.character" }),
    -- constant }

    -- entity {
    _BatTmScopeRenderer:new("Function", "entity.name.function"),
    _BatTmScopeRenderer:new("Type", { "entity.name.type" }),
    _BatTmScopeRenderer:new({ "Structure" }, { "entity.name.union" }),
    _BatTmScopeRenderer:new({ "Structure" }, { "entity.name.enum" }),
    _BatTmScopeRenderer:new({ "Label" }, "entity.name.label"),
    _BatTmScopeRenderer:new({ "Constant" }, "entity.name.constant"),
    _BatTmScopeRenderer:new({ "Type" }, "entity.other.inherited-class"),
    -- entity }

    -- keyword {
    _BatTmScopeRenderer:new({ "Keyword" }, "keyword"),
    _BatTmScopeRenderer:new({ "Conditional" }, "keyword.control"),
    _BatTmScopeRenderer:new({ "Operator" }, "keyword.operator"),
    -- keyword }

    -- markup {
    _BatTmScopeRenderer:new({
      "GitSignsAdd",
      "GitGutterAdd",
      "DiffAdd",
      "DiffAdded",
      "Added",
    }, { "markup.inserted" }),
    _BatTmScopeRenderer:new({
      "GitSignsDelete",
      "GitGutterDelete",
      "DiffDelete",
      "DiffRemoved",
      "Removed",
    }, { "markup.deleted" }),
    _BatTmScopeRenderer:new({
      "GitGutterChange",
      "GitSignsChange",
      "DiffChange",
      "Changed",
    }, { "markup.changed" }),
    -- markup }

    -- meta {
    _BatTmScopeRenderer:new({ "Macro" }, { "meta.preprocessor" }),
    -- meta }

    -- storage {
    _BatTmScopeRenderer:new(
      { "Keyword" },
      { "storage.type.function", "keyword.declaration.function" }
    ),
    _BatTmScopeRenderer:new({ "Structure" }, {
      "storage.type.enum",
      "keyword.declaration.enum",
    }),
    _BatTmScopeRenderer:new({ "Structure" }, {
      "storage.type.struct",
      "keyword.declaration.struct",
    }),
    _BatTmScopeRenderer:new({ "Type" }, { "storage.type", "keyword.declaration.type" }),
    _BatTmScopeRenderer:new({ "StorageClass" }, "storage.modifier"),
    -- storage }

    -- string {
    _BatTmScopeRenderer:new({ "String" }, { "string", "string.quoted" }),
    -- string }

    -- support {
    _BatTmScopeRenderer:new({ "Function" }, "support.function"),
    _BatTmScopeRenderer:new({ "Constant" }, "support.constant"),
    _BatTmScopeRenderer:new({ "Type" }, "support.type"),
    _BatTmScopeRenderer:new({ "Type" }, "support.class"),
    -- support }

    -- variable {
    _BatTmScopeRenderer:new({ "Function" }, "variable.function"),
    _BatTmScopeRenderer:new({ "Identifier" }, "variable"),
    -- variable }
  }

  return {
    globals = GLOBAL_RENDERERS,
    scopes = SCOPE_RENDERERS,
  }
end

-- tmTheme renderer
--
--- @class fzfx._BatTmRenderer
--- @field template string
--- @field globals fzfx._BatTmGlobalRenderer[]
--- @field scopes fzfx._BatTmScopeRenderer[]
local _BatTmRenderer = {}

--- @return fzfx._BatTmRenderer
function _BatTmRenderer:new()
  -- there're 3 components in below template:
  -- {NAME}
  -- {GLOBAL}
  -- {SCOPE}
  --
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
        <!-- globals -->
        <key>settings</key>
        <dict>
          {GLOBAL}
        </dict>
      </dict>

      <!-- scope -->
      {SCOPE}

    </array>
    <key>uuid</key>
    <string>uuid</string>
  </dict>
</plist>
  ]]

  local render_map = M._make_render_map()

  local o = {
    template = template,
    globals = render_map.globals,
    scopes = render_map.scopes,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param theme_name string
--- @return {name:string,payload:string}
function _BatTmRenderer:render(theme_name)
  local payload = self.template

  payload = str.replace(payload, "{NAME}", theme_name)

  local globals = {}
  for i, r in ipairs(self.globals) do
    local result = r:render()
    if result then
      table.insert(globals, result)
    end
  end
  local scopes = {}
  for i, r in ipairs(self.scopes) do
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

--- @param lsp_type string
--- @param lsp_modifiers table<string, any>?
--- @return boolean
function _BatTmRenderer:patch_lsp_hl(lsp_type, lsp_modifiers)
  local updated = false
  local updated_count = 0

  for i, r in ipairs(self.scopes) do
    if r:lsp_hl_name() == lsp_type then
      local has_updates = r:update_lsp_hl()
      if has_updates then
        updated = true
        updated_count = updated_count + 1
      end
    end
  end

  -- log.debug(
  --   "|_BatTmRenderer:patch_lsp_token| updated lsp hl:%s, has updated:%s",
  --   vim.inspect(updated_count),
  --   vim.inspect(updated)
  -- )
  return updated
end

M._BatTmRenderer = _BatTmRenderer

M._BatTmRendererInstance = nil

local building_bat_theme = false

--- @param colorname string
M._build_theme = function(colorname)
  log.ensure(str.not_empty(colorname), "|_build_theme| colorname is empty string!")

  local theme_dir = bat_themes_helper.get_theme_dir()
  log.ensure(str.not_empty(theme_dir), "|_build_theme| failed to get bat config dir")

  -- log.debug("|_build_theme| theme_dir:%s", vim.inspect(theme_dir))
  if not path.isdir(theme_dir) then
    spawn
      .run({ "mkdir", "-p", theme_dir }, {
        on_stdout = function() end,
        on_stderr = function() end,
      })
      :wait()
  end

  local theme_name = bat_themes_helper.get_theme_name(colorname)
  log.ensure(
    str.not_empty(theme_name),
    "|_build_theme| failed to get theme_name from nvim colorscheme name:%s",
    vim.inspect(colorname)
  )

  M._BatTmRendererInstance = _BatTmRenderer:new()
  local rendered_result = M._BatTmRendererInstance:render(theme_name)
  log.ensure(
    tbl.tbl_not_empty(rendered_result),
    "|_build_theme| rendered result is empty, color name:%s, theme name:%s",
    vim.inspect(colorname),
    vim.inspect(theme_name)
  )

  local theme_config_file = bat_themes_helper.get_theme_config_file(colorname)
  -- log.debug("|_build_theme| theme_config_file:%s", vim.inspect(theme_config_file))
  log.ensure(
    str.not_empty(theme_config_file),
    "|_build_theme| failed to get bat theme config file from nvim colorscheme name:%s",
    vim.inspect(colorname)
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
      spawn.run({ constants.BAT, "cache", "--build" }, {
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

--- @param colorname string
--- @param lsp_type string
--- @param lsp_modifiers table<string, any>?
M._patch_theme = function(colorname, lsp_type, lsp_modifiers)
  if not M._BatTmRendererInstance then
    return
  end
  -- log.debug(
  --   "|_patch_theme| colorname:%s, lsp_token:%s",
  --   vim.inspect(colorname),
  --   vim.inspect(lsp_token)
  -- )

  log.ensure(str.not_empty(colorname), "|_patch_theme| colorname is empty string!")
  log.ensure(
    str.not_empty(lsp_type) and str.startswith(lsp_type, "@lsp"),
    "|_patch_theme| invalid lsp token:%s",
    vim.inspect(lsp_type)
  )

  local theme_dir = bat_themes_helper.get_theme_dir()
  log.ensure(str.not_empty(theme_dir), "|_patch_theme| failed to get bat config dir")

  local theme_name = bat_themes_helper.get_theme_name(colorname)
  log.ensure(
    str.not_empty(theme_name),
    "|_patch_theme| failed to get theme_name from nvim colorscheme name:%s",
    vim.inspect(colorname)
  )

  local updated = M._BatTmRendererInstance:patch_lsp_hl(lsp_type, lsp_modifiers)
  if not updated then
    return
  end

  local theme_config_file = bat_themes_helper.get_theme_config_file(colorname)
  -- log.debug("|_patch_theme| theme_config_file:%s", vim.inspect(theme_config_file))
  log.ensure(
    str.not_empty(theme_config_file),
    "|_patch_theme| failed to get bat theme config file from nvim colorscheme name:%s",
    vim.inspect(colorname)
  )

  if building_bat_theme then
    return
  end
  building_bat_theme = true

  local rendered_result = M._BatTmRendererInstance:render(theme_name)
  fileio.asyncwritefile(theme_config_file, rendered_result.payload, function()
    vim.defer_fn(function()
      -- log.debug(
      --   "|_patch_theme| dump theme payload, theme_template:%s",
      --   vim.inspect(theme_config_file)
      -- )
      spawn.run({ constants.BAT, "cache", "--build" }, {
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
  if not constants.HAS_BAT then
    return
  end

  if str.not_empty(vim.g.colors_name) then
    M._build_theme(vim.g.colors_name)
  end

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = function(event)
      -- log.debug("|setup| ColorScheme event:%s", vim.inspect(event))
      vim.schedule(function()
        if str.not_empty(vim.g.colors_name) then
          M._build_theme(vim.g.colors_name)
        end
      end)
    end,
  })

  -- if version.ge("0.9") and vim.fn.exists("##LspTokenUpdate") then
  --   vim.api.nvim_create_autocmd("LspTokenUpdate", {
  --     callback = function(event)
  --       -- log.debug("|setup| LspTokenUpdate:%s", vim.inspect(event))
  --       vim.schedule(function()
  --         if str.not_empty(tbl.tbl_get(event, "data", "token", "type")) then
  --           local lsp_type = string.format("@lsp.type.%s", event.data.token.type)
  --           local lsp_modifiers = tbl.tbl_get(event, "data", "token", "modifiers") or {}
  --           if str.not_empty(vim.g.colors_name) then
  --             M._patch_theme(vim.g.colors_name, lsp_type, lsp_modifiers)
  --           end
  --         end
  --       end)
  --     end,
  --   })
  -- end
end

return M
