local cwd = vim.fn.getcwd()

describe("helper.previewers", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.env._FZFX_NVIM_DEVICONS_PATH = nil
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local function make_context()
    return {
      bufnr = vim.api.nvim_get_current_buf(),
      winnr = vim.api.nvim_get_current_win(),
      tabnr = vim.api.nvim_get_current_tabpage(),
    }
  end

  local tbl = require("fzfx.commons.tbl")
  local str = require("fzfx.commons.str")
  local path = require("fzfx.commons.path")
  local constants = require("fzfx.lib.constants")
  local previewers = require("fzfx.helper.previewers")
  local conf = require("fzfx.config")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  require("fzfx").setup()

  describe("[_bat_style_theme]", function()
    if constants.HAS_BAT then
      it("default", function()
        vim.env.BAT_STYLE = nil
        vim.env.BAT_THEME = nil
        local style, theme = previewers._bat_style_theme()
        assert_eq(style, "numbers,changes")
        assert_eq(type(theme), "string")
      end)
      it("overwrites", function()
        vim.env.BAT_STYLE = "numbers,changes,headers"
        vim.env.BAT_THEME = "zenburn"
        local style, theme = previewers._bat_style_theme()
        assert_eq(style, vim.env.BAT_STYLE)
        assert_eq(theme, vim.env.BAT_THEME)
        vim.env.BAT_STYLE = nil
        vim.env.BAT_THEME = nil
      end)
    end
  end)

  describe("[preview_files]", function()
    it("test", function()
      local actual = previewers.preview_files("lua/fzfx/config.lua", 135)
      -- print(
      --     string.format("make file previewer:%s\n", vim.inspect(actual))
      -- )
      if actual[1] == constants.BAT then
        assert_eq(actual[1], constants.BAT)
        assert_eq(actual[2], "--style=numbers,changes")
        assert_true(str.startswith(actual[3], "--theme="))
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
  end)

  describe("[preview_files_find]", function()
    it("test", function()
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      for i, line in ipairs(lines) do
        local actual = previewers.preview_files_find(line)
        print(string.format("preview_files_find-%s:%s\n", vim.inspect(i), vim.inspect(actual)))
        if actual[1] == constants.BAT then
          assert_eq(actual[1], constants.BAT)
          assert_eq(actual[2], "--style=numbers,changes")
          assert_true(str.startswith(actual[3], "--theme="))
          assert_eq(actual[4], "--color=always")
          assert_eq(actual[5], "--pager=never")
          assert_eq(actual[6], "--")
          assert_eq(actual[7], path.normalize(line, { double_backslash = true, expand = true }))
        else
          assert_eq(actual[1], "cat")
          assert_eq(actual[2], path.normalize(line, { double_backslash = true, expand = true }))
        end
      end
    end)
  end)

  describe("[buffer_preview_files_find]", function()
    it("test", function()
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt",
      }
      for i, line in ipairs(lines) do
        local actual = previewers.buffer_preview_files_find(line)
        print(
          string.format("buffer_preview_files_find-%s:%s\n", vim.inspect(i), vim.inspect(actual))
        )
        assert_eq(type(actual), "table")
        assert_true(str.endswith(path.normalize(line, { expand = true }), actual.filename))
      end
    end)
  end)

  describe("[preview_files_grep]", function()
    it("test", function()
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:2",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:3",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:4",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:5",
      }
      for _, line in ipairs(lines) do
        local actual = previewers.preview_files_grep(line)
        local expect =
          path.normalize(str.split(line, ":")[1], { double_backslash = true, expand = true })
        print(string.format("normalize:%s\n", vim.inspect(expect)))
        print(string.format("file previewer grep:%s\n", vim.inspect(actual)))
        if actual[1] == constants.BAT then
          assert_eq(actual[1], constants.BAT)
          assert_eq(actual[2], "--style=numbers,changes")
          assert_true(str.startswith(actual[3], "--theme="))
          assert_eq(actual[4], "--color=always")
          assert_eq(actual[5], "--pager=never")
          assert_true(str.startswith(actual[6], "--highlight-line"))
          assert_eq(actual[7], "--")
          assert_true(str.startswith(actual[8], expect))
        else
          assert_eq(actual[1], "cat")
          assert_eq(actual[2], expect)
        end
      end
    end)
  end)

  describe("[preview_files_grep_no_filename]", function()
    it("test", function()
      local lines = {
        "1",
        "2:1",
        "3:hello",
        "4:  local i = 1",
      }
      for _, line in ipairs(lines) do
        local ctx = make_context()
        local actual = previewers.preview_files_grep_no_filename(line, ctx)
        local expect =
          path.normalize(str.split(line, ":")[1], { double_backslash = true, expand = true })
        print(string.format("normalize:%s\n", vim.inspect(expect)))
        print(string.format("file previewer grep:%s\n", vim.inspect(actual)))
        if actual[1] == constants.BAT then
          assert_eq(actual[1], constants.BAT)
          assert_eq(actual[2], "--style=numbers,changes")
          assert_true(str.startswith(actual[3], "--theme="))
          assert_eq(actual[4], "--color=always")
          assert_eq(actual[5], "--pager=never")
          assert_true(str.startswith(actual[6], "--highlight-line"))
          assert_eq(actual[7], "--line-range")
          assert_eq(actual[9], "--")
        else
          assert_eq(actual[1], "cat")
        end
      end
    end)
  end)

  describe("[buffer_preview_files_grep_no_filename]", function()
    it("test", function()
      local lines = {
        "1",
        "2:1",
        "3:hello",
        "4:  local i = 1",
      }
      local ctx = make_context()
      local filename = vim.api.nvim_buf_get_name(ctx.bufnr)
      filename = path.normalize(filename, { double_backslash = true, expand = true })

      for _, line in ipairs(lines) do
        local actual = previewers.buffer_preview_files_grep_no_filename(line, ctx)
        print(string.format("filename:%s\n", vim.inspect(filename)))
        print(string.format("file previewer grep:%s\n", vim.inspect(actual)))
        local splits = str.split(line, ":")
        if actual then
          assert_eq(actual.filename, filename)
          assert_eq(actual.lineno, tonumber(splits[1]))
        end
      end
    end)
  end)

  describe("[get_preview_window_width]", function()
    it("test", function()
      local actual = previewers.get_preview_window_width()
      assert_eq(type(actual), "number")
      assert_true(actual >= 3)
    end)
  end)

  describe("[preview_git_commit]", function()
    it("_make_preview_git_commit", function()
      local lines = {
        "44ee80e",
        "706e1d6",
      }
      for _, line in ipairs(lines) do
        local actual = previewers._make_preview_git_commit(line)
        if actual ~= nil then
          assert_eq(type(actual), "string")
          assert_true(str.find(actual, "git show") > 0)
          if vim.fn.executable("delta") > 0 then
            assert_true(str.find(actual, "delta") > 0)
          else
            assert_true(str.find(actual, "delta") == nil)
          end
        end
      end
    end)

    it("preview_git_commit", function()
      local lines = {
        "44ee80e 2023-10-11 linrongbin16 (HEAD -> origin/feat_git_status) docs: wording",
        "706e1d6 2023-10-10 linrongbin16 chore",
        "                                | 1:2| fzfx.nvim",
      }
      for _, line in ipairs(lines) do
        local actual = previewers.preview_git_commit(line)
        if actual ~= nil then
          assert_eq(type(actual), "string")
          assert_true(str.find(actual, "git show") > 0)
          if vim.fn.executable("delta") > 0 then
            assert_true(str.find(actual, "delta") > 0)
          else
            assert_true(str.find(actual, "delta") == nil)
          end
        end
      end
    end)
  end)

  describe("[preview_files_with_line_range]", function()
    it("test", function()
      local actual = previewers.preview_files_with_line_range("lua/fzfx/config.lua", 135)
      assert_eq(type(actual), "table")
      print(string.format("preview_files_with_line_range:%s\n", vim.inspect(actual)))
      if actual[1] == constants.BAT then
        assert_eq(actual[1], constants.BAT)
        assert_eq(actual[2], "--style=numbers,changes")
        assert_true(str.startswith(actual[3], "--theme="))
        assert_eq(actual[4], "--color=always")
        assert_eq(actual[5], "--pager=never")
        assert_eq(actual[6], "--highlight-line=135")
        assert_true(str.startswith(actual[7], "--line-range"))
        assert_true(str.endswith(actual[8], ":"))
        assert_eq(actual[9], "--")
        assert_eq(actual[10], "lua/fzfx/config.lua")
      else
        assert_eq(actual[1], "cat")
        assert_eq(actual[2], "lua/fzfx/config.lua")
      end
    end)
  end)

  describe("[buffer_preview_files_grep]", function()
    it("test", function()
      local lines = {
        "~/github/linrongbin16/fzfx.nvim/README.md:1:3:hello world",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx.lua:3:7: hello",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua:8:9324",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/goodbye world/goodbye.lua:2:81",
        "~/github/linrongbin16/fzfx.nvim/lua/fzfx/test/hello world.txt:8: hello",
      }
      for i, line in ipairs(lines) do
        local actual = previewers.buffer_preview_files_grep(line)
        print(
          string.format("buffer_preview_files_grep-%s:%s\n", vim.inspect(i), vim.inspect(actual))
        )
        assert_eq(type(actual), "table")
        local splits = str.split(line, ":")
        assert_true(str.endswith(path.normalize(splits[1], { expand = true }), actual.filename))
        assert_eq(tonumber(splits[2]), actual.lineno)
      end
    end)
  end)
end)
