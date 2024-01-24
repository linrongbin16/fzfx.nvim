---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch, duplicate-set-field
local cwd = vim.fn.getcwd()

describe("detail.fzf_helpers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.opt.swapfile = false
    vim.fn["fzf#exec"] = function()
      return "fzf"
    end
  end)

  local jsons = require("fzfx.commons.jsons")
  local fileios = require("fzfx.commons.fileios")
  local tables = require("fzfx.commons.tables")
  local strings = require("fzfx.commons.strings")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum
  require("fzfx").setup({
    debug = {
      enable = true,
      file_log = true,
    },
  })

  describe("[last_query_cache_name]", function()
    it("test", function()
      local actual = fzf_helpers.last_query_cache_name("test")
      assert_true(strings.endswith(actual, "_test_last_query_cache"))
    end)
  end)
  describe("[get_last_query_cache/save_last_query_cache]", function()
    it("is nil before initialize", function()
      local actual1 = fzf_helpers.get_last_query_cache("test1")
      assert_true(actual1 == nil or type(actual1) == "table")
      local actual2 = fzf_helpers.get_last_query_cache("test2")
      assert_true(actual2 == nil or type(actual2) == "table")
    end)
    it("has value after initialize", function()
      local actual1 = fzf_helpers.get_last_query_cache("test1")
      assert_eq(actual1, nil)
      fzf_helpers.save_last_query_cache("test1", "query", "provider")
      local actual2 = fzf_helpers.get_last_query_cache("test1")
      assert_eq(type(actual2), "table")
      assert_eq(actual2.query, "query")
      assert_eq(actual2.default_provider, "provider")
    end)
    it("has value if exists cache file", function()
      local cache_file = fzf_helpers.last_query_cache_name("test2")
      local input =
        jsons.encode({ query = "query2", default_provider = "provider3" })
      fileios.writefile(cache_file, input)
      local actual = fzf_helpers.get_last_query_cache("test2")
      assert_eq(type(actual), "table")
      assert_eq(actual.query, "query2")
      assert_eq(actual.default_provider, "provider3")
      vim.cmd(string.format([[!rm %s]], cache_file))
    end)
  end)

  describe("[get_command_feed]", function()
    it("get normal args feed", function()
      local expect = "expect"
      local actual =
        fzf_helpers.get_command_feed(CommandFeedEnum.ARGS, "expect", "test")
      assert_eq(type(actual), "table")
      assert_eq(expect, actual.query)
      assert_eq(actual.default_provider, nil)
    end)
    it("get visual select feed", function()
      local actual =
        fzf_helpers.get_command_feed(CommandFeedEnum.VISUAL, "", "test")
      assert_eq(type(actual), "table")
      assert_eq(type(actual.query), "string")
      assert_eq(actual.default_provider, nil)
    end)
    it("get cword feed", function()
      local actual =
        fzf_helpers.get_command_feed(CommandFeedEnum.CWORD, "", "test")
      assert_eq(type(actual), "table")
      assert_eq(type(actual.query), "string")
      assert_eq(actual.default_provider, nil)
    end)
    it("get resume feed", function()
      local actual =
        fzf_helpers.get_command_feed(CommandFeedEnum.RESUME, "", "test")
      assert_eq(type(actual), "table")
      assert_eq(type(actual.query), "string")
      assert_true(
        actual.default_provider == nil
          or type(actual.default_provider) == "string"
      )
    end)
  end)

  describe("[_get_visual_lines]", function()
    it("is v mode", function()
      vim.cmd([[
            edit! README.md
            call feedkeys('V', 'n')
            ]])
      -- vim.fn.feedkeys("V", "n")
      local actual = fzf_helpers._get_visual_lines("V")
      print(string.format("get visual lines(V):%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
    end)
    it("is V mode", function()
      vim.cmd([[
            edit README.md
            call feedkeys('v', 'n')
            call feedkeys('l', 'x')
            call feedkeys('l', 'x')
            ]])
      -- vim.fn.feedkeys("vll", "n")
      local actual = fzf_helpers._get_visual_lines("v")
      print(string.format("get visual lines(v):%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
    end)
  end)

  describe("[_visual_select]", function()
    it("is v mode", function()
      vim.cmd([[
            edit! README.md
            call feedkeys('V', 'n')
            ]])
      local actual = fzf_helpers._visual_select()
      print(string.format("visual select:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
    end)
    it("is V mode", function()
      vim.cmd([[
            edit! README.md
            call feedkeys('v', 'n')
            call feedkeys('l', 'x')
            call feedkeys('l', 'x')
            ]])
      local actual = fzf_helpers._visual_select()
      print(string.format("visual select:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
    end)
  end)

  describe("[nvim_exec]", function()
    it("get nvim path", function()
      local actual = fzf_helpers.nvim_exec()
      print(string.format("nvim_exec: %s\n", vim.inspect(actual)))
      assert_true(type(actual) == "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
      assert_true(vim.fn.executable(actual) > 0)
    end)
  end)

  describe("[fzf_exec]", function()
    it("get fzf path", function()
      local ok, actual = pcall(fzf_helpers.fzf_exec)
      print(
        string.format(
          "fzf_exec: %s, %s\n",
          vim.inspect(ok),
          vim.inspect(actual)
        )
      )
      assert_eq(actual, "fzf")
    end)
  end)

  describe("[preprocess_fzf_opts]", function()
    it("preprocess nil opts", function()
      local actual = fzf_helpers.preprocess_fzf_opts({
        "--bind=enter:accept",
        function()
          return nil
        end,
      })
      print(string.format("preprocess nil opts: %s\n", vim.inspect(actual)))
      assert_true(type(actual) == "table")
      assert_false(tables.tbl_empty(actual))
      assert_eq(#actual, 1)
    end)
    it("preprocess string opts", function()
      local actual = fzf_helpers.preprocess_fzf_opts({
        "--bind=enter:accept",
        function()
          return "--no-multi"
        end,
      })
      print(string.format("preprocess string opts: %s\n", vim.inspect(actual)))
      assert_true(type(actual) == "table")
      assert_false(tables.tbl_empty(actual))
      assert_eq(#actual, 2)
    end)
  end)

  describe("[make_fzf_opts]", function()
    it("_generate_fzf_color_opts", function()
      local actual = fzf_helpers._generate_fzf_color_opts()
      assert_eq(type(actual), "table")
      assert_eq(#actual, 1)
      assert_eq(type(actual[1]), "table")
      assert_eq(actual[1][1], "--color")
      assert_eq(type(actual[1][2]), "string")
    end)
    it("_generate_fzf_icon_opts", function()
      local actual = fzf_helpers._generate_fzf_icon_opts()
      assert_eq(type(actual), "table")
      for _, act in ipairs(actual) do
        assert_eq(type(act), "table")
        assert_eq(#act, 2)
        assert_true(act[1] == "--marker" or act[1] == "--pointer")
      end
    end)
    it("make_fzf_opts", function()
      local expect = "--bind=enter:accept"
      local actual = fzf_helpers.make_fzf_opts({ expect })
      print(string.format("make opts: %s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
      assert_eq(actual, expect)
    end)
  end)

  describe("[make_fzf_default_opts]", function()
    it("make default opts", function()
      local actual = fzf_helpers.make_fzf_default_opts()
      print(string.format("make default opts: %s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
      assert_true(strings.find(actual, "--border") > 0)
    end)
  end)

  describe("[setup]", function()
    it("setup", function()
      fzf_helpers.setup()
      vim.cmd([[colorscheme darkblue]])
      local actual = fzf_helpers.make_fzf_default_opts()
      print(string.format("default fzf opts:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
      assert_true(strings.find(actual, "--border") > 0)
    end)
  end)

  describe("[make_lua_command]", function()
    it("make lua command", function()
      local actual = fzf_helpers.make_lua_command("general", "provider.lua")
      print(string.format("make lua command: %s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
      assert_true(actual:gmatch("general") ~= nil)
      assert_true(actual:gmatch("provider") ~= nil)
      assert_true(
        strings.find(actual, "nvim -n -u NONE --clean --headless -l") >= 1
      )
    end)
  end)

  describe("[FzfOptEventBinder]", function()
    it("creates new", function()
      local actual = fzf_helpers.FzfOptEventBinder:new("focus")
      assert_eq(actual.event, "focus")
    end)
    it("appends", function()
      local actual = fzf_helpers.FzfOptEventBinder:new("focus")
      actual:append("a"):append("b")
      assert_eq(actual.event, "focus")
      assert_eq(#actual.opts, 2)
      assert_eq(actual.opts[1], "a")
      assert_eq(actual.opts[2], "b")
    end)
    it("builds", function()
      local binder = fzf_helpers.FzfOptEventBinder:new("focus")
      assert_true(binder:build() == nil)
      binder:append("a"):append("b")
      local actual = binder:build()
      assert_eq(actual[1], "--bind")
      assert_true(strings.startswith(actual[2], "focus:a+b"))
    end)
  end)
  describe("[parse_fzf_preview_window_opts]", function()
    it("no-alternative 1", function()
      local actual1 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window",
        "up,30%",
      })
      print(
        string.format("parse fzf --preview-window-1:%s", vim.inspect(actual1))
      )
      assert_eq(actual1.position, "up")
      assert_eq(actual1.size, 30)
      assert_eq(actual1.size_is_percent, true)
      local actual2 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window",
        "down,3",
      })
      print(
        string.format("parse fzf --preview-window-2:%s", vim.inspect(actual2))
      )
      assert_eq(actual1.position, "down")
      assert_eq(actual2.size, 3)
      assert_eq(actual2.size_is_percent, true)
      local actual3 =
        fzf_helpers.parse_fzf_preview_window_opts("--preview-window=left,50%")
      print(
        string.format("parse fzf --preview-window-3:%s", vim.inspect(actual3))
      )
      local actual4 =
        fzf_helpers.parse_fzf_preview_window_opts("--preview-window=right,50")
      print(
        string.format("parse fzf --preview-window-4:%s", vim.inspect(actual4))
      )
    end)
    it("no-alternative 2", function() end)
  end)
end)
