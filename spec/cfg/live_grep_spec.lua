local cwd = vim.fn.getcwd()

describe("fzfx.cfg.live_grep", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.o.swapfile = false
    vim.cmd([[noautocmd edit README.md]])
  end)

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  require("fzfx").setup()
  local consts = require("fzfx.lib.constants")
  local contexts = require("fzfx.helper.contexts")
  local live_grep_cfg = require("fzfx.cfg.live_grep")

  describe("[_make_provider]", function()
    it("_make_provider restricted", function()
      local f = live_grep_cfg._make_provider()
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
        assert_eq(actual[6], "--exclude-dir=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]]))
        assert_eq(actual[7], "--exclude=" .. (consts.HAS_GNU_GREP and [[.*]] or [[./.*]]))
        assert_eq(actual[8], "hello")
      end
    end)
    it("_make_provider unrestricted", function()
      local f = live_grep_cfg._make_provider({ unrestricted = true })
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
    it("_make_provider buffer", function()
      local f = live_grep_cfg._make_provider({ buffer = true })
      local actual = f("hello", contexts.make_pipeline_context())
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
