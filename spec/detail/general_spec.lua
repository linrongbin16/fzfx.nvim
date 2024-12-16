local cwd = vim.fn.getcwd()

describe("detail.general", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false
  local assert_truthy = assert.is.truthy
  local assert_falsy = assert.is.falsy

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.env._FZFX_NVIM_DEBUG_ENABLE = 1
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local tbl = require("fzfx.commons.tbl")
  local str = require("fzfx.commons.str")
  local fileio = require("fzfx.commons.fileio")
  local path = require("fzfx.commons.path")

  local schema = require("fzfx.schema")
  local ProviderTypeEnum = schema.ProviderTypeEnum

  local config = require("fzfx.config")
  require("fzfx").setup({
    debug = {
      enable = true,
      file_log = true,
    },
  })

  local general = require("fzfx.detail.general")

  describe("[ProviderSwitch:new]", function()
    it("creates PLAIN_COMMAND_STRING provider", function()
      local ps = general.ProviderSwitch:new("single_test", "pipeline", {
        key = "ctrl-k",
        provider = "ls -1",
      })
      assert_eq(type(ps), "table")
      assert_false(tbl.tbl_empty(ps))
      assert_eq(type(ps.provider_configs.default), "table")
      assert_false(tbl.tbl_empty(ps.provider_configs.default))
      assert_eq(ps.provider_configs.default.key, "ctrl-k")
      assert_eq(ps.provider_configs.default.provider, "ls -1")
      assert_eq(ps.provider_configs.default.provider_type, ProviderTypeEnum.PLAIN_COMMAND_STRING)
      assert_eq(ps:switch("default"), nil)
      assert_eq(ps:provide("hello", {}), ProviderTypeEnum.PLAIN_COMMAND_STRING)
      if not github_actions then
        local meta1 = fileio.readfile(general._provider_metafile(), { trim = true })
        local result1 = fileio.readfile(general._provider_resultfile(), { trim = true })
        print(string.format("metafile1:%s\n", meta1))
        local metajson1 = vim.json.decode(meta1) --[[@as table]]
        assert_eq(type(metajson1), "table")
        assert_eq(metajson1.pipeline, "default")
        assert_eq(metajson1.provider_type, ProviderTypeEnum.PLAIN_COMMAND_STRING)
        print(string.format("resultfile1:%s\n", result1))
        assert_eq(result1, "ls -1")
      end
    end)
    it("creates PLAIN_COMMAND_ARRAY provider", function()
      local ps = general.ProviderSwitch:new("single_plain_list_test", "pipeline", {
        key = "ctrl-k",
        provider = { "ls", "-lh", "~" },
      })
      assert_eq(type(ps), "table")
      assert_false(tbl.tbl_empty(ps))
      assert_eq(type(ps.provider_configs.default), "table")
      assert_false(tbl.tbl_empty(ps.provider_configs.default))
      assert_eq(ps.provider_configs.default.key, "ctrl-k")
      assert_eq(type(ps.provider_configs.default.provider), "table")
      assert_eq(#ps.provider_configs.default.provider, 3)
      assert_eq(ps.provider_configs.default.provider[1], "ls")
      assert_eq(ps.provider_configs.default.provider[2], "-lh")
      assert_eq(ps.provider_configs.default.provider[3], "~")
      assert_eq(ps.provider_configs.default.provider_type, ProviderTypeEnum.PLAIN_COMMAND_ARRAY)
      assert_eq(ps:switch("default"), nil)
      assert_eq(ps:provide("hello", {}), ProviderTypeEnum.PLAIN_COMMAND_ARRAY)
      if not github_actions then
        local meta2 = fileio.readfile(general._provider_metafile(), { trim = true })
        local result2 = fileio.readfile(general._provider_resultfile(), { trim = true })
        print(string.format("metafile2:%s\n", meta2))
        local metajson1 = vim.json.decode(meta2) --[[@as table]]
        assert_eq(type(metajson1), "table")
        assert_eq(metajson1.pipeline, "default")
        assert_eq(metajson1.provider_type, ProviderTypeEnum.PLAIN_COMMAND_ARRAY)
        print(string.format("resultfile2:%s\n", result2))
        local resultjson2 = vim.json.decode(result2) --[[@as table]]
        assert_eq(type(resultjson2), "table")
        assert_eq(#resultjson2, 3)
        assert_eq(resultjson2[1], "ls")
        assert_eq(resultjson2[2], "-lh")
        assert_eq(resultjson2[3], "~")
      end
    end)
    it("creates multiple PLAIN_COMMAND_STRING providers", function()
      local ps = general.ProviderSwitch:new("multiple_test", "pipeline", {
        p1 = {
          key = "ctrl-p",
          provider = "p1",
        },
        p2 = {
          key = "ctrl-q",
          provider = { "p2", "p3", "p4" },
        },
      })
      assert_eq(type(ps), "table")
      assert_false(tbl.tbl_empty(ps))

      assert_eq(type(ps.provider_configs.p1), "table")
      assert_false(tbl.tbl_empty(ps.provider_configs.p1))
      assert_eq(ps.provider_configs.p1.key, "ctrl-p")
      assert_eq(type(ps.provider_configs.p1.provider), "string")
      assert_eq(ps.provider_configs.p1.provider, "p1")
      assert_eq(ps.provider_configs.p1.provider_type, ProviderTypeEnum.PLAIN_COMMAND_STRING)
      assert_eq(ps:switch("p1"), nil)
      assert_eq(ps:provide("hello", {}), ProviderTypeEnum.PLAIN_COMMAND_STRING)
      if not github_actions then
        local meta3 = fileio.readfile(general._provider_metafile(), { trim = true })
        local result3 = fileio.readfile(general._provider_resultfile(), { trim = true })
        print(string.format("metafile3:%s\n", meta3))
        local metajson1 = vim.json.decode(meta3) --[[@as table]]
        assert_eq(type(metajson1), "table")
        assert_eq(metajson1.pipeline, "p1")
        assert_eq(metajson1.provider_type, ProviderTypeEnum.PLAIN_COMMAND_STRING)
        print(string.format("resultfile3:%s\n", result3))
        assert_eq(result3, "p1")
      end

      assert_eq(type(ps.provider_configs.p2), "table")
      assert_false(tbl.tbl_empty(ps.provider_configs.p2))
      assert_eq(ps.provider_configs.p2.key, "ctrl-q")
      assert_eq(type(ps.provider_configs.p2.provider), "table")
      assert_eq(type(ps.provider_configs.p2.provider), "table")
      assert_eq(#ps.provider_configs.p2.provider, 3)
      assert_eq(ps.provider_configs.p2.provider[1], "p2")
      assert_eq(ps.provider_configs.p2.provider[2], "p3")
      assert_eq(ps.provider_configs.p2.provider[3], "p4")
      assert_eq(ps.provider_configs.p2.provider_type, ProviderTypeEnum.PLAIN_COMMAND_ARRAY)
      assert_eq(ps:switch("p2"), nil)
      assert_eq(ps:provide("hello", {}), ProviderTypeEnum.PLAIN_COMMAND_ARRAY)
      if not github_actions then
        local meta4 = fileio.readfile(general._provider_metafile(), { trim = true })
        local result4 = fileio.readfile(general._provider_resultfile(), { trim = true })
        print(string.format("metafile4:%s\n", meta4))
        local metajson1 = vim.json.decode(meta4) --[[@as table]]
        assert_eq(type(metajson1), "table")
        assert_eq(metajson1.pipeline, "p2")
        assert_eq(metajson1.provider_type, ProviderTypeEnum.PLAIN_COMMAND_ARRAY)
        print(string.format("resultfile4:%s\n", result4))
        local resultjson4 = vim.json.decode(result4) --[[@as table]]
        assert_eq(type(resultjson4), "table")
        assert_eq(#resultjson4, 3)
        assert_eq(resultjson4[1], "p2")
        assert_eq(resultjson4[2], "p3")
        assert_eq(resultjson4[3], "p4")
      end
    end)
    it("creates FUNCTIONAL_COMMAND_STRING provider", function()
      local ps = general.ProviderSwitch:new("single_test", "pipeline", {
        key = "ctrl-k",
        provider = function()
          return "ls -1"
        end,
        provider_type = ProviderTypeEnum.FUNCTIONAL_COMMAND_STRING,
      })
      assert_eq(type(ps), "table")
      assert_false(tbl.tbl_empty(ps))
      assert_eq(type(ps.provider_configs.default), "table")
      assert_false(tbl.tbl_empty(ps.provider_configs.default))
      assert_eq(ps.provider_configs.default.key, "ctrl-k")
      assert_eq(ps.provider_configs.default.provider(), "ls -1")
      assert_eq(
        ps.provider_configs.default.provider_type,
        ProviderTypeEnum.FUNCTIONAL_COMMAND_STRING
      )
      assert_eq(ps:switch("default"), nil)
      assert_eq(ps:provide("hello", {}), ProviderTypeEnum.FUNCTIONAL_COMMAND_STRING)
      if not github_actions then
        local meta1 = fileio.readfile(general._provider_metafile(), { trim = true })
        local result1 = fileio.readfile(general._provider_resultfile(), { trim = true })
        print(string.format("metafile1:%s\n", meta1))
        local metajson1 = vim.json.decode(meta1) --[[@as table]]
        assert_eq(type(metajson1), "table")
        assert_eq(metajson1.pipeline, "default")
        assert_eq(metajson1.provider_type, ProviderTypeEnum.FUNCTIONAL_COMMAND_STRING)
        print(string.format("resultfile1:%s\n", result1))
        assert_eq(result1, "ls -1")
      end
    end)
    it("creates FUNCTIONAL_COMMAND_ARRAY provider", function()
      local ps = general.ProviderSwitch:new("single_test", "pipeline", {
        key = "ctrl-k",
        provider = function()
          return { "ls", "-1" }
        end,
        provider_type = ProviderTypeEnum.FUNCTIONAL_COMMAND_ARRAY,
      })
      assert_eq(type(ps), "table")
      assert_false(tbl.tbl_empty(ps))
      assert_eq(type(ps.provider_configs.default), "table")
      assert_false(tbl.tbl_empty(ps.provider_configs.default))
      assert_eq(ps.provider_configs.default.key, "ctrl-k")
      assert_true(vim.deep_equal(ps.provider_configs.default.provider(), { "ls", "-1" }))
      assert_eq(
        ps.provider_configs.default.provider_type,
        ProviderTypeEnum.FUNCTIONAL_COMMAND_ARRAY
      )
      assert_eq(ps:switch("default"), nil)
      assert_eq(ps:provide("hello", {}), ProviderTypeEnum.FUNCTIONAL_COMMAND_ARRAY)
      if not github_actions then
        local meta1 = fileio.readfile(general._provider_metafile(), { trim = true })
        local result1 = fileio.readfile(general._provider_resultfile(), { trim = true })
        print(string.format("metafile1:%s\n", meta1))
        local metajson1 = vim.json.decode(meta1) --[[@as table]]
        assert_eq(type(metajson1), "table")
        assert_eq(metajson1.pipeline, "default")
        assert_eq(metajson1.provider_type, ProviderTypeEnum.FUNCTIONAL_COMMAND_ARRAY)
        print(string.format("resultfile1:%s\n", result1))
        assert_eq(result1, vim.json.encode({ "ls", "-1" }))
      end
    end)
    it("creates DIRECT provider", function()
      local ps = general.ProviderSwitch:new("single_test", "pipeline", {
        key = "ctrl-k",
        provider = function()
          return { "ls", "-1" }
        end,
        provider_type = ProviderTypeEnum.DIRECT,
      })
      assert_eq(type(ps), "table")
      assert_false(tbl.tbl_empty(ps))
      assert_eq(type(ps.provider_configs.default), "table")
      assert_false(tbl.tbl_empty(ps.provider_configs.default))
      assert_eq(ps.provider_configs.default.key, "ctrl-k")
      assert_true(vim.deep_equal(ps.provider_configs.default.provider(), { "ls", "-1" }))
      assert_eq(ps.provider_configs.default.provider_type, ProviderTypeEnum.DIRECT)
      assert_eq(ps:switch("default"), nil)
      assert_eq(ps:provide("hello", {}), ProviderTypeEnum.DIRECT)
      if not github_actions then
        local meta1 = fileio.readfile(general._provider_metafile(), { trim = true })
        local result1 = fileio.readfile(general._provider_resultfile(), { trim = true })
        print(string.format("metafile1:%s\n", meta1))
        local metajson1 = vim.json.decode(meta1) --[[@as table]]
        assert_eq(type(metajson1), "table")
        assert_eq(metajson1.pipeline, "default")
        assert_eq(metajson1.provider_type, ProviderTypeEnum.DIRECT)
        print(string.format("resultfile1:%s\n", result1))
        assert_eq(result1, "ls\n-1")
      end
    end)
  end)
  describe("[PreviewerSwitch:preview]", function()
    local FZFPORTFILE = general._make_cache_filename("fzf_port_file")
    it("is a plain/plain_list provider", function()
      local ps = general.PreviewerSwitch:new("plain_test", "p1", {
        p1 = {
          previewer = function()
            return "ls -lh"
          end,
        },
        p2 = {
          previewer = function()
            return { "ls", "-lha", "~" }
          end,
          previewer_type = "command_list",
        },
      }, FZFPORTFILE)
      print(string.format("GITHUB_ACTIONS:%s\n", os.getenv("GITHUB_ACTIONS")))
      assert_eq(ps:preview("hello", {}), "command")
      if not github_actions then
        local meta1 = fileio.readfile(general._previewer_metafile(), { trim = true })
        local result1 = fileio.readfile(general._previewer_resultfile(), { trim = true })
        print(string.format("metafile1:%s\n", meta1))
        local metajson1 = vim.json.decode(meta1) --[[@as table]]
        assert_eq(type(metajson1), "table")
        assert_eq(metajson1.pipeline, "p1")
        assert_eq(metajson1.previewer_type, "command")
        print(string.format("resultfile1:%s\n", result1))
        assert_eq(result1, "ls -lh")
      end
      ps:switch("p2")
      assert_eq(ps:preview("world", {}), "command_list")
      if not github_actions then
        local meta2 = fileio.readfile(general._previewer_metafile(), { trim = true })
        local result2 = fileio.readfile(general._previewer_resultfile(), { trim = true })
        print(string.format("metafile2:%s\n", meta2))
        local metajson2 = vim.json.decode(meta2) --[[@as table]]
        assert_eq(type(metajson2), "table")
        assert_eq(metajson2.pipeline, "p2")
        assert_eq(metajson2.previewer_type, "command_list")
        print(string.format("resultfile2:%s\n", result2))
        local resultjson2 = vim.json.decode(result2) --[[@as table]]
        assert_eq(type(resultjson2), "table")
        assert_eq(#resultjson2, 3)
        assert_eq(resultjson2[1], "ls")
        assert_eq(resultjson2[2], "-lha")
        assert_eq(resultjson2[3], "~")
      end
    end)
    it("is a command/command_list previewer", function()
      local ps = general.PreviewerSwitch:new("command_test", "p1", {
        p1 = {
          previewer = function()
            return "ls -lh"
          end,
          previewer_type = schema.PreviewerTypeEnum.COMMAND,
        },
        p2 = {
          previewer = function()
            return { "ls", "-lha", "~" }
          end,
          previewer_type = schema.PreviewerTypeEnum.COMMAND_LIST,
        },
      }, FZFPORTFILE)
      assert_eq(ps:preview("hello", {}), "command")
      if not github_actions then
        local meta1 = fileio.readfile(general._previewer_metafile(), { trim = true })
        local result1 = fileio.readfile(general._previewer_resultfile(), { trim = true })
        print(string.format("metafile:%s\n", meta1))
        local metajson1 = vim.json.decode(meta1) --[[@as table]]
        assert_eq(type(metajson1), "table")
        assert_eq(metajson1.pipeline, "p1")
        assert_eq(metajson1.previewer_type, "command")
        print(string.format("resultfile:%s\n", result1))
        assert_eq(result1, "ls -lh")
      end
      ps:switch("p2")
      assert_eq(ps:preview("world", {}), "command_list")
      if not github_actions then
        local meta2 = fileio.readfile(general._previewer_metafile(), { trim = true })
        local result2 = fileio.readfile(general._previewer_resultfile(), { trim = true })
        print(string.format("metafile:%s\n", meta2))
        local metajson2 = vim.json.decode(meta2) --[[@as table]]
        assert_eq(type(metajson2), "table")
        assert_eq(metajson2.pipeline, "p2")
        assert_eq(metajson2.previewer_type, "command_list")
        print(string.format("resultfile:%s\n", result2))
        local resultjson2 = vim.json.decode(result2) --[[@as table]]
        assert_eq(type(resultjson2), "table")
        assert_eq(#resultjson2, 3)
        assert_eq(resultjson2[1], "ls")
        assert_eq(resultjson2[2], "-lha")
        assert_eq(resultjson2[3], "~")
      end
    end)
  end)
  describe("[PreviewerSwitch:new]", function()
    local FZFPORTFILE = general._make_cache_filename("fzf_port_file")
    it("creates single command previewer", function()
      local ps = general.PreviewerSwitch:new("single", "pipeline", {
        previewer = function()
          return "ls -1"
        end,
      }, FZFPORTFILE)
      assert_eq(type(ps), "table")
      assert_false(tbl.tbl_empty(ps))
      assert_eq(type(ps.previewer_configs), "table")
      assert_false(tbl.tbl_empty(ps.previewer_configs))
      assert_eq(type(ps.previewer_configs.default.previewer), "function")
      assert_eq(ps.previewer_configs.default.previewer(), "ls -1")
      assert_eq(ps.previewer_configs.default.previewer_type, "command")
      assert_eq(ps.fzf_port_reader.filename, FZFPORTFILE)
      assert_eq(ps:switch("default"), nil)
    end)
    it("creates multiple command previewer", function()
      local ps = general.PreviewerSwitch:new("single", "pipeline", {
        p1 = {
          previewer = function()
            return "p1"
          end,
        },
        p2 = {
          previewer = function()
            return "p2"
          end,
        },
      }, FZFPORTFILE)
      assert_eq(type(ps), "table")
      assert_false(tbl.tbl_empty(ps))
      assert_eq(type(ps.previewer_configs), "table")
      assert_false(tbl.tbl_empty(ps.previewer_configs))
      assert_eq(type(ps.previewer_configs.p1.previewer), "function")
      assert_eq(ps.previewer_configs.p1.previewer(), "p1")
      assert_eq(ps.previewer_configs.p1.previewer_type, "command")
      assert_eq(ps:switch("p1"), nil)

      assert_eq(type(ps.previewer_configs), "table")
      assert_false(tbl.tbl_empty(ps.previewer_configs))
      assert_eq(type(ps.previewer_configs.p2.previewer), "function")
      assert_eq(ps.previewer_configs.p2.previewer(), "p2")
      assert_eq(ps.previewer_configs.p2.previewer_type, "command")
      assert_eq(ps:switch("p2"), nil)
    end)
  end)
  describe("[PreviewerSwitch:_preview_label]", function()
    local FZFPORTFILE = general._make_cache_filename("fzf_port_file")
    it("not previews label", function()
      local name = "label_test1"
      fileio.writefile(FZFPORTFILE, "12345")
      local ps = general.PreviewerSwitch:new(name, "p1", {
        p1 = {
          previewer = function()
            return "ls -lh"
          end,
        },
        p2 = {
          previewer = function()
            return { "ls", "-lha", "~" }
          end,
          previewer_type = "command_list",
        },
      }, FZFPORTFILE)
      print(string.format("GITHUB_ACTIONS:%s\n", os.getenv("GITHUB_ACTIONS")))
      assert_true(ps:_preview_label("hello", {}) == nil)
      ps:switch("p2")
      assert_true(ps:_preview_label("world", {}) == nil)
    end)
    it("previews label", function()
      local name = "label_test2"
      fileio.writefile(FZFPORTFILE, "54321")
      local ps = general.PreviewerSwitch:new(name, "p1", {
        p1 = {
          previewer = function()
            return "ls -lh"
          end,
          previewer_label = function(line)
            return nil
          end,
        },
        p2 = {
          previewer = function()
            return { "ls", "-lha", "~" }
          end,
          previewer_type = "command_list",
          previewer_label = function(line)
            return nil
          end,
        },
      }, FZFPORTFILE)
      print(string.format("GITHUB_ACTIONS:%s\n", os.getenv("GITHUB_ACTIONS")))
      assert_true(ps:_preview_label("hello", {}) == "p1")
      ps:switch("p2")
      assert_true(ps:_preview_label("world", {}) == "p2")
    end)
  end)
  describe("[PreviewerSwitch:current]", function()
    local FZFPORTFILE = general._make_cache_filename("fzf_port_file")
    it("test", function()
      local name = "current1"
      fileio.writefile(FZFPORTFILE, "12345")
      local ps = general.PreviewerSwitch:new(name, "p1", {
        p1 = {
          previewer = function()
            return "ls -lh"
          end,
        },
        p2 = {
          previewer = function()
            return { "ls", "-lha", "~" }
          end,
          previewer_type = "command_list",
        },
      }, FZFPORTFILE)
      local actual = ps:current()
      assert_eq(actual.previewer(), "ls -lh")
    end)
  end)
  describe("[_render_help]", function()
    it("renders1", function()
      local actual = general._render_help("doc1", "bs")
      print(string.format("render help1:%s\n", actual))
      assert_true(actual:gmatch("to doc1") ~= nil)
      assert_true(actual:gmatch("BS") ~= nil)
      assert_true(str.find(actual, "to doc1") > str.find(actual, "BS"))
    end)
    it("renders2", function()
      local actual = general._render_help("do_it", "ctrl")
      print(string.format("render help2:%s\n", actual))
      assert_true(actual:gmatch("to do it") ~= nil)
      assert_true(actual:gmatch("CTRL") ~= nil)
      assert_true(str.find(actual, "to do it") > str.find(actual, "CTRL"))
    end)
    it("renders3", function()
      local actual = general._render_help("ok_ok", "alt")
      print(string.format("render help3:%s\n", actual))
      assert_true(actual:gmatch("to ok ok") ~= nil)
      assert_true(actual:gmatch("ALT") ~= nil)
      assert_true(str.find(actual, "to ok ok") > str.find(actual, "ALT"))
    end)
  end)
  describe("[_should_skip_help]", function()
    it("skip1", function()
      local actual = general._should_skip_help(nil, "bs")
      assert_false(actual)
    end)
    it("skip2", function()
      local actual = general._should_skip_help({}, "bs")
      assert_false(actual)
    end)
    it("skip3", function()
      local actual = general._should_skip_help({ "bs" }, "bs")
      assert_true(actual)
    end)
  end)
  describe("[make_help_doc]", function()
    it("make1", function()
      local action_configs = {
        action1 = {
          key = "ctrl-l",
        },
        upper = {
          key = "ctrl-u",
        },
      }
      local actual = general._make_help_doc(action_configs, {})
      assert_eq(type(actual), "table")
      assert_eq(#actual, 2)
      assert_true(str.find(actual[1], "to action1") > str.find(actual[1], "CTRL-L"))
      assert_true(str.endswith(actual[1], "to action1"))
      assert_true(str.find(actual[2], "to upper") > str.find(actual[2], "CTRL-U"))
      assert_true(str.endswith(actual[2], "to upper"))
    end)
    it("make2", function()
      local action_configs = {
        action1 = {
          key = "ctrl-l",
        },
        upper = {
          key = "ctrl-u",
        },
        goto_inter = {
          key = "alt-p",
        },
      }
      local actual = general._make_help_doc(action_configs, {})
      assert_eq(type(actual), "table")
      assert_eq(#actual, 3)
      assert_true(str.find(actual[1], "to action1") > str.find(actual[1], "CTRL-L"))
      assert_true(str.endswith(actual[1], "to action1"))
      assert_true(str.find(actual[2], "to goto inter") > str.find(actual[2], "ALT-P"))
      assert_true(str.endswith(actual[2], "to goto inter"))
      assert_true(str.find(actual[3], "to upper") > str.find(actual[3], "CTRL-U"))
      assert_true(str.endswith(actual[3], "to upper"))
    end)
  end)
  describe("[_make_cache_filename]", function()
    it("is debug mode", function()
      vim.env._FZFX_NVIM_DEBUG_ENABLE = 1
      assert_eq(
        general._make_cache_filename("provider", "switch", "meta", "live_grep"),
        path.join(config.get().cache.dir, "provider_switch_meta_live_grep")
      )
    end)
    it("is not debug mode", function()
      vim.env._FZFX_NVIM_DEBUG_ENABLE = 0
      local actual = general._make_cache_filename("provider", "switch", "meta", "live_grep")
      print(string.format("make cache filename (non-debug):%s", vim.inspect(actual)))
      assert_true(actual ~= path.join(vim.fn.stdpath("data"), "provider_switch_meta_live_grep"))
    end)
  end)
  describe("[make_provider_meta_opts]", function()
    it("makes without icon", function()
      local actual1 = general.make_provider_meta_opts("test1", {
        key = "test1",
        provider_type = ProviderTypeEnum.FUNCTIONAL_COMMAND_STRING,
      })
      assert_eq(type(actual1), "table")
      assert_eq(actual1.pipeline, "test1")
      assert_eq(actual1.provider_type, ProviderTypeEnum.FUNCTIONAL_COMMAND_STRING)
      local actual2 = general.make_provider_meta_opts("test2", {
        key = "test2",
        provider_type = ProviderTypeEnum.FUNCTIONAL_COMMAND_ARRAY,
      })
      assert_eq(type(actual2), "table")
      assert_eq(actual2.pipeline, "test2")
      assert_eq(actual2.provider_type, ProviderTypeEnum.FUNCTIONAL_COMMAND_ARRAY)
    end)
    it("makes with icon", function()
      local actual = general.make_provider_meta_opts("test3", {
        key = "test3",
        provider_type = ProviderTypeEnum.DIRECT,
      })
      assert_eq(type(actual), "table")
      assert_eq(actual.pipeline, "test3")
      assert_eq(actual.provider_type, ProviderTypeEnum.DIRECT)
    end)
  end)
  describe("[make_previewer_meta_opts]", function()
    it("makes without icon", function()
      local actual1 = general.make_previewer_meta_opts("test1", {
        previewer = function() end,
        previewer_type = "command",
      })
      assert_eq(type(actual1), "table")
      assert_eq(actual1.pipeline, "test1")
      assert_eq(actual1.previewer_type, "command")
      local actual2 = general.make_previewer_meta_opts("test2", {
        previewer = function() end,
        previewer_type = "command_list",
      })
      assert_eq(type(actual2), "table")
      assert_eq(actual2.pipeline, "test2")
      assert_eq(actual2.previewer_type, "command_list")
    end)
    it("makes with icon", function()
      local actual = general.make_previewer_meta_opts("test3", {
        previewer = function() end,
        previewer_type = "list",
      })
      assert_eq(type(actual), "table")
      assert_eq(actual.pipeline, "test3")
      assert_eq(actual.previewer_type, "list")
    end)
  end)
  describe("[_make_user_command]", function()
    it("makes", function()
      local actual = general._make_user_command(
        "live_grep_test",
        config.get().live_grep.command,
        config.get().live_grep.variants,
        config.get().live_grep
      )
      assert_true(actual == nil)
    end)
  end)
  describe("[_send_http_post]", function()
    it("send", function()
      local ok, err = pcall(general._send_http_post, "12345", "asdf")
      assert_eq(type(ok), "boolean")
      assert_true(type(err) == "string" or err == nil)
    end)
  end)
  describe("[_make_cache_filename]", function()
    it("_provider_metafile", function()
      local actual = general._provider_metafile()
      assert_true(str.endswith(actual, "provider_metafile"))
    end)
    it("_provider_resultfile", function()
      local actual1 = general._provider_resultfile()
      assert_true(str.endswith(actual1, "provider_resultfile"))
    end)
    it("_previewer_metafile", function()
      local actual = general._previewer_metafile()
      assert_true(str.endswith(actual, "previewer_metafile"))
    end)
    it("_previewer_resultfile", function()
      local actual = general._previewer_resultfile()
      assert_true(str.endswith(actual, "previewer_resultfile"))
    end)
    it("_fzf_port_file", function()
      local actual = general._fzf_port_file()
      assert_true(str.not_empty(actual))
    end)
    it("_buffer_previewer_actions_file", function()
      local actual = general._buffer_previewer_actions_file()
      assert_true(str.endswith(actual, "buffer_previewer_actions_file"))
    end)
  end)
  describe("[dump_action_command]", function()
    it("test", function()
      local actual = general.dump_action_command("toggle-preview", "action_file")
      print(string.format("dump action command:%s\n", vim.inspect(actual)))
      assert_true(str.startswith(actual, "execute-silent(echo"))
      assert_true(str.endswith(actual, "toggle-preview>action_file)"))
    end)
  end)
  describe("[mock_buffer_previewer_fzf_opts]", function()
    local ACTIONS_FILE = "actions_file"
    it("preview window", function()
      local fzf_opts1 = {
        "--preview-window=left,50%",
      }
      local actual11, actual12 = general.mock_buffer_previewer_fzf_opts(fzf_opts1, ACTIONS_FILE)
      print(string.format("mock-1:%s, %s\n", vim.inspect(actual11), vim.inspect(actual12)))
      assert_eq(#actual11, 0)
      assert_eq(actual12.fzf_preview_window_opts.position, "left")
      assert_eq(actual12.fzf_preview_window_opts.size, 50)
      local fzf_opts2 = {
        { "--preview-window", "up,50" },
      }
      local actual21, actual22 = general.mock_buffer_previewer_fzf_opts(fzf_opts2, ACTIONS_FILE)
      print(string.format("mock-2:%s, %s\n", vim.inspect(actual21), vim.inspect(actual22)))
      assert_eq(#actual21, 0)
      assert_eq(actual22.fzf_preview_window_opts.position, "up")
      assert_eq(actual22.fzf_preview_window_opts.size, 50)
      assert_eq(actual22.fzf_preview_window_opts.size_is_percent, false)
    end)
    it("border", function()
      local fzf_opts1 = {
        "--preview-window=left,50%",
        "--border=double",
      }
      local actual11, actual12 = general.mock_buffer_previewer_fzf_opts(fzf_opts1, ACTIONS_FILE)
      print(string.format("mock-3:%s, %s\n", vim.inspect(actual11), vim.inspect(actual12)))
      assert_eq(#actual11, 0)
      assert_eq(actual12.fzf_preview_window_opts.position, "left")
      assert_eq(actual12.fzf_preview_window_opts.size, 50)
      assert_eq(actual12.fzf_border_opts, "double")
    end)
    it("preview-half-page-down/preview-half-page-up", function()
      local fzf_opts1 = {
        "--preview-window=left,50%",
        "--border=double",
        "--bind=ctrl-f:preview-half-page-down",
        "--bind=ctrl-b:preview-half-page-up",
      }
      local actual11, actual12 = general.mock_buffer_previewer_fzf_opts(fzf_opts1, ACTIONS_FILE)
      print(string.format("mock-4:%s, %s\n", vim.inspect(actual11), vim.inspect(actual12)))
      assert_eq(#actual11, 2)
      local first_bind = actual11[1]
      local second_bind = actual11[2]
      assert_eq(first_bind[1], "--bind")
      assert_true(str.startswith(first_bind[2], "ctrl-f:execute-silent(echo"))
      assert_eq(second_bind[1], "--bind")
      assert_true(str.startswith(second_bind[2], "ctrl-b:execute-silent(echo"))
      assert_eq(actual12.fzf_preview_window_opts.position, "left")
      assert_eq(actual12.fzf_preview_window_opts.size, 50)
      assert_eq(actual12.fzf_border_opts, "double")
    end)
  end)
  -- describe("[decode_fzf_status_current_text]", function()
  --   it("test", function()
  --     local input1 =
  --       '{"reading":false,"progress":100,"query":"f","position":0,"sort":true,"totalCount":148,"matchCount":100,"current":{"index":92,"text":" lua/fzfx.lua"},"matches":[{"index":93,"text":" lua/config.lua"}]}'
  --     local actual1 = general.decode_fzf_status_current_text(input1)
  --     assert_eq(actual1, " lua/fzfx.lua")
  --     local input2 =
  --       [[{"reading":false,"progress":100,"query":"f","position":0,"sort":true,"totalCount":148,"matchCount":100,"current":{"index":92,"text":" \"lua/fzfx.lua"},"matches":[{"index":93,"text":" lua/config.lua"}]}]]
  --     local actual2 = general.decode_fzf_status_current_text(input2)
  --     assert_eq(actual2, [[ \"lua/fzfx.lua]])
  --   end)
  -- end)
end)
