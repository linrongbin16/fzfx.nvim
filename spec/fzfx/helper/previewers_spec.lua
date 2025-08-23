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
  local consts = require("fzfx.lib.constants")
  local previewers_helper = require("fzfx.helper.previewers")
  local conf = require("fzfx.config")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  require("fzfx").setup()

  describe("[_bat_style]", function()
    it("default", function()
      vim.env.BAT_STYLE = nil
      assert_eq(previewers_helper._bat_style(), "--style=numbers,changes")
    end)
    it("overwrite", function()
      vim.env.BAT_STYLE = "full"
      assert_eq(previewers_helper._bat_style(), "--style=full")
    end)
  end)

  describe("[_fzf_preview_window_width]", function()
    it("test", function()
      local actual = previewers_helper._fzf_preview_window_width()
      assert_eq(type(actual), "number")
      assert_true(actual > 0)
    end)
  end)

  describe("[_fzf_preview_window_centered_lineno]", function()
    it("test", function()
      local actual = previewers_helper._fzf_preview_window_half_height()
      assert_eq(type(actual), "number")
      assert_true(actual > 0)
    end)
  end)

  describe("[_fzf_preview_find]", function()
    it("test", function()
      local filename = "README.md"
      local actual = previewers_helper._preview_find(filename)
      assert_eq(type(actual), "table")
      if consts.HAS_BAT then
        local n = #previewers_helper._PREVIEW_BAT
        for i = 1, n do
          assert_eq(actual[i], previewers_helper._PREVIEW_BAT[i])
        end
      else
        local n = #previewers_helper._PREVIEW_CAT
        for i = 1, n do
          assert_eq(actual[i], previewers_helper._PREVIEW_CAT[i])
        end
      end
      assert_eq(actual[#actual - 1], "--")
      assert_eq(actual[#actual], filename)
    end)
  end)

  describe("[fzf_preview_find]", function()
    it("test", function()
      local line = "README.md"
      local actual = previewers_helper.preview_find(line)
      assert_eq(type(actual), "table")
      assert_true(actual[1] == consts.BAT or actual[1] == consts.CAT)
    end)
  end)

  describe("[_preview_grep]", function()
    it("case-1", function()
      local filename = "README.md"
      local lineno = 12
      local actual = previewers_helper._preview_grep(filename, lineno)
      assert_eq(type(actual), "table")
      if consts.HAS_BAT then
        local n = #previewers_helper._PREVIEW_BAT
        for i = 1, n do
          assert_eq(actual[i], previewers_helper._PREVIEW_BAT[i])
        end
        assert_true(tbl.List:copy(actual):some(function(a)
          return a == string.format("--highlight-line=%d", lineno)
        end))
      else
        local n = #previewers_helper._PREVIEW_CAT
        for i = 1, n do
          assert_eq(actual[i], previewers_helper._PREVIEW_CAT[i])
        end
      end
      assert_eq(actual[#actual - 1], "--")
      assert_eq(actual[#actual], filename)
    end)

    it("case-2", function()
      local filename = "README.md"
      local actual = previewers_helper._preview_grep(filename)
      assert_eq(type(actual), "table")
      if consts.HAS_BAT then
        local n = #previewers_helper._PREVIEW_BAT
        for i = 1, n do
          assert_eq(actual[i], previewers_helper._PREVIEW_BAT[i])
        end
        assert_true(tbl.List:copy(actual):none(function(a)
          local p = str.find(a, "--highlight-line=")
          return type(p) == "number" and p > 0
        end))
      else
        local n = #previewers_helper._PREVIEW_CAT
        for i = 1, n do
          assert_eq(actual[i], previewers_helper._PREVIEW_CAT[i])
        end
      end
      assert_eq(actual[#actual - 1], "--")
      assert_eq(actual[#actual], filename)
    end)
  end)

  describe("[preview_grep]", function()
    it("test", function()
      local line = "README.md:1:ok"
      local actual = previewers_helper.preview_grep(line)
      assert_eq(type(actual), "table")
      assert_true(str.endswith(actual[#actual], "README.md"))
    end)
  end)

  describe("[preview_grep_bufnr]", function()
    it("test", function()
      local lines = { "1:1:ok", "2:1: this is the plugin" }
      for i, line in ipairs(lines) do
        local actual = previewers_helper.preview_grep_bufnr(line, make_context())
        assert_eq(type(actual), "table")
        if consts.HAS_BAT then
          local n = #previewers_helper._PREVIEW_BAT
          for j = 1, n do
            assert_eq(actual[j], previewers_helper._PREVIEW_BAT[j])
          end
          assert_true(tbl.List:copy(actual):some(function(a)
            local p = str.find(a, "--highlight-line=")
            return type(p) == "number" and p > 0
          end))
        else
          local n = #previewers_helper._PREVIEW_CAT
          for j = 1, n do
            assert_eq(actual[j], previewers_helper._PREVIEW_CAT[j])
          end
          assert_true(tbl.List:copy(actual):none(function(a)
            local p = str.find(a, "--highlight-line=")
            return type(p) == "number" and p > 0
          end))
        end
        assert_eq(actual[#actual - 1], "--")
        assert_true(str.endswith(actual[#actual], "README.md"))
      end
    end)
  end)

  describe("[fzf_preview_git_commit]", function()
    it("commit", function()
      local lines = {
        "44ee80e 2023-10-11 linrongbin16 (HEAD -> origin/feat_git_status) docs: wording",
        "706e1d6 2023-10-10 linrongbin16 chore",
      }
      for _, line in ipairs(lines) do
        local actual = previewers_helper.preview_git_commit(line)
        assert_eq(type(actual), "string")
        assert_true(str.find(actual, "git show") > 0)
        if consts.HAS_DELTA then
          assert_true(str.find(actual, "delta") > 0)
        else
          assert_true(str.find(actual, "delta") == nil)
        end
      end
    end)
    it("empty", function()
      local lines = {
        "                                | 1:2| fzfx.nvim",
      }
      for _, line in ipairs(lines) do
        local actual = previewers_helper.preview_git_commit(line)
        assert_eq(actual, nil)
      end
    end)
  end)

  describe("[fzf_preview_git_status]", function()
    it("test", function()
      local lines = {
        " M fzfx/config.lua",
        " D fzfx/constants.lua",
        " M fzfx/line_helpers.lua",
        " M ../test/line_helpers_spec.lua",
        "?? ../hello",
      }
      for _, line in ipairs(lines) do
        local actual = previewers_helper.preview_git_status(line)
        assert_eq(type(actual), "string")
        assert_true(str.startswith(actual, "git diff"))
        if consts.HAS_DELTA then
          assert_true(str.find(actual, "delta") > 0)
        else
          assert_true(str.find(actual, "delta") == nil)
        end
      end
    end)
  end)

  describe("[_preview_grep_line_range]", function()
    it("test", function()
      local filename = "lua/fzfx/config.lua"
      local lineno = 135
      local actual = previewers_helper._preview_grep_line_range(filename, lineno)
      print(string.format("_preview_grep_line_range:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      if consts.HAS_BAT then
        local n = #previewers_helper._PREVIEW_BAT
        for i = 1, n do
          assert_eq(actual[i], previewers_helper._PREVIEW_BAT[i])
        end
        assert_true(tbl.List:copy(actual):some(function(a)
          return a == string.format("--highlight-line=%d", lineno)
        end))
        assert_true(tbl.List:copy(actual):some(function(a)
          return a == "--line-range"
        end))
      else
        local n = #previewers_helper._PREVIEW_CAT
        for i = 1, n do
          assert_eq(actual[i], previewers_helper._PREVIEW_CAT[i])
        end
        assert_true(tbl.List:copy(actual):none(function(a)
          return a == string.format("--highlight-line=%d", lineno)
        end))
        assert_true(tbl.List:copy(actual):none(function(a)
          return a == "--line-range"
        end))
      end
      assert_eq(actual[#actual - 1], "--")
      assert_true(str.endswith(actual[#actual], "config.lua"))
    end)
  end)
end)
