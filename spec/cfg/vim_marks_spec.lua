local cwd = vim.fn.getcwd()

describe("fzfx.cfg.vim_marks", function()
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
  local tbl = require("fzfx.commons.tbl")
  local num = require("fzfx.commons.num")
  local constants = require("fzfx.lib.constants")
  local contexts = require("fzfx.helper.contexts")
  local fzf_helpers = require("fzfx.detail.fzf_helpers")
  local vim_marks_cfg = require("fzfx.cfg.vim_marks")
  require("fzfx").setup()

  describe("[_parse_mark_command_output_first_line]", function()
    it("test", function()
      local input = "mark line  col file/text"
      local actual = vim_marks_cfg._parse_mark_command_output_first_line(input)
      assert_eq(type(actual), "table")
      assert_eq(actual.mark_pos, 1)
      assert_eq(actual.lineno_pos, str.find(input, "line"))
      assert_eq(actual.col_pos, str.find(input, "col"))
      assert_eq(actual.file_text_pos, str.find(input, "file"))
    end)
  end)
  describe("[_get_vim_marks]", function()
    it("test", function()
      local marks = vim_marks_cfg._get_vim_marks()
      assert_eq(type(marks), "table")
      for _, m in ipairs(marks) do
        assert_eq(type(m), "string")
        assert_true(str.not_empty(m))
      end
    end)
  end)
  describe("[_vim_marks_provider]", function()
    it("test", function()
      local ctx = vim_marks_cfg._vim_marks_context_maker()
      local marks = vim_marks_cfg._vim_marks_provider("", ctx)
      if marks then
        assert_eq(type(marks), "table")
        for _, m in ipairs(marks) do
          assert_eq(type(m), "string")
          assert_true(str.not_empty(m))
        end
      end
    end)
  end)
  describe("[_vim_marks_previewer]", function()
    it("test", function()
      local ctx = vim_marks_cfg._vim_marks_context_maker()
      local marks = ctx.marks
      for i, line in ipairs(marks) do
        local actual = vim_marks_cfg._vim_marks_previewer(line, ctx)
        if actual then
          assert_eq(type(actual), "table")
          for j, act in ipairs(actual) do
            assert_eq(type(act), "string")
          end
          if actual[1] == "echo" then
            assert_eq(#actual, 2)
            assert_eq(type(actual[2]), "string")
            assert_true(string.len(actual[2]) >= 0)
          else
            assert_true(actual[1] == constants.BAT or actual[1] == constants.CAT)
            if constants.HAS_BAT then
              assert_true(str.startswith(actual[2], "--style="))
              assert_true(str.startswith(actual[3], "--theme="))
              assert_eq(actual[4], "--color=always")
              assert_eq(actual[5], "--pager=never")
              assert_true(str.startswith(actual[6], "--highlight-line="))
              assert_eq(actual[7], "--line-range")
            elseif constants.HAS_CAT then
              assert_eq(type(actual[2]), "string")
            end
          end
        end
      end
    end)
  end)
  describe("[_vim_marks_context_maker]", function()
    it("test", function()
      local actual = vim_marks_cfg._vim_marks_context_maker()
      assert_true(tbl.tbl_not_empty(actual))
      assert_true(tbl.list_not_empty(actual.marks))
      for _, m in ipairs(actual.marks) do
        assert_true(str.not_empty(m))
      end
      assert_true(num.ge(actual.mark_pos, 1))
      assert_true(num.ge(actual.lineno_pos, actual.mark_pos))
      assert_true(num.ge(actual.col_pos, actual.lineno_pos))
      assert_true(num.ge(actual.file_text_pos, actual.col_pos))
    end)
  end)
end)
