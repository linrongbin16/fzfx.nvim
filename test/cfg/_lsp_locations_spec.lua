---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("cfg._lsp_locations", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local tbls = require("fzfx.lib.tables")
  local consts = require("fzfx.lib.constants")
  local strs = require("fzfx.lib.strings")
  local paths = require("fzfx.lib.paths")
  local colors = require("fzfx.lib.colors")

  local contexts = require("fzfx.helper.contexts")
  local providers = require("fzfx.helper.providers")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")

  local _lsp_locations = require("fzfx.cfg._lsp_locations")

  describe("_lsp_locations", function()
    local RANGE = {
      start = { line = 1, character = 10 },
      ["end"] = { line = 10, character = 31 },
    }
    local LOCATION = {
      uri = "file:///usr/home/github/linrongbin16/fzfx.nvim",
      range = RANGE,
    }
    local LOCATIONLINK = {
      targetUri = "file:///usr/home/github/linrongbin16/fzfx.nvim",
      targetRange = RANGE,
    }
    it("_is_lsp_range", function()
      assert_false(_lsp_locations._is_lsp_range(nil))
      assert_false(_lsp_locations._is_lsp_range({}))
      assert_true(_lsp_locations._is_lsp_range(RANGE))
    end)
    it("_is_lsp_location", function()
      assert_false(_lsp_locations._is_lsp_location("asdf"))
      assert_false(_lsp_locations._is_lsp_location({}))
      assert_true(_lsp_locations._is_lsp_location(LOCATION))
    end)
    it("_is_lsp_locationlink", function()
      assert_false(_lsp_locations._is_lsp_locationlink("hello"))
      assert_false(_lsp_locations._is_lsp_locationlink({}))
      assert_true(_lsp_locations._is_lsp_locationlink(LOCATIONLINK))
    end)
    it("_lsp_location_render_line", function()
      local r = {
        start = { line = 1, character = 20 },
        ["end"] = { line = 1, character = 26 },
      }
      local loc = _lsp_locations._lsp_location_render_line(
        'describe("_lsp_location_render_line", function()',
        r,
        colors.red
      )
      -- print(string.format("lsp render line:%s\n", vim.inspect(loc)))
      assert_eq(type(loc), "string")
      assert_true(strs.startswith(loc, "describe"))
      assert_true(strs.endswith(loc, "function()"))
    end)
    it("renders location", function()
      local actual = _lsp_locations._render_lsp_location_line(LOCATION)
      -- print(
      --     string.format("render lsp location:%s\n", vim.inspect(actual))
      -- )
      assert_true(actual == nil or type(actual) == "string")
    end)
    it("renders locationlink", function()
      local actual = _lsp_locations._render_lsp_location_line(LOCATIONLINK)
      -- print(
      --     string.format(
      --         "render lsp locationlink:%s\n",
      --         vim.inspect(actual)
      --     )
      -- )
      assert_true(actual == nil or type(actual) == "string")
    end)
    it("_lsp_position_context_maker", function()
      local ctx = _lsp_locations._lsp_position_context_maker()
      -- print(string.format("lsp position context:%s\n", vim.inspect(ctx)))
      assert_true(ctx.bufnr > 0)
      assert_true(ctx.winnr > 0)
      assert_true(ctx.tabnr > 0)
      assert_eq(type(ctx.position_params), "table")
      assert_eq(type(ctx.position_params.context), "table")
      assert_eq(type(ctx.position_params.position), "table")
      assert_true(ctx.position_params.position.character >= 0)
      assert_true(ctx.position_params.position.line >= 0)
      assert_eq(type(ctx.position_params.textDocument), "table")
      assert_eq(type(ctx.position_params.textDocument.uri), "string")
      assert_true(
        strs.endswith(ctx.position_params.textDocument.uri, "README.md")
      )
    end)
    it("_make_lsp_locations_provider", function()
      local ctx = _lsp_locations._lsp_position_context_maker()
      local f = _lsp_locations._make_lsp_locations_provider({
        method = "textDocument/definition",
        capability = "definitionProvider",
      })
      assert_eq(type(f), "function")
      local actual = f("", ctx)
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(#actual >= 0)
        for _, act in ipairs(actual) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) > 0)
        end
      end
    end)
  end)
end)
