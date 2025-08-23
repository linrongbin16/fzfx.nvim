---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("fzfx.cfg.file_explorer", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local GITHUB_ACTIONS = os.getenv("GITHUB_ACTIONS") == "true"

  local str = require("fzfx.commons.str")
  local path = require("fzfx.commons.path")
  local consts = require("fzfx.lib.constants")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local file_explorer_cfg = require("fzfx.cfg.file_explorer")

  -- require("fzfx").setup()

  --- @return fzfx.PipelineContext
  local function make_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  describe("[file_explorer]", function()
    local LS_LINES = {
      "-rw-r--r--   1 rlin  staff   1.0K Aug 28 12:39 LICENSE",
      "-rw-r--r--   1 rlin  staff    27K Oct  8 11:37 README.md",
      "drwxr-xr-x   4 rlin  staff   128B Sep 22 10:11 bin",
      "-rw-r--r--   1 rlin  staff   120B Sep  5 14:14 codecov.yml",
    }
    local LSD_LINES = {
      "drwxr-xr-x  rlin staff 160 B  Wed Oct 25 16:59:44 2023 bin",
      ".rw-r--r--  rlin staff  54 KB Tue Oct 31 22:29:35 2023 CHANGELOG.md",
      ".rw-r--r--  rlin staff 120 B  Tue Oct 10 14:47:43 2023 codecov.yml",
      ".rw-r--r--  rlin staff 1.0 KB Mon Aug 28 12:39:24 2023 LICENSE",
      "drwxr-xr-x  rlin staff 128 B  Tue Oct 31 21:55:28 2023 lua",
      ".rw-r--r--  rlin staff  38 KB Wed Nov  1 10:29:19 2023 README.md",
      "drwxr-xr-x  rlin staff 992 B  Wed Nov  1 11:16:13 2023 test",
    }
    local EZA_LINES = {
      "drwxr-xr-x     - linrongbin 22 Sep 10:11  bin",
      ".rw-r--r--   120 linrongbin  5 Sep 14:14  codecov.yml",
      ".rw-r--r--  1.1k linrongbin 28 Aug 12:39  LICENSE",
      "drwxr-xr-x     - linrongbin  8 Oct 09:14  lua",
      ".rw-r--r--   28k linrongbin  8 Oct 11:37  README.md",
      "drwxr-xr-x     - linrongbin  8 Oct 11:44  test",
    }
    it("_context_maker", function()
      local ctx = file_explorer_cfg._context_maker()
      assert_eq(type(ctx), "table")
      assert_true(ctx.bufnr > 0)
      assert_true(ctx.winnr > 0)
      assert_true(ctx.tabnr > 0)
      assert_true(vim.fn.filereadable(ctx.cwd) > 0)
    end)
    it("_parse_opts", function()
      local actual1 = file_explorer_cfg._parse_opts()
      assert_true(actual1 == "-lh")
      local actual2 = file_explorer_cfg._parse_opts({})
      assert_true(actual2 == "-lh")
      local actual3 = file_explorer_cfg._parse_opts({ include_hidden = false })
      assert_true(actual3 == "-lh")
      local actual4 = file_explorer_cfg._parse_opts({ include_hidden = true })
      assert_true(actual4 == "-lha")
    end)
    it("_make_provider_lsd case-1", function()
      local ctx = file_explorer_cfg._context_maker()
      local f = file_explorer_cfg._make_provider_lsd()
      assert_eq(type(f), "function")
      local actual = f("", ctx)
      print(string.format("_make_provider_lsd-1:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(str.find(actual, "echo") > 0)
      assert_true(str.find(actual, consts.LSD) > 0)
      assert_true(str.find(actual, "-lh") > 0)
      assert_true(str.find(actual, "-lha") == nil)
      assert_true(
        str.find(
          actual,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )
    end)
    it("_make_provider_lsd case-2", function()
      local ctx = file_explorer_cfg._context_maker()
      local f = file_explorer_cfg._make_provider_lsd({ include_hidden = true })
      assert_eq(type(f), "function")
      local actual2 = f("", ctx)
      print(string.format("_make_provider_lsd-2:%s\n", vim.inspect(actual2)))
      assert_eq(type(actual2), "string")
      assert_true(str.find(actual2, "echo") > 0)
      assert_true(str.find(actual2, consts.LSD) > 0)
      assert_true(str.find(actual2, "-lha") > 0)
      assert_true(
        str.find(
          actual2,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )
    end)
    it("_make_provider_eza case-1", function()
      local ctx = file_explorer_cfg._context_maker()
      local f = file_explorer_cfg._make_provider_eza()
      assert_eq(type(f), "function")
      local actual = f("", ctx)
      print(string.format("_make_provider_eza-1:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(str.find(actual, "echo") > 0)
      assert_true(str.find(actual, consts.EZA) > 0)
      assert_true(str.find(actual, "-lh") > 0)
      assert_true(str.find(actual, "-lha") == nil)
      assert_true(
        str.find(
          actual,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )
    end)
    it("_make_provider_eza case-2", function()
      local ctx = file_explorer_cfg._context_maker()
      local f = file_explorer_cfg._make_provider_eza({ include_hidden = true })
      assert_eq(type(f), "function")
      local actual = f("", ctx)
      print(string.format("_make_provider_eza-2:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(str.find(actual, "echo") > 0)
      assert_true(str.find(actual, consts.EZA) > 0)
      assert_true(str.find(actual, "-lhaa") > 0)
      assert_true(
        str.find(
          actual,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )
    end)
    it("_make_provider_ls case-1", function()
      local ctx = file_explorer_cfg._context_maker()
      local f = file_explorer_cfg._make_provider_ls()
      assert_eq(type(f), "function")
      local actual = f("", ctx)
      print(string.format("_make_provider_ls-1:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(str.find(actual, "echo") > 0)
      assert_true(str.find(actual, consts.LS) > 0)
      assert_true(str.find(actual, "-lh") > 0)
      assert_true(str.find(actual, "-lha") == nil)
      assert_true(
        str.find(
          actual,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )
    end)
    it("_make_provider_ls case-2", function()
      local ctx = file_explorer_cfg._context_maker()
      local f = file_explorer_cfg._make_provider_ls({ include_hidden = true })
      assert_eq(type(f), "function")
      local actual = f("", ctx)
      print(string.format("_make_provider_ls-2:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(str.find(actual, "echo") > 0)
      assert_true(str.find(actual, consts.LS) > 0)
      assert_true(str.find(actual, "-lha") > 0)
      assert_true(
        str.find(
          actual,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )
    end)
    it("_make_provider_dummy", function()
      local ctx = file_explorer_cfg._context_maker()
      local f = file_explorer_cfg._make_provider_dummy()
      assert_eq(type(f), "function")
      local actual = f("", ctx)
      print(string.format("_make_provider_dummy-1:%s\n", vim.inspect(actual)))
      assert_true(actual == nil)
    end)
    it("_make_provider", function()
      local ctx = file_explorer_cfg._context_maker()
      local f1 = file_explorer_cfg._make_provider()
      assert_eq(type(f1), "function")
      local actual1 = f1("", ctx)
      print(string.format("_make_provider-1:%s\n", vim.inspect(actual1)))
      assert_eq(type(actual1), "string")
      assert_true(str.find(actual1, "echo") > 0)
      if consts.HAS_LSD then
        assert_true(str.find(actual1, consts.LSD) > 0)
      elseif consts.HAS_EZA then
        assert_true(str.find(actual1, consts.EZA) > 0)
      else
        assert_true(str.find(actual1, consts.LS) > 0)
      end
      assert_true(
        str.find(
          actual1,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )

      local f2 = file_explorer_cfg._make_provider({ include_hidden = true })
      assert_eq(type(f2), "function")
      local actual2 = f2("", ctx)
      print(string.format("_make_provider-2:%s\n", vim.inspect(actual1)))
      assert_eq(type(actual2), "string")
      assert_true(str.find(actual2, "echo") > 0)
      if consts.HAS_LSD then
        assert_true(str.find(actual2, consts.LSD) > 0)
      elseif consts.HAS_EZA then
        assert_true(str.find(actual2, consts.EZA) > 0)
      else
        assert_true(str.find(actual2, consts.LS) > 0)
      end
      assert_true(
        str.find(
          actual2,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )
    end)
    it("_make_directory_previewer with lsd", function()
      local input = "lua/fzfx/config.lua"
      local f = file_explorer_cfg._make_directory_previewer({ lsd = true })
      local actual = f(input)
      assert_eq(type(actual), "table")
      local n = #file_explorer_cfg._DIRECTORY_PREVIEWER_LSD
      for i = 1, n do
        assert_eq(actual[i], file_explorer_cfg._DIRECTORY_PREVIEWER_LSD[i])
      end
      assert_eq(actual[#actual], input)
    end)
    it("_make_directory_previewer with eza", function()
      local input = "lua/fzfx/config.lua"
      local f = file_explorer_cfg._make_directory_previewer({ eza = true })
      local actual = f(input)
      assert_eq(type(actual), "table")
      local n = #file_explorer_cfg._DIRECTORY_PREVIEWER_EZA
      for i = 1, n do
        assert_eq(actual[i], file_explorer_cfg._DIRECTORY_PREVIEWER_EZA[i])
      end
      assert_eq(actual[#actual], input)
    end)
    it("_make_directory_previewer with ls", function()
      local input = "lua/fzfx/config.lua"
      local f = file_explorer_cfg._make_directory_previewer({ ls = true })
      local actual = f(input)
      assert_eq(type(actual), "table")
      local n = #file_explorer_cfg._DIRECTORY_PREVIEWER_LS
      for i = 1, n do
        assert_eq(actual[i], file_explorer_cfg._DIRECTORY_PREVIEWER_LS[i])
      end
      assert_eq(actual[#actual], input)
    end)
    it("_directory_previewer", function()
      local input = "lua/fzfx/config.lua"
      local actual = file_explorer_cfg._directory_previewer(input)
      assert_eq(type(actual), "table")
      if consts.HAS_LSD then
        local n = #file_explorer_cfg._DIRECTORY_PREVIEWER_LSD
        for i = 1, n do
          assert_eq(actual[i], file_explorer_cfg._DIRECTORY_PREVIEWER_LSD[i])
        end
        assert_eq(actual[#actual], input)
      elseif consts.HAS_EZA then
        local n = #file_explorer_cfg._DIRECTORY_PREVIEWER_EZA
        for i = 1, n do
          assert_eq(actual[i], file_explorer_cfg._DIRECTORY_PREVIEWER_EZA[i])
        end
        assert_eq(actual[#actual], input)
      else
        local n = #file_explorer_cfg._DIRECTORY_PREVIEWER_LS
        for i = 1, n do
          assert_eq(actual[i], file_explorer_cfg._DIRECTORY_PREVIEWER_LS[i])
        end
        assert_eq(actual[#actual], input)
      end
    end)
    it("_previewer", function()
      local ctx = file_explorer_cfg._context_maker()
      if consts.HAS_LSD then
        for _, line in ipairs(LSD_LINES) do
          local actual = file_explorer_cfg._previewer(line, ctx)
          if actual ~= nil then
            assert_eq(type(actual), "table")
            assert_true(actual[1] == consts.BAT or actual[1] == "cat" or actual[1] == "lsd")
          end
        end
      elseif consts.HAS_EZA then
        for _, line in ipairs(EZA_LINES) do
          local actual = file_explorer_cfg._previewer(line, ctx)
          if actual ~= nil then
            assert_eq(type(actual), "table")
            assert_true(actual[1] == consts.BAT or actual[1] == "cat" or actual[1] == consts.EZA)
          end
        end
      else
        for _, line in ipairs(LS_LINES) do
          local actual = file_explorer_cfg._previewer(line, ctx)
          if actual ~= nil then
            assert_eq(type(actual), "table")
            assert_true(actual[1] == consts.BAT or actual[1] == "cat" or actual[1] == "ls")
          end
        end
      end
    end)
    it("_cd", function()
      local ctx = file_explorer_cfg._context_maker()
      if consts.HAS_LSD then
        for _, line in ipairs(LSD_LINES) do
          file_explorer_cfg._cd(line, ctx)
        end
      elseif consts.HAS_EZA then
        for _, line in ipairs(EZA_LINES) do
          file_explorer_cfg._cd(line, ctx)
        end
      else
        for _, line in ipairs(LS_LINES) do
          file_explorer_cfg._cd(line, ctx)
        end
      end
      assert_true(true)
    end)
    it("_upper", function()
      local ctx = file_explorer_cfg._context_maker()
      if consts.HAS_LSD then
        for _, line in ipairs(LSD_LINES) do
          file_explorer_cfg._upper(line, ctx)
        end
      elseif consts.HAS_EZA then
        for _, line in ipairs(EZA_LINES) do
          file_explorer_cfg._upper(line, ctx)
        end
      else
        for _, line in ipairs(LS_LINES) do
          file_explorer_cfg._upper(line, ctx)
        end
      end
      assert_true(true)
    end)
  end)
end)
