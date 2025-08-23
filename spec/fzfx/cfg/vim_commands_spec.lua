local cwd = vim.fn.getcwd()

describe("fzfx.cfg.vim_commands", function()
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
  local tbl = require("fzfx.commons.tbl")
  local consts = require("fzfx.lib.constants")
  local vim_commands_cfg = require("fzfx.cfg.vim_commands")
  -- require("fzfx").setup()

  describe("[commands]", function()
    local OUTPUT_LINES = vim_commands_cfg._get_commands_output_in_lines()
    it("_parse_ex_command_name", function()
      local lines = {
        "|:|",
        "|:next|",
        "|:FzfxGBranches|",
      }
      for _, line in ipairs(lines) do
        local actual = vim_commands_cfg._parse_ex_command_name(line)
        local expect = vim.trim(line:sub(3, #line - 1))
        assert_eq(actual, expect)
      end
    end)
    it("_get_ex_commands", function()
      local actual = vim_commands_cfg._get_ex_commands()
      local expects = {
        "next",
        "bnext",
        "bprevious",
      }
      assert_eq(type(actual), "table")
      for _, expect in ipairs(expects) do
        local a = actual[expect]
        assert_eq(type(a), "table")
        assert_eq(a.name, expect)
        assert_true(vim.fn.filereadable(vim.fn.expand(a.loc.filename)) > 0)
        assert_true(tonumber(a.loc.lineno) > 0)
      end
    end)
    it("_is_ex_command_output_header", function()
      local line = "Name              Args Address Complete    Definition"
      local actual1 = vim_commands_cfg._is_ex_command_output_header("asdf")
      local actual2 = vim_commands_cfg._is_ex_command_output_header(line)
      assert_false(actual1)
      assert_true(actual2)
    end)
    it("_parse_ex_command_output_as_header", function()
      local line = "Name              Args Address Complete    Definition"
      local actual3 = vim_commands_cfg._parse_ex_command_output_as_header(line)
      assert_eq(type(actual3), "table")
      assert_eq(actual3.name_pos, 1)
      assert_eq(actual3.args_pos, str.find(line, "Args"))
      assert_eq(actual3.address_pos, str.find(line, "Address"))
      assert_eq(actual3.complete_pos, str.find(line, "Complete"))
      assert_eq(actual3.definition_pos, str.find(line, "Definition"))
    end)
    it("_parse_ex_command_output_as_lua_function", function()
      local header = "Name              Args Address Complete    Definition"
      local successes = {
        "    Barbecue          ?            <Lua function> <Lua 437: ~/.config/nvim/lazy/barbecue/lua/barbecue.lua:18>",
        "    BufferLineCloseLeft 0                      <Lua 329: ~/.config/nvim/lazy/bufferline.nvim/lua/bufferline.lua:226>",
        "    BufferLineCloseRight 0                     <Lua 328: ~/.config/nvim/lazy/bufferline.nvim/lua/bufferline.lua:225>",
        "!   FzfxBuffers       ?            file        <Lua 744: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>",
        "!   FzfxBuffersP      0                        <Lua 742: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>",
        "!   FzfxBuffersV      0    .                   <Lua 358: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>",
      }
      local failures = {
        "                                               Run subcommands through this general command",
        '!   Bdelete           ?            buffer      :call s:bdelete("bdelete", <q-bang>, <q-args>)',
        '!   Bwipeout          ?            buffer      :call s:bdelete("bwipeout", <q-bang>, <q-args>)',
        "    DoMatchParen      0                        call matchup#matchparen#toggle(1)",
        "!|  Explore           *    0c ?    dir         call netrw#Explore(<count>,0,0+<bang>0,<q-args>)",
        "!   FZF               *            dir         call s:cmd(<bang>0, <f-args>)",
        "                                               Find buffers",
        "                                               Find buffers by yank text",
      }
      local def_pos = str.find(header, "Definition")
      for _, line in ipairs(successes) do
        local actual = vim_commands_cfg._parse_ex_command_output_as_lua_function(line, def_pos)
        assert_eq(type(actual), "table")
        assert_true(string.len(actual.filename) > 0)
        assert_true(string.len(vim.fn.expand(actual.filename)) > 0)
        assert_true(tonumber(actual.lineno) > 0)
      end
      for _, line in ipairs(failures) do
        local actual = vim_commands_cfg._parse_ex_command_output_as_lua_function(line, def_pos)
        assert_true(actual == nil)
      end
    end)
    it("_get_commands_output_in_lines", function()
      local actual = vim_commands_cfg._get_commands_output_in_lines()
      assert_eq(type(actual), "table")
      for _, a in ipairs(actual) do
        assert_eq(type(a), "string")
        assert_true(string.len(a) >= 0)
      end
    end)
    it("_parse_ex_command_output", function()
      local actual = vim_commands_cfg._parse_ex_command_output(OUTPUT_LINES)
      -- print(string.format("_parse_ex_command_output:%s\n", vim.inspect(actual)))
      for k, v in pairs(actual) do
        assert_true(vim.fn.exists(":" .. k) > 0)
        assert_eq(type(v.filename), "string")
        assert_true(string.len(v.filename) > 0)
        assert_eq(type(v.lineno), "number")
        assert_true(v.lineno >= 0)
      end
    end)
    it("_get_user_commands", function()
      local actual = vim_commands_cfg._get_user_commands(OUTPUT_LINES)
      for k, v in pairs(actual) do
        assert_true(vim.fn.exists(":" .. k) > 0)
        if type(v.loc) == "table" then
          assert_eq(type(v.loc.filename), "string")
          assert_true(string.len(v.loc.filename) > 0)
          assert_eq(type(v.loc.lineno), "number")
          assert_true(v.loc.lineno >= 0)
        end
      end
    end)
    it("_get_commands", function()
      local ctx = vim_commands_cfg._context_maker()
      local actual1 =
        vim_commands_cfg._get_commands(ctx, { ex_commands = true, user_commands = true })
      local actual2 = vim_commands_cfg._get_commands(ctx, { ex_commands = true })
      local actual3 = vim_commands_cfg._get_commands(ctx, { user_commands = true })

      assert_eq(type(actual1), "table")
      assert_eq(type(actual2), "table")
      assert_eq(type(actual3), "table")
      assert_eq(#actual1, #actual2 + #actual3)
    end)
    it("_calculate_column_widths", function()
      local commands = {
        {
          name = "FzfxGBranches",
          opts = { bang = true, bar = true },
        },
        {
          name = "bnext",
          opts = {
            bang = false,
            bar = false,
            nargs = "*",
            range = ".",
            complete = "<Lua function>",
          },
        },
      }
      local name_actual, opts_actual = vim_commands_cfg._calculate_column_widths(commands)
      assert_eq(name_actual, string.len(commands[1].name))
      assert_eq(opts_actual, string.len("Bang|Bar|Nargs|Range|Complete"))
    end)
    it("_render_header", function()
      local actual1 = vim_commands_cfg._render_header({
        opts = { bang = true, bar = true },
      })
      assert_eq(actual1, "Y   |Y  |N/A  |N/A  |N/A")
      local actual2 = vim_commands_cfg._render_header({
        opts = {
          bang = false,
          bar = false,
          nargs = "*",
          range = ".",
          complete = "<Lua function>",
        },
      })
      assert_eq(actual2, "N   |N  |*    |.    |<Lua>")
    end)
    it("_render_desc_or_location", function()
      local inputs = {
        { loc = { filename = "filename", lineno = 1 } },
        { opts = { desc = "desc" } },
      }
      local expects = {
        "filename:1",
        '"desc"',
      }
      for i, input in ipairs(inputs) do
        local actual = vim_commands_cfg._render_desc_or_location(input)
        local expect = expects[i]
        assert_true(str.find(actual, expect) > 0)
      end

      local input2 = {}
      local actual2 = vim_commands_cfg._render_desc_or_location(input2)
      assert_eq(actual2, "")
    end)
    -- it("_render_lines", function()
    --   local ctx = vim_commands_cfg._context_maker()
    --   local opts = {
    --     { ex_commands = true, user_commands = true },
    --     { ex_commands = true },
    --     { user_commands = true },
    --   }
    --   local expect_commands = {
    --     { "FzfxGBranches", "FzfxLiveGrep", "bnext", "bprevious" },
    --     { "bnext", "bprevious" },
    --     { "FzfxGBranches", "FzfxLiveGrep" },
    --   }
    --
    --   for i, opt in ipairs(opts) do
    --     local commands = vim_commands_cfg._get_commands(ctx, opt)
    --     local actual = vim_commands_cfg._render_lines(commands, ctx)
    --     assert_eq(type(actual), "table")
    --     assert_true(#actual >= 0)
    --
    --     local header = actual[1]
    --     assert_true(str.startswith(header, "Name"))
    --     assert_true(str.endswith(header, "Definition/Location"))
    --
    --     for _, expect in ipairs(expect_commands[i]) do
    --       assert_true(tbl.List
    --         :copy(actual)
    --         :filter(function(_, j)
    --           return j > 1
    --         end)
    --         :some(function(a)
    --           local result = str.find(a, expect)
    --           return type(result) == "number" and result > 0
    --         end))
    --     end
    --   end
    -- end)
  end)
  describe("[context]", function()
    it("_context_maker", function()
      local ctx = vim_commands_cfg._context_maker()
      -- print(string.format("vim commands context:%s\n", vim.inspect(ctx)))
      assert_true(ctx.bufnr > 0)
      assert_true(ctx.winnr > 0)
      assert_true(ctx.tabnr > 0)
      assert_eq(type(ctx.output_lines), "table")
      assert_true(#ctx.output_lines > 0)
    end)
  end)
  describe("[_previewer]", function()
    it("test", function()
      local ctx = vim_commands_cfg._context_maker()
      local commands =
        vim_commands_cfg._get_commands(ctx, { ex_commands = true, user_commands = true })
      local rendered_lines = vim_commands_cfg._render_lines(commands, ctx)

      local n = #rendered_lines
      local i = 2
      while i <= n do
        local line = rendered_lines[i]
        local actual = vim_commands_cfg._previewer(line, ctx) --[[@as string[] ]]
        local vc = commands[i - 1]
        assert_eq(type(actual), "table")
        assert_eq(type(vc), "table")
        print(
          string.format(
            "_previewer-%d, vc:%s, actual:%s\n",
            i,
            vim.inspect(vc),
            vim.inspect(actual)
          )
        )
        if vim_commands_cfg._is_location(vc) then
          if consts.HAS_BAT then
            assert_true(tbl.List:copy(actual):some(function(a)
              return a == consts.BAT
            end))
          else
            assert_true(tbl.List:copy(actual):some(function(a)
              return a == consts.CAT
            end))
          end
        else
          assert_true(vim_commands_cfg._is_description(vc))
          assert_true(tbl.List:copy(actual):some(function(a)
            return a == consts.ECHO
          end))
        end
        i = i + 1
      end
    end)
  end)
end)
