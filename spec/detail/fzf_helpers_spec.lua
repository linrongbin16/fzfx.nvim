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

  local tbl = require("fzfx.commons.tbl")
  local str = require("fzfx.commons.str")
  local fileio = require("fzfx.commons.fio")
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
      assert_true(str.endswith(actual, "_test_last_query_cache"))
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
      local input = vim.json.encode({ query = "query2", default_provider = "provider3" })
      fileio.writefile(cache_file, input)
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
      local actual = fzf_helpers.get_command_feed(CommandFeedEnum.ARGS, "expect", "test")
      assert_eq(type(actual), "table")
      assert_eq(expect, actual.query)
      assert_eq(actual.default_provider, nil)
    end)
    it("get visual select feed", function()
      local actual = fzf_helpers.get_command_feed(CommandFeedEnum.VISUAL, "", "test")
      assert_eq(type(actual), "table")
      assert_eq(type(actual.query), "string")
      assert_eq(actual.default_provider, nil)
    end)
    it("get cword feed", function()
      local actual = fzf_helpers.get_command_feed(CommandFeedEnum.CWORD, "", "test")
      assert_eq(type(actual), "table")
      assert_eq(type(actual.query), "string")
      assert_eq(actual.default_provider, nil)
    end)
    it("get resume feed", function()
      local actual = fzf_helpers.get_command_feed(CommandFeedEnum.RESUME, "", "test")
      assert_eq(type(actual), "table")
      assert_eq(type(actual.query), "string")
      assert_true(actual.default_provider == nil or type(actual.default_provider) == "string")
    end)
  end)

  describe("[_get_visual_lines]", function()
    it("is v mode", function()
      vim.cmd([[
            noautocmd edit! README.md
            call feedkeys('V', 'n')
            ]])
      -- vim.fn.feedkeys("V", "n")
      local actual = fzf_helpers._get_visual_lines("V")
      print(string.format("get visual lines(V):%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
    end)
    it("is V mode", function()
      vim.cmd([[
            noautocmd edit README.md
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
            noautocmd edit! README.md
            call feedkeys('V', 'n')
            ]])
      local actual = fzf_helpers._visual_select()
      print(string.format("visual select:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
    end)
    it("is V mode", function()
      vim.cmd([[
            noautocmd edit! README.md
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
      print(string.format("fzf_exec: %s, %s\n", vim.inspect(ok), vim.inspect(actual)))
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
      assert_false(tbl.tbl_empty(actual))
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
      assert_false(tbl.tbl_empty(actual))
      assert_eq(#actual, 2)
    end)
  end)

  describe("[make_fzf_opts]", function()
    it("_generate_fzf_color_opts default", function()
      local actual = fzf_helpers._generate_fzf_color_opts()
      assert_eq(type(actual), "table")
      assert_eq(#actual, 1)
      assert_eq(type(actual[1]), "table")
      assert_eq(actual[1][1], "--color")
      assert_eq(type(actual[1][2]), "string")
    end)
    it("_generate_fzf_color_opts RGB colors", function()
      local config = require("fzfx.config")
      local confs = config.get()
      confs.fzf_color_opts = vim.tbl_deep_extend("force", vim.deepcopy(confs.fzf_color_opts), {
        fg = { "fg", "#ffffff" },
        bg = { "bg", "#000000" },
      })
      config.set(confs)
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
    it("test", function()
      local actual = fzf_helpers.make_fzf_default_opts()
      print(string.format("make default opts: %s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
      assert_true(str.find(actual, "color") > 0)
    end)
  end)

  describe("[make_lua_command]", function()
    it("make lua command", function()
      local actual = fzf_helpers.make_lua_command("rpc", "request.lua")
      print(string.format("make lua command: %s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
      assert_true(actual:gmatch("rpc") ~= nil)
      assert_true(actual:gmatch("request") ~= nil)
      assert_true(str.find(actual, "nvim -n -u NONE --clean --headless -l") >= 1)
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
      assert_true(str.startswith(actual[2], "focus:a+b"))
    end)
  end)
  describe("[_spilt_fzf_preview_window_opts]", function()
    it("no alternative_layout", function()
      local actual1 = fzf_helpers._spilt_fzf_preview_window_opts("up,30%")
      print(string.format("split --preview-window-1:%s\n", vim.inspect(actual1)))
      assert_eq(actual1[1], "up")
      assert_eq(actual1[2], "30%")
      local actual2 =
        fzf_helpers._spilt_fzf_preview_window_opts("down,30,nohidden,cycle,follow,~3,+{2}+3/2")
      print(string.format("split --preview-window-2:%s\n", vim.inspect(actual2)))
      assert_eq(actual2[1], "down")
      assert_eq(actual2[2], "30")
      assert_eq(actual2[3], "nohidden")
      assert_eq(actual2[4], "cycle")
      assert_eq(actual2[5], "follow")
      assert_eq(actual2[6], "~3")
      assert_eq(actual2[7], "+{2}+3/2")
    end)
    it("alternative_layout", function()
      local actual2 = fzf_helpers._spilt_fzf_preview_window_opts(
        "down,30%,<20(cycle,follow,~3,+{2}+3/2),cycle,follow,~3,+{2}+3/2"
      )
      print(string.format("split --preview-window-2:%s\n", vim.inspect(actual2)))
      assert_eq(actual2[1], "down")
      assert_eq(actual2[2], "30%")
      assert_eq(actual2[3], "<20(cycle,follow,~3,+{2}+3/2)")
      assert_eq(actual2[4], "cycle")
      assert_eq(actual2[5], "follow")
      assert_eq(actual2[6], "~3")
      assert_eq(actual2[7], "+{2}+3/2")
    end)
  end)
  describe("[parse_fzf_preview_window_opts]", function()
    it("position", function()
      local actual1 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "up,30%",
        },
      })
      print(string.format("parse fzf --preview-window-1:%s\n", vim.inspect(actual1)))
      assert_eq(actual1.position, "up")
      assert_eq(actual1.size, 30)
      assert_eq(actual1.size_is_percent, true)
      local actual2 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "down,3",
        },
      })
      print(string.format("parse fzf --preview-window-2:%s\n", vim.inspect(actual2)))
      assert_eq(actual2.position, "down")
      assert_eq(actual2.size, 3)
      assert_eq(actual2.size_is_percent, false)
      local actual3 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=left,50%",
      })
      print(string.format("parse fzf --preview-window-3:%s\n", vim.inspect(actual3)))
      assert_eq(actual3.position, "left")
      assert_eq(actual3.size, 50)
      assert_eq(actual3.size_is_percent, true)
      local actual4 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=right,50",
      })
      print(string.format("parse fzf --preview-window-4:%s\n", vim.inspect(actual4)))
      assert_eq(actual4.position, "right")
      assert_eq(actual4.size, 50)
      assert_eq(actual4.size_is_percent, false)
    end)
    it("border", function()
      local actual1 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "up,30%,border-block",
        },
      })
      print(string.format("parse fzf --preview-window-5:%s\n", vim.inspect(actual1)))
      assert_eq(actual1.position, "up")
      assert_eq(actual1.size, 30)
      assert_eq(actual1.size_is_percent, true)
      assert_eq(type(actual1.border), "table")
      assert_eq(#actual1.border, 8)
      local actual2 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=down,3,border-bold",
      })
      print(string.format("parse fzf --preview-window-6:%s\n", vim.inspect(actual2)))
      assert_eq(actual2.position, "down")
      assert_eq(actual2.size, 3)
      assert_eq(actual2.size_is_percent, false)
      assert_eq(type(actual2.border), "table")
      assert_eq(#actual2.border, 8)
    end)
    it("wrap/follow/cycle/hidden", function()
      local actual1 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "wrap",
        },
      })
      print(string.format("parse fzf --preview-window-7:%s\n", vim.inspect(actual1)))
      assert_eq(actual1.wrap, true)
      local actual2 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=down,3,border-bold,nowrap",
      })
      print(string.format("parse fzf --preview-window-8:%s\n", vim.inspect(actual2)))
      assert_eq(actual2.position, "down")
      assert_eq(actual2.size, 3)
      assert_eq(actual2.size_is_percent, false)
      assert_eq(type(actual2.border), "table")
      assert_eq(#actual2.border, 8)
      assert_eq(actual2.wrap, false)
      local actual3 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "nofollow",
        },
      })
      print(string.format("parse fzf --preview-window-9:%s\n", vim.inspect(actual3)))
      assert_eq(actual3.position, "right")
      assert_eq(actual3.size, 50)
      assert_eq(actual3.size_is_percent, true)
      assert_eq(actual3.follow, false)
      local actual4 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=down,3,border-bold,nowrap,follow",
      })
      print(string.format("parse fzf --preview-window-10:%s\n", vim.inspect(actual4)))
      assert_eq(actual4.position, "down")
      assert_eq(actual4.size, 3)
      assert_eq(actual4.size_is_percent, false)
      assert_eq(type(actual4.border), "table")
      assert_eq(#actual4.border, 8)
      assert_eq(actual4.wrap, false)
      assert_eq(actual4.follow, true)
      local actual5 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "nofollow",
        },
      })
      print(string.format("parse fzf --preview-window-11:%s\n", vim.inspect(actual5)))
      assert_eq(actual5.position, "right")
      assert_eq(actual5.size, 50)
      assert_eq(actual5.size_is_percent, true)
      assert_eq(actual5.follow, false)
      local actual6 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=top,3,border-bold,nowrap,follow",
      })
      print(string.format("parse fzf --preview-window-12:%s\n", vim.inspect(actual6)))
      assert_eq(actual6.position, "up")
      assert_eq(actual6.size, 3)
      assert_eq(actual6.size_is_percent, false)
      assert_eq(type(actual6.border), "table")
      assert_eq(#actual6.border, 8)
      assert_eq(actual6.wrap, false)
      assert_eq(actual6.follow, true)
      local actual7 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "nofollow,cycle,hidden",
        },
      })
      print(string.format("parse fzf --preview-window-13:%s\n", vim.inspect(actual7)))
      assert_eq(actual7.position, "right")
      assert_eq(actual7.size, 50)
      assert_eq(actual7.size_is_percent, true)
      assert_eq(actual7.follow, false)
      assert_eq(actual7.cycle, true)
      assert_eq(actual7.hidden, true)
      local actual8 = fzf_helpers.parse_fzf_preview_window_opts({
        "--preview-window=bottom,3,border-bold,nowrap,follow,nocycle,nohidden",
      })
      print(string.format("parse fzf --preview-window-14:%s\n", vim.inspect(actual8)))
      assert_eq(actual8.position, "down")
      assert_eq(actual8.size, 3)
      assert_eq(actual8.size_is_percent, false)
      assert_eq(type(actual8.border), "table")
      assert_eq(#actual8.border, 8)
      assert_eq(actual8.wrap, false)
      assert_eq(actual8.follow, true)
      assert_eq(actual8.cycle, false)
      assert_eq(actual8.hidden, false)
    end)
    it("scroll/header_lines", function()
      local actual1 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "+{2}-5",
        },
      })
      print(string.format("parse fzf --preview-window-15:%s\n", vim.inspect(actual1)))
      assert_eq(actual1.position, "right")
      assert_eq(actual1.size, 50)
      assert_eq(actual1.size_is_percent, true)
      assert_eq(actual1.border, "rounded")
      assert_eq(actual1.scroll, "+{2}-5")
      local actual2 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "~3,+{2}+3/2",
        },
      })
      print(string.format("parse fzf --preview-window-16:%s\n", vim.inspect(actual2)))
      assert_eq(actual2.position, "right")
      assert_eq(actual2.size, 50)
      assert_eq(actual2.size_is_percent, true)
      assert_eq(actual2.border, "rounded")
      assert_eq(actual2.scroll, "+{2}+3/2")
      assert_eq(actual2.header_lines, 3)
      local actual3 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "+{2}-/2",
        },
      })
      print(string.format("parse fzf --preview-window-17:%s\n", vim.inspect(actual3)))
      assert_eq(actual3.position, "right")
      assert_eq(actual3.size, 50)
      assert_eq(actual3.size_is_percent, true)
      assert_eq(actual3.border, "rounded")
      assert_eq(actual3.scroll, "+{2}-/2")
      local actual4 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "~3",
        },
      })
      print(string.format("parse fzf --preview-window-18:%s\n", vim.inspect(actual4)))
      assert_eq(actual4.position, "right")
      assert_eq(actual4.size, 50)
      assert_eq(actual4.size_is_percent, true)
      assert_eq(actual4.border, "rounded")
      assert_eq(actual4.header_lines, 3)
    end)
    it("size_threshold/alternative_layout", function()
      local actual1 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "+{2}-5,right,border-left,<30(up,30%,border-bottom,~3)",
        },
      })
      print(string.format("parse fzf --preview-window-19:%s\n", vim.inspect(actual1)))
      assert_eq(actual1.position, "right")
      assert_eq(actual1.size, 50)
      assert_eq(actual1.size_is_percent, true)
      assert_eq(type(actual1.border), "table")
      assert_eq(#actual1.border, 8)
      assert_eq(actual1.scroll, "+{2}-5")
      assert_eq(actual1.size_threshold, 30)
      assert_eq(actual1.alternative_layout.position, "up")
      assert_eq(actual1.alternative_layout.size, 30)
      assert_eq(actual1.alternative_layout.size_is_percent, true)
      assert_eq(type(actual1.alternative_layout.border), "table")
      assert_eq(#actual1.alternative_layout.border, 8)
      assert_eq(actual1.alternative_layout.header_lines, 3)
      local actual2 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "~3,+{2}+3/2,<90(~5,+{1}+4/3),nohidden",
        },
      })
      print(string.format("parse fzf --preview-window-20:%s\n", vim.inspect(actual2)))
      assert_eq(actual2.position, "right")
      assert_eq(actual2.size, 50)
      assert_eq(actual2.size_is_percent, true)
      assert_eq(actual2.border, "rounded")
      assert_eq(actual2.scroll, "+{2}+3/2")
      assert_eq(actual2.header_lines, 3)
      assert_eq(actual2.size_threshold, 90)
      assert_eq(actual2.alternative_layout.position, "right")
      assert_eq(actual2.alternative_layout.size, 50)
      assert_eq(actual2.alternative_layout.size_is_percent, true)
      assert_eq(actual2.alternative_layout.header_lines, 5)
      assert_eq(actual2.alternative_layout.scroll, "+{1}+4/3")
      assert_eq(actual2.hidden, false)
      local actual3 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "<20(nohidden,nofollow,~5,+{1}+4/3)",
        },
      })
      print(string.format("parse fzf --preview-window-21:%s\n", vim.inspect(actual3)))
      assert_eq(actual3.size_threshold, 20)
      assert_eq(actual3.alternative_layout.hidden, false)
      assert_eq(actual3.alternative_layout.follow, false)
      assert_eq(actual3.alternative_layout.header_lines, 5)
      assert_eq(actual3.alternative_layout.scroll, "+{1}+4/3")
      local actual4 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "~3,+{2}+3/2,<90(),nohidden",
        },
      })
      print(string.format("parse fzf --preview-window-22:%s\n", vim.inspect(actual4)))
      assert_eq(actual4.header_lines, 3)
      assert_eq(actual4.scroll, "+{2}+3/2")
      assert_eq(actual4.size_threshold, 90)
      assert_eq(actual4.alternative_layout.position, "right")
      assert_eq(actual4.alternative_layout.size, 50)
      assert_eq(actual4.alternative_layout.size_is_percent, true)
      assert_eq(actual4.hidden, false)
    end)
    it("override multiples", function()
      local actual1 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "+{2}-5,right,border-left,<30(up,30%,border-bottom,~3)",
        },
        "--preview-window=left,30",
      })
      print(string.format("parse fzf --preview-window-23:%s\n", vim.inspect(actual1)))
      assert_eq(actual1.position, "left")
      assert_eq(actual1.size, 30)
      assert_eq(actual1.size_is_percent, false)
      assert_eq(type(actual1.border), "table")
      assert_eq(#actual1.border, 8)
      assert_eq(actual1.scroll, "+{2}-5")
      assert_eq(actual1.size_threshold, 30)
      assert_eq(actual1.alternative_layout.position, "up")
      assert_eq(actual1.alternative_layout.size, 30)
      assert_eq(actual1.alternative_layout.size_is_percent, true)
      assert_eq(type(actual1.alternative_layout.border), "table")
      assert_eq(#actual1.alternative_layout.border, 8)
      assert_eq(actual1.alternative_layout.header_lines, 3)
      local actual2 = fzf_helpers.parse_fzf_preview_window_opts({
        {
          "--preview-window",
          "~3,+{2}+3/2,<90(~5,+{1}+4/3),nohidden",
        },
        {
          "--preview-window",
          "hidden,wrap,follow",
        },
      })
      print(string.format("parse fzf --preview-window-24:%s\n", vim.inspect(actual2)))
      assert_eq(actual2.position, "right")
      assert_eq(actual2.size, 50)
      assert_eq(actual2.size_is_percent, true)
      assert_eq(actual2.border, "rounded")
      assert_eq(actual2.scroll, "+{2}+3/2")
      assert_eq(actual2.header_lines, 3)
      assert_eq(actual2.size_threshold, 90)
      assert_eq(actual2.alternative_layout.position, "right")
      assert_eq(actual2.alternative_layout.size, 50)
      assert_eq(actual2.alternative_layout.size_is_percent, true)
      assert_eq(actual2.alternative_layout.header_lines, 5)
      assert_eq(actual2.alternative_layout.scroll, "+{1}+4/3")
      assert_eq(actual2.hidden, true)
      assert_eq(actual2.wrap, true)
      assert_eq(actual2.follow, true)
    end)
  end)
end)
