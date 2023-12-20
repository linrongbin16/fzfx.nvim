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

  require("fzfx").setup()
  local tbls = require("fzfx.lib.tables")
  local consts = require("fzfx.lib.constants")
  local strs = require("fzfx.lib.strings")
  local paths = require("fzfx.lib.paths")
  local termcolors = require("fzfx.commons.termcolors")

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
    it("_colorize_lsp_range", function()
      local r = {
        start = { line = 1, character = 20 },
        ["end"] = { line = 1, character = 26 },
      }
      local loc = _lsp_locations._colorize_lsp_range(
        'describe("_lsp_location_render_line", function()',
        r,
        termcolors.red
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

  describe("[_call_hierarchy]", function()
    local RANGE = {
      start = {
        character = 1,
        line = 299,
      },
      ["end"] = {
        character = 0,
        line = 289,
      },
    }
    local CALL_HIERARCHY_ITEM = {
      name = "name",
      kind = 2,
      detail = "detail",
      uri = "file:///usr/home/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
      range = RANGE,
      selectionRange = RANGE,
    }
    local INCOMING_CALLS = {
      from = CALL_HIERARCHY_ITEM,
      fromRanges = { RANGE },
    }
    local OUTGOING_CALLS = {
      to = CALL_HIERARCHY_ITEM,
      fromRanges = { RANGE },
    }
    it("_is_lsp_call_hierarchy_item", function()
      local actual1 = _lsp_locations._is_lsp_call_hierarchy_item(nil)
      assert_false(actual1)
      local actual2 = _lsp_locations._is_lsp_call_hierarchy_item({})
      assert_false(actual2)
      local actual3 = _lsp_locations._is_lsp_call_hierarchy_item({
        name = "name",
        kind = 2,
        detail = "detail",
        uri = "uri",
        range = {
          start = 1,
          ["end"] = 2,
        },
        selectRange = {
          start = 1,
          ["end"] = 2,
        },
      })
      assert_false(actual3)
      local actual4 =
        _lsp_locations._is_lsp_call_hierarchy_item(CALL_HIERARCHY_ITEM)
      assert_true(actual4)
    end)
    it("_is_lsp_call_hierarchy_incoming_call", function()
      local actual1 = _lsp_locations._is_lsp_call_hierarchy_incoming_call(
        "callHierarchy/incomingCalls",
        INCOMING_CALLS
      )
      assert_true(actual1)
    end)
    it("_is_lsp_call_hierarchy_outgoing_call", function()
      local actual1 = _lsp_locations._is_lsp_call_hierarchy_outgoing_call(
        "callHierarchy/outgoingCalls",
        OUTGOING_CALLS
      )
      assert_true(actual1)
    end)
    it("_render_lsp_call_hierarchy_line", function()
      local actual1 = _lsp_locations._render_lsp_call_hierarchy_line(
        INCOMING_CALLS.from,
        INCOMING_CALLS.fromRanges
      )
      print(string.format("incoming render lines:%s\n", vim.inspect(actual1)))
      assert_true(#actual1 >= 0)
      local actual2 = _lsp_locations._render_lsp_call_hierarchy_line(
        OUTGOING_CALLS.to,
        OUTGOING_CALLS.fromRanges
      )
      print(string.format("outgoing render lines:%s\n", vim.inspect(actual2)))
      assert_true(#actual1 >= 0)
    end)
    it("_retrieve_lsp_call_hierarchy_item_and_from_ranges", function()
      local actual11, actual12 =
        _lsp_locations._retrieve_lsp_call_hierarchy_item_and_from_ranges(
          "callHierarchy/incomingCalls",
          INCOMING_CALLS
        )
      assert_true(vim.deep_equal(actual11, INCOMING_CALLS.from))
      assert_true(vim.deep_equal(actual12, INCOMING_CALLS.fromRanges))
      local actual21, actual22 =
        _lsp_locations._retrieve_lsp_call_hierarchy_item_and_from_ranges(
          "callHierarchy/incomingCalls",
          OUTGOING_CALLS
        )
      assert_eq(actual21, nil)
      assert_eq(actual22, nil)
      local actual31, actual32 =
        _lsp_locations._retrieve_lsp_call_hierarchy_item_and_from_ranges(
          "callHierarchy/outgoingCalls",
          INCOMING_CALLS
        )
      assert_eq(actual31, nil)
      assert_eq(actual32, nil)
      local actual41, actual42 =
        _lsp_locations._retrieve_lsp_call_hierarchy_item_and_from_ranges(
          "callHierarchy/outgoingCalls",
          OUTGOING_CALLS
        )
      assert_true(vim.deep_equal(actual41, OUTGOING_CALLS.to))
      assert_true(vim.deep_equal(actual42, OUTGOING_CALLS.fromRanges))
    end)
    it("_make_lsp_call_hierarchy_provider", function()
      local ctx = _lsp_locations._lsp_position_context_maker()
      local f1 = _lsp_locations._make_lsp_call_hierarchy_provider({
        method = "callHierarchy/incomingCalls",
        capability = "callHierarchyProvider",
      })
      assert_eq(type(f1), "function")
      local actual1 = f1("", ctx)
      if actual1 ~= nil then
        assert_eq(type(actual1), "table")
        assert_true(#actual1 >= 0)
        for _, act in ipairs(actual1) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) > 0)
        end
      end
      local f2 = _lsp_locations._make_lsp_call_hierarchy_provider({
        method = "callHierarchy/outgoingCalls",
        capability = "callHierarchyProvider",
      })
      assert_eq(type(f2), "function")
      local actual2 = f2("", ctx)
      if actual2 ~= nil then
        assert_eq(type(actual2), "table")
        assert_true(#actual2 >= 0)
        for _, act in ipairs(actual2) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) > 0)
        end
      end
    end)
  end)
end)
