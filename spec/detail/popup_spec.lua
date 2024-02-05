local cwd = vim.fn.getcwd()

describe("detail.popup", function()
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

  local tables = require("fzfx.commons.tables")
  local strings = require("fzfx.commons.strings")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local popup = require("fzfx.detail.popup")
  require("fzfx").setup()

  local WIN_OPTS = {
    height = 0.85,
    width = 0.85,
    row = 0,
    col = 0,
  }
  describe("[PopupWindowInstances]", function()
    it("_get_instances", function()
      popup._clear_instances()
      assert_eq(type(popup._get_instances()), "table")
      assert_true(tables.tbl_empty(popup._get_instances()))
      local pw = popup.PopupWindow:new(WIN_OPTS, "fzf", {})
      assert_eq(type(popup._get_instances()), "table")
      assert_false(tables.tbl_empty(popup._get_instances()))
      local instances = popup._get_instances()
      for _, p in pairs(instances) do
        assert_eq(p.winnr, pw.winnr)
        assert_eq(p.bufnr, pw.bufnr)
        assert_true(vim.deep_equal(p.window_opts_context, pw.window_opts_context))
        assert_true(vim.deep_equal(p._saved_win_opts, pw._saved_win_opts))
        assert_eq(p._resizing, pw._resizing)
      end
      assert_eq(popup._count_instances(), 1)
    end)
    it("_count_instances", function()
      popup._clear_instances()
      assert_eq(type(popup._get_instances()), "table")
      assert_true(tables.tbl_empty(popup._get_instances()))
      assert_eq(popup._count_instances(), 0)
      local pw = popup.PopupWindow:new(WIN_OPTS, "fzf", {})
      assert_eq(popup._count_instances(), 1)
      pw:close()
      assert_eq(popup._count_instances(), 0)
      local pw1 = popup.PopupWindow:new(WIN_OPTS, "fzf", {})
      local pw2 = popup.PopupWindow:new(WIN_OPTS, "fzf", {})
      assert_eq(popup._count_instances(), 2)
      pw1:close()
      pw2:close()
      assert_eq(popup._count_instances(), 0)
    end)
  end)
  describe("[PopupWindow]", function()
    it("create fzf", function()
      local pw = popup.PopupWindow:new(WIN_OPTS, "fzf", {})
      assert_eq(type(pw), "table")
      assert_eq(type(pw.instance), "table")
    end)
    it("resize fzf", function()
      local pw = popup.PopupWindow:new(WIN_OPTS, "fzf", {})
      pw:resize()
    end)
  end)
  describe("[_make_expect_keys]", function()
    it("make --expect options", function()
      local input = {
        ["ctrl-d"] = function(lines) end,
        ["ctrl-r"] = function(lines) end,
      }
      local actual = popup._make_expect_keys(input)
      assert_eq(type(actual), "table")
      assert_eq(#actual, 2)
      for _, a in ipairs(actual) do
        assert_eq(a[1], "--expect")
        assert_true(a[2] == "ctrl-d" or a[2] == "ctrl-r")
      end
    end)
  end)
  describe("[_merge_fzf_actions]", function()
    it("merge fzf actions", function()
      local input = {
        ["ctrl-d"] = function(lines) end,
        ["ctrl-r"] = function(lines) end,
      }
      local actual = popup._merge_fzf_actions({}, input)
      assert_eq(type(actual), "table")
      assert_eq(#actual, 2)
      for _, a in ipairs(actual) do
        assert_eq(a[1], "--expect")
        assert_true(a[2] == "ctrl-d" or a[2] == "ctrl-r")
      end
      local actual2 = popup._make_expect_keys(input)
      assert_true(vim.deep_equal(actual, actual2))
    end)
  end)
  describe("[_make_fzf_command]", function()
    it("merge fzf command", function()
      local input = {
        ["ctrl-d"] = function(lines) end,
        ["ctrl-r"] = function(lines) end,
      }
      local tmpname = vim.fn.tempname()
      local fzfopts = fzf_helpers.make_fzf_default_opts()
      local actual = popup._make_fzf_command({ fzfopts }, input, tmpname)
      print(string.format("make fzf command:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "string")
      assert_true(string.len(actual) > 0)
      assert_true(strings.startswith(actual, "fzf "))
      assert_eq(strings.find(actual, fzfopts), 5)
      assert_true(strings.find(actual, "--expect") > string.len(fzfopts))
    end)
  end)
end)
