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

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local str = require("fzfx.commons.str")
  local path = require("fzfx.commons.path")

  local constants = require("fzfx.lib.constants")

  local contexts = require("fzfx.helper.contexts")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")

  local file_explorer_cfg = require("fzfx.cfg.file_explorer")

  require("fzfx").setup()

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
    it("_make_provider", function()
      local ctx = file_explorer_cfg._context_maker()
      local f1 = file_explorer_cfg._make_provider("-lh")
      assert_eq(type(f1), "function")
      local actual1 = f1("", ctx)
      -- print(
      --     string.format(
      --         "file explorer provider1:%s\n",
      --         vim.inspect(actual1)
      --     )
      -- )
      assert_eq(type(actual1), "string")
      assert_true(str.find(actual1, "echo") > 0)
      assert_true(
        type(str.find(actual1, "eza")) == "number" or type(str.find(actual1, "ls")) == "number"
      )
      assert_true(
        str.find(
          actual1,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )
      local f2 = file_explorer_cfg._make_provider("-lha")
      assert_eq(type(f2), "function")
      local actual2 = f2("", ctx)
      -- print(
      --     string.format(
      --         "file explorer provider2:%s\n",
      --         vim.inspect(actual2)
      --     )
      -- )
      assert_eq(type(actual2), "string")
      assert_true(str.find(actual2, "echo") > 0)
      assert_true(
        type(str.find(actual2, "eza")) == "number" or type(str.find(actual2, "ls")) == "number"
      )
      assert_true(
        str.find(
          actual2,
          path.normalize(vim.fn.getcwd(), { double_backslash = true, expand = true })
        ) > 0
      )
    end)
    it("_directory_previewer", function()
      local actual = file_explorer_cfg._directory_previewer("lua/fzfx/config.lua")
      assert_eq(type(actual), "table")
      if actual[1] == "lsd" then
        assert_eq(actual[1], "lsd")
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-lha")
        assert_eq(actual[4], "--header")
        assert_eq(actual[5], "--")
        assert_eq(actual[6], "lua/fzfx/config.lua")
      else
        assert_true(actual[1] == "eza" or actual[1] == "ls")
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-lha")
        assert_eq(actual[4], "--")
        assert_eq(actual[5], "lua/fzfx/config.lua")
      end
    end)
    it("_previewer", function()
      local ctx = file_explorer_cfg._context_maker()
      if constants.HAS_LSD then
        for _, line in ipairs(LSD_LINES) do
          local actual = file_explorer_cfg._previewer(line, ctx)
          if actual ~= nil then
            assert_eq(type(actual), "table")
            assert_true(actual[1] == constants.BAT or actual[1] == "cat" or actual[1] == "lsd")
          end
        end
      elseif constants.HAS_EZA then
        for _, line in ipairs(EZA_LINES) do
          local actual = file_explorer_cfg._previewer(line, ctx)
          if actual ~= nil then
            assert_eq(type(actual), "table")
            assert_true(
              actual[1] == constants.BAT or actual[1] == "cat" or actual[1] == constants.EZA
            )
          end
        end
      else
        for _, line in ipairs(LS_LINES) do
          local actual = file_explorer_cfg._previewer(line, ctx)
          if actual ~= nil then
            assert_eq(type(actual), "table")
            assert_true(actual[1] == constants.BAT or actual[1] == "cat" or actual[1] == "ls")
          end
        end
      end
    end)
    it("_cd_file_explorer", function()
      local ctx = file_explorer_cfg._context_maker()
      if constants.HAS_LSD then
        for _, line in ipairs(LSD_LINES) do
          local actual = file_explorer_cfg._cd_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      elseif constants.HAS_EZA then
        for _, line in ipairs(EZA_LINES) do
          local actual = file_explorer_cfg._cd_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      else
        for _, line in ipairs(LS_LINES) do
          local actual = file_explorer_cfg._cd_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      end
    end)
    it("_upper_file_explorer", function()
      local ctx = file_explorer_cfg._context_maker()
      if constants.HAS_LSD then
        for _, line in ipairs(LSD_LINES) do
          local actual = file_explorer_cfg._upper_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      elseif constants.HAS_EZA then
        for _, line in ipairs(EZA_LINES) do
          local actual = file_explorer_cfg._upper_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      else
        for _, line in ipairs(LS_LINES) do
          local actual = file_explorer_cfg._upper_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      end
    end)
  end)
end)
