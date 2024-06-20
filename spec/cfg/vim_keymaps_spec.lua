local cwd = vim.fn.getcwd()

describe("fzfx.cfg.vim_keymaps", function()
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
  local vim_keymaps_cfg = require("fzfx.cfg.vim_keymaps")
  require("fzfx").setup()

  describe("[keymaps]", function()
    local CONTEXT = vim_keymaps_cfg._context_maker()
    it("_get_keymaps_output_in_lines", function()
      local output_lines = vim_keymaps_cfg._get_maps_output_in_lines()
      assert_eq(type(output_lines), "table")
      assert_true(#output_lines > 0)
    end)
    it("_parse_output_line", function()
      local output_lines = vim_keymaps_cfg._get_maps_output_in_lines()
      for i, line in ipairs(output_lines) do
        if str.not_empty(line) then
          local actual = vim_keymaps_cfg._parse_output_line(line)
          print(
            string.format(
              "_parse_output_line-%d, line:%s, actual:%s\n",
              i,
              vim.inspect(line),
              vim.inspect(actual)
            )
          )
          assert_eq(type(actual), "table")
          assert_true(str.not_empty(actual.lhs))
        end
      end
    end)
    it("_make_provider a (all)", function()
      local ctx = vim_keymaps_cfg._context_maker()
      local f = vim_keymaps_cfg._make_provider("a")
      local actual = f("", ctx)
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(#actual >= 0)
        for _, act in ipairs(actual) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) > 0)
        end
      end
    end)
    it("_make_provider n (normal mode)", function()
      local ctx = vim_keymaps_cfg._context_maker()
      local f = vim_keymaps_cfg._make_provider("n")
      local actual = f("", ctx)
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(#actual >= 0)
        for _, act in ipairs(actual) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) > 0)
        end
      end
    end)
    it("_make_provider i (insert mode)", function()
      local ctx = vim_keymaps_cfg._context_maker()
      local f = vim_keymaps_cfg._make_provider("i")
      local actual = f("", ctx)
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(#actual >= 0)
        for _, act in ipairs(actual) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) > 0)
        end
      end
    end)
    it("_make_provider v (visual mode)", function()
      local ctx = vim_keymaps_cfg._context_maker()
      local f = vim_keymaps_cfg._make_provider("v")
      local actual = f("", ctx)
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(#actual >= 0)
        for _, act in ipairs(actual) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) > 0)
        end
      end
    end)
    it("_get_vim_keymaps", function()
      local actual = vim_keymaps_cfg._get_vim_keymaps(CONTEXT.output_lines)
      -- print(string.format("vim keymaps:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      assert_true(#actual >= 0)
      for _, act in ipairs(actual) do
        assert_eq(type(act), "table")
        assert_eq(type(act.lhs), "string")
        assert_true(string.len(act.lhs) > 0)
        assert_eq(type(act.mode), "string")
        assert_true(string.len(act.mode) == 1)
      end
    end)
    it("_render_header", function()
      local actual1 = vim_keymaps_cfg._render_header({
        lhs = "#",
        mode = "n",
        noremap = true,
        nowait = false,
        silent = false,
      })
      assert_eq(actual1, "n   |Y      |N     |N     ")
    end)
    it("_calculate_columns_widths", function()
      local keymaps = {
        {
          lhs = "#",
          mode = "n",
          noremap = true,
          nowait = false,
          silent = false,
        },
      }
      local actual1, actual2 = vim_keymaps_cfg._calculate_columns_widths(keymaps)
      assert_eq(actual1, math.max(string.len(keymaps[1].lhs), string.len("Lhs")))
      assert_eq(actual2, string.len("Mode|Noremap|Nowait|Silent"))
    end)
    it("_render_lines", function()
      local keymaps = vim_keymaps_cfg._get_vim_keymaps(CONTEXT.output_lines)
      local lhs_width, opts_width = vim_keymaps_cfg._calculate_columns_widths(keymaps)
      local actual = vim_keymaps_cfg._render_lines(keymaps, lhs_width, opts_width)
      -- print(string.format("render vim keymaps:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      assert_true(#actual >= 1)
      assert_true(str.startswith(actual[1], "Key"))
      assert_true(str.endswith(actual[1], "Definition/Location"))
      for i = 2, #actual do
        assert_true(string.len(actual[i]) > 0)
      end
    end)
    it("_context_maker", function()
      local ctx = vim_keymaps_cfg._context_maker()
      -- print(string.format("vim keymaps context:%s\n", vim.inspect(ctx)))
      assert_eq(type(ctx), "table")
      assert_true(ctx.bufnr > 0)
      assert_true(ctx.winnr > 0)
      assert_true(ctx.tabnr > 0)
      assert_true(ctx.key_column_width > 0)
      assert_true(ctx.opts_column_width > 0)
    end)
    it("_previewer", function()
      local lines = {
        '<C-Tab>                                      o   |Y      |N     |N      "<C-C><C-W>w"',
        "<Plug>(YankyCycleBackward)                   n   |Y      |N     |Y      ~/.config/nvim/lazy/yanky.nvim/lua/yanky.lua:290",
      }
      local ctx = vim_keymaps_cfg._context_maker()
      for _, line in ipairs(lines) do
        local actual = vim_keymaps_cfg._previewer(line, ctx)
        assert_eq(type(actual), "table")
        assert_true(actual[1] == constants.BAT or actual[1] == "cat" or actual[1] == "echo")
      end
    end)
  end)
end)
