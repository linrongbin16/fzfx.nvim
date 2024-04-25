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

  local github_actions = os.getenv("GITHUB_ACTIONS") == "true"

  local str = require("fzfx.commons.str")
  local path = require("fzfx.commons.path")
  local vim_commands_cfg = require("fzfx.cfg.vim_commands")
  require("fzfx").setup()

  describe("[commands]", function()
    it("_parse_vim_ex_command_name", function()
      local lines = {
        "|:|",
        "|:next|",
        "|:FzfxGBranches|",
      }
      for _, line in ipairs(lines) do
        local actual = vim_commands_cfg._parse_vim_ex_command_name(line)
        local expect = vim.trim(line:sub(3, #line - 1))
        assert_eq(actual, expect)
      end
    end)
    it("_get_vim_ex_commands", function()
      local actual = vim_commands_cfg._get_vim_ex_commands()
      assert_eq(type(actual["next"]), "table")
      -- print(
      --     string.format(
      --         "ex command 'next':%s\n",
      --         vim.inspect(actual["next"])
      --     )
      -- )
      assert_eq(actual["next"].name, "next")
      assert_true(vim.fn.filereadable(vim.fn.expand(actual["next"].loc.filename)) > 0)
      assert_true(tonumber(actual["next"].loc.lineno) > 0)
      assert_eq(type(actual["bnext"]), "table")
      -- print(
      --     string.format(
      --         "ex command 'bnext':%s\n",
      --         vim.inspect(actual["bnext"])
      --     )
      -- )
      assert_eq(actual["bnext"].name, "bnext")
      assert_true(vim.fn.filereadable(vim.fn.expand(actual["bnext"].loc.filename)) > 0)
      assert_true(tonumber(actual["bnext"].loc.lineno) > 0)
    end)
    it("_is_ex_command_output_header/_parse_ex_command_output_header", function()
      local line = "Name              Args Address Complete    Definition"
      local actual1 = vim_commands_cfg._is_ex_command_output_header("asdf")
      local actual2 = vim_commands_cfg._is_ex_command_output_header(line)
      assert_false(actual1)
      assert_true(actual2)
      local actual3 = vim_commands_cfg._parse_ex_command_output_header(line)
      assert_eq(type(actual3), "table")
      assert_eq(actual3.name_pos, 1)
      assert_eq(actual3.args_pos, str.find(line, "Args"))
      assert_eq(actual3.address_pos, str.find(line, "Address"))
      assert_eq(actual3.complete_pos, str.find(line, "Complete"))
      assert_eq(actual3.definition_pos, str.find(line, "Definition"))
    end)
    it("_parse_ex_command_output_lua_function_definition", function()
      local header = "Name              Args Address Complete    Definition"
      local success_lines = {
        "    Barbecue          ?            <Lua function> <Lua 437: ~/.config/nvim/lazy/barbecue/lua/barbecue.lua:18>",
        "    BufferLineCloseLeft 0                      <Lua 329: ~/.config/nvim/lazy/bufferline.nvim/lua/bufferline.lua:226>",
        "    BufferLineCloseRight 0                     <Lua 328: ~/.config/nvim/lazy/bufferline.nvim/lua/bufferline.lua:225>",
        "!   FzfxBuffers       ?            file        <Lua 744: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>",
        "!   FzfxBuffersP      0                        <Lua 742: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>",
        "!   FzfxBuffersV      0    .                   <Lua 358: ~/github/linrongbin16/fzfx.nvim/lua/fzfx/general.lua:913>",
      }
      local failed_lines = {
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
      for _, line in ipairs(success_lines) do
        local actual =
          vim_commands_cfg._parse_ex_command_output_lua_function_definition(line, def_pos)
        -- print(
        --     string.format(
        --         "parse ex command lua function:%s\n",
        --         vim.inspect(actual)
        --     )
        -- )
        assert_eq(type(actual), "table")
        assert_true(string.len(actual.filename) > 0)
        assert_true(string.len(vim.fn.expand(actual.filename)) > 0)
        assert_true(tonumber(actual.lineno) > 0)
      end
      for _, line in ipairs(failed_lines) do
        local actual =
          vim_commands_cfg._parse_ex_command_output_lua_function_definition(line, def_pos)
        -- print(
        --     string.format(
        --         "failed to parse ex command lua function:%s\n",
        --         vim.inspect(actual)
        --     )
        -- )
        assert_true(actual == nil)
      end
    end)
    it("_parse_ex_command_output", function()
      local actual = vim_commands_cfg._parse_ex_command_output()
      print(string.format("_parse_ex_command_output:%s\n", vim.inspect(actual)))
      for k, v in pairs(actual) do
        assert_true(vim.fn.exists(":" .. k) > 0)
        assert_eq(type(v.filename), "string")
        assert_true(string.len(v.filename) > 0)
        assert_eq(type(v.lineno), "number")
        assert_true(v.lineno > 0)
      end
    end)
    it("_get_vim_user_commands", function()
      local actual = vim_commands_cfg._get_vim_user_commands()
      print(string.format("_get_vim_user_commands:%s\n", vim.inspect(actual)))
      for k, v in pairs(actual) do
        assert_true(vim.fn.exists(":" .. k) > 0)
        if type(v.loc) == "table" then
          assert_eq(type(v.loc.filename), "string")
          assert_true(string.len(v.loc.filename) > 0)
          assert_eq(type(v.loc.lineno), "number")
          assert_true(v.loc.lineno > 0)
        end
      end
    end)
    it("_render_vim_commands_column_opts", function()
      local actual1 = vim_commands_cfg._render_vim_commands_column_opts({
        opts = { bang = true, bar = true },
      })
      -- print(
      --     string.format(
      --         "render vim command opts1:%s\n",
      --         vim.inspect(actual1)
      --     )
      -- )
      assert_eq(actual1, "Y   |Y  |N/A  |N/A  |N/A")
      local actual2 = vim_commands_cfg._render_vim_commands_column_opts({
        opts = {
          bang = false,
          bar = false,
          nargs = "*",
          range = ".",
          complete = "<Lua function>",
        },
      })
      -- print(
      --     string.format(
      --         "render vim command opts2:%s\n",
      --         vim.inspect(actual2)
      --     )
      -- )
      assert_eq(actual2, "N   |N  |*    |.    |<Lua>")
    end)
    it("_calculate_vim_commands_columns_width", function()
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
      local actual1, actual2 = vim_commands_cfg._calculate_vim_commands_columns_width(commands)
      -- print(
      --     string.format(
      --         "render vim command status:%s, %s\n",
      --         vim.inspect(actual1),
      --         vim.inspect(actual2)
      --     )
      -- )
      assert_eq(actual1, string.len(commands[1].name))
      assert_eq(actual2, string.len("Bang|Bar|Nargs|Range|Complete"))
    end)
    it("_render_vim_commands", function()
      local commands = {
        {
          name = "FzfxGBranches",
          opts = { bang = true, bar = true, desc = "git branches" },
          loc = {
            filename = "~/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
            lineno = 13,
          },
        },
        {
          name = "bnext",
          opts = {
            bang = false,
            bar = false,
            nargs = "*",
            range = ".",
            complete = "<Lua function>",
            desc = "next buffer",
          },
        },
      }
      local name_width, opts_width =
        vim_commands_cfg._calculate_vim_commands_columns_width(commands)
      local actual = vim_commands_cfg._render_vim_commands(commands, name_width, opts_width)
      -- print(
      --     string.format("render vim commands:%s\n", vim.inspect(actual))
      -- )
      assert_eq(type(actual), "table")
      assert_eq(#actual, 3)
      assert_true(str.startswith(actual[1], "Name"))
      assert_true(str.endswith(actual[1], "Definition/Location"))
      assert_true(str.startswith(actual[2], "FzfxGBranches"))
      local expect =
        string.format("%s:%d", path.reduce(commands[1].loc.filename), commands[1].loc.lineno)
      assert_true(str.endswith(actual[2], expect))
      assert_true(str.startswith(actual[3], "bnext"))
      assert_true(str.endswith(actual[3], '"next buffer"'))
    end)
  end)

  describe("[context]", function()
    it("_vim_commands_context_maker", function()
      local ctx = vim_commands_cfg._vim_commands_context_maker()
      -- print(string.format("vim commands context:%s\n", vim.inspect(ctx)))
      assert_true(ctx.bufnr > 0)
      assert_true(ctx.winnr > 0)
      assert_true(ctx.tabnr > 0)
      assert_true(ctx.name_width > 0)
      assert_true(ctx.opts_width >= string.len("Bang|Bar|Nargs|Range|Complete"))
    end)
    it("_get_vim_commands", function()
      local actual = vim_commands_cfg._get_vim_commands({
        ex_commands = true,
        user_commands = true,
      })
      -- print(string.format("vim commands:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      assert_true(#actual >= 0)
      for i, act in ipairs(actual) do
        -- print(
        --     string.format("vim command[%d]:%s\n", i, vim.inspect(act))
        -- )
        assert_eq(type(act), "table")
        assert_eq(type(act.name), "string")
        assert_true(string.len(act.name) > 0)
        assert_true(vim.fn.exists(":" .. act.name) >= 0)
        if str.isalpha(act.name:sub(1, 1)) and act.name ~= "range" then
          assert_true(vim.fn.exists(":" .. act.name) > 0)
        end
      end
    end)
  end)
end)
