---@diagnostic disable: undefined-field, unused-local, missing-fields, need-check-nil, param-type-mismatch, assign-type-mismatch
local cwd = vim.fn.getcwd()

describe("helper.providers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local function make_default_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  local tbls = require("fzfx.lib.tables")
  local consts = require("fzfx.lib.constants")
  local strs = require("fzfx.lib.strings")
  local paths = require("fzfx.lib.paths")
  local colors = require("fzfx.lib.colors")

  local conf = require("fzfx.config")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  conf.setup()

  describe("[files]", function()
    it("_bat_style_theme default", function()
      vim.env.BAT_STYLE = nil
      vim.env.BAT_THEME = nil
      local style, theme = conf._bat_style_theme()
      assert_eq(style, "numbers,changes")
      assert_eq(theme, "base16")
    end)
    it("_default_bat_style_theme overwrites", function()
      vim.env.BAT_STYLE = "numbers,changes,headers"
      vim.env.BAT_THEME = "zenburn"
      local style, theme = conf._default_bat_style_theme()
      assert_eq(style, vim.env.BAT_STYLE)
      assert_eq(theme, vim.env.BAT_THEME)
      vim.env.BAT_STYLE = nil
      vim.env.BAT_THEME = nil
    end)
    it("_make_file_previewer", function()
      local f = conf._make_file_previewer("lua/fzfx/config.lua", 135)
      assert_eq(type(f), "function")
      local actual = f()
      -- print(
      --     string.format("make file previewer:%s\n", vim.inspect(actual))
      -- )
      if actual[1] == "bat" then
        assert_eq(actual[1], "bat")
        assert_eq(actual[2], "--style=numbers,changes")
        assert_eq(actual[3], "--theme=base16")
        assert_eq(actual[4], "--color=always")
        assert_eq(actual[5], "--pager=never")
        assert_eq(actual[6], "--highlight-line=135")
        assert_eq(actual[7], "--")
        assert_eq(actual[8], "lua/fzfx/config.lua")
      else
        assert_eq(actual[1], "cat")
        assert_eq(actual[2], "lua/fzfx/config.lua")
      end
    end)
    it("_file_previewer", function()
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      for _, line in ipairs(lines) do
        local actual = conf._file_previewer(line)
        print(string.format("file previewer:%s\n", vim.inspect(actual)))
        if actual[1] == "bat" then
          assert_eq(actual[1], "bat")
          assert_eq(actual[2], "--style=numbers,changes")
          assert_eq(actual[3], "--theme=base16")
          assert_eq(actual[4], "--color=always")
          assert_eq(actual[5], "--pager=never")
          assert_eq(actual[6], "--")
          assert_eq(actual[7], paths.normalize(line, { expand = true }))
        else
          assert_eq(actual[1], "cat")
          assert_eq(actual[2], paths.normalize(line, { expand = true }))
        end
      end
    end)
  end)
  describe("[live_grep]", function()
    it("_make_live_grep_provider restricted", function()
      local f = conf._make_live_grep_provider()
      local actual = f("hello", {})
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if actual[1] == "rg" then
        assert_eq(actual[1], "rg")
        assert_eq(actual[2], "--column")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "--no-heading")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "-H")
        assert_eq(actual[7], "-S")
        assert_eq(actual[8], "hello")
      else
        assert_eq(actual[1], consts.GREP)
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "-H")
        assert_eq(actual[5], "-r")
        assert_eq(
          actual[6],
          "--exclude-dir=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]])
        )
        assert_eq(
          actual[7],
          "--exclude=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]])
        )
        assert_eq(actual[8], "hello")
      end
    end)
    it("_file_previewer_grep", function()
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:2",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:3",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:5",
      }
      for _, line in ipairs(lines) do
        local actual = conf._file_previewer_grep(line)
        local expect =
          paths.normalize(strs.split(line, ":")[1], { expand = true })
        print(string.format("normalize:%s\n", vim.inspect(expect)))
        print(string.format("file previewer grep:%s\n", vim.inspect(actual)))
        if actual[1] == "bat" then
          assert_eq(actual[1], "bat")
          assert_eq(actual[2], "--style=numbers,changes")
          assert_eq(actual[3], "--theme=base16")
          assert_eq(actual[4], "--color=always")
          assert_eq(actual[5], "--pager=never")
          assert_true(strs.startswith(actual[6], "--highlight-line"))
          assert_eq(actual[7], "--")
          assert_true(strs.startswith(actual[8], expect))
        else
          assert_eq(actual[1], "cat")
          assert_eq(actual[2], expect)
        end
      end
    end)
    it("_make_live_grep_provider unrestricted", function()
      local f = conf._make_live_grep_provider({ unrestricted = true })
      local actual = f("hello", {})
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if actual[1] == "rg" then
        assert_eq(actual[1], "rg")
        assert_eq(actual[2], "--column")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "--no-heading")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "-H")
        assert_eq(actual[7], "-S")
        assert_eq(actual[8], "-uu")
        assert_eq(actual[9], "hello")
      else
        assert_eq(actual[1], consts.GREP)
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "-H")
        assert_eq(actual[5], "-r")
        assert_eq(actual[6], "hello")
      end
    end)
    it("_make_live_grep_provider buffer", function()
      local f = conf._make_live_grep_provider({ buffer = true })
      local actual = f("hello", make_default_context())
      -- print(string.format("live grep provider:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if actual[1] == "rg" then
        assert_eq(actual[1], "rg")
        assert_eq(actual[2], "--column")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "--no-heading")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "-H")
        assert_eq(actual[7], "-S")
        assert_eq(actual[8], "-uu")
        assert_eq(actual[9], "hello")
        assert_eq(actual[10], "README.md")
      else
        assert_eq(actual[1], consts.GREP)
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "-H")
        assert_eq(actual[5], "-r")
        assert_eq(actual[6], "hello")
        assert_eq(actual[7], "README.md")
      end
    end)
  end)
end)
