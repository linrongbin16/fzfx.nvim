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
  local constants = require("fzfx.lib.constants")
  local contexts = require("fzfx.helper.contexts")
  local providers = require("fzfx.helper.providers")
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
end)
