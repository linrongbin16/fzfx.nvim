---@diagnostic disable: undefined-field, unused-local
local cwd = vim.fn.getcwd()

describe("config", function()
  local assert_eq = assert.is_equal
  local assert_true = assert.is_true
  local assert_false = assert.is_false

  before_each(function()
    vim.api.nvim_command("cd " .. cwd)
    vim.env._FZFX_NVIM_DEVICONS_PATH = nil
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
  local constants = require("fzfx.constants")
  local conf = require("fzfx.config")
  conf.setup()
  local fzf_helpers = require("fzfx.fzf_helpers")
  local utils = require("fzfx.utils")
  local path = require("fzfx.path")
  describe("[setup]", function()
    it("setup with default configs", function()
      conf.setup()
      assert_eq(type(conf.get_config()), "table")
      assert_false(tbls.tbl_empty(conf.get_config()))
      assert_eq(type(conf.get_config().live_grep), "table")
      assert_eq(type(conf.get_config().debug), "table")
      assert_eq(type(conf.get_config().debug.enable), "boolean")
      assert_false(conf.get_config().debug.enable)
      assert_eq(type(conf.get_config().popup), "table")
      assert_eq(type(conf.get_config().icons), "table")
      assert_eq(type(conf.get_config().fzf_opts), "table")
      local actual = fzf_helpers.make_fzf_opts(conf.get_config().fzf_opts)
      -- print(
      --     string.format(
      --         "make fzf opts with default configs:%s\n",
      --         vim.inspect(actual)
      --     )
      -- )
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
    end)
  end)
  describe("[get_defaults]", function()
    it("get defaults", function()
      assert_eq(type(conf.get_defaults()), "table")
      assert_false(tbls.tbl_empty(conf.get_defaults()))
      assert_eq(type(conf.get_defaults().live_grep), "table")
      assert_eq(type(conf.get_defaults().debug), "table")
      assert_eq(type(conf.get_defaults().debug.enable), "boolean")
      assert_false(conf.get_defaults().debug.enable)
      assert_eq(type(conf.get_defaults().popup), "table")
      assert_eq(type(conf.get_defaults().icons), "table")
      assert_eq(type(conf.get_defaults().fzf_opts), "table")
      local actual = fzf_helpers.make_fzf_opts(conf.get_defaults().fzf_opts)
      -- print(
      --     string.format(
      --         "make fzf opts with default configs:%s\n",
      --         vim.inspect(actual)
      --     )
      -- )
      assert_eq(type(actual), "string")
      assert_true(string.len(actual --[[@as string]]) > 0)
    end)
  end)
  describe("[files]", function()
    it("_default_bat_style_theme default", function()
      vim.env.BAT_STYLE = nil
      vim.env.BAT_THEME = nil
      local style, theme = conf._default_bat_style_theme()
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
          assert_eq(actual[7], path.normalize(line, { expand = true }))
        else
          assert_eq(actual[1], "cat")
          assert_eq(actual[2], path.normalize(line, { expand = true }))
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
        assert_eq(actual[1], constants.grep)
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "-H")
        assert_eq(actual[5], "-r")
        assert_eq(
          actual[6],
          "--exclude-dir=" .. (constants.has_gnu_grep and [[.*]] or [[./.*]])
        )
        assert_eq(
          actual[7],
          "--exclude=" .. (constants.has_gnu_grep and [[.*]] or [[./.*]])
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
          path.normalize(utils.string_split(line, ":")[1], { expand = true })
        print(string.format("normalize:%s\n", vim.inspect(expect)))
        print(string.format("file previewer grep:%s\n", vim.inspect(actual)))
        if actual[1] == "bat" then
          assert_eq(actual[1], "bat")
          assert_eq(actual[2], "--style=numbers,changes")
          assert_eq(actual[3], "--theme=base16")
          assert_eq(actual[4], "--color=always")
          assert_eq(actual[5], "--pager=never")
          assert_true(utils.string_startswith(actual[6], "--highlight-line"))
          assert_eq(actual[7], "--")
          assert_true(utils.string_startswith(actual[8], expect))
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
        assert_eq(actual[1], constants.grep)
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
        assert_eq(actual[1], constants.grep)
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-n")
        assert_eq(actual[4], "-H")
        assert_eq(actual[5], "-r")
        assert_eq(actual[6], "hello")
        assert_eq(actual[7], "README.md")
      end
    end)
  end)
  describe("buffers", function()
    it("_is_valid_buffer_number", function()
      assert_eq(type(conf._is_valid_buffer_number(0)), "boolean")
      assert_eq(type(conf._is_valid_buffer_number(1)), "boolean")
      assert_eq(type(conf._is_valid_buffer_number(2)), "boolean")
    end)
    it("_buffers_provider", function()
      local actual = conf._buffers_provider("", make_default_context())
      assert_eq(type(actual), "table")
      assert_true(#actual >= 0)
    end)
    it("_delete_buffer", function()
      conf._delete_buffer("README.md")
      assert_true(true)
    end)
  end)
  describe("git_files", function()
    it("_make_git_files_provider repo", function()
      local f = conf._make_git_files_provider()
      local actual = f()
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(vim.deep_equal(actual, { "git", "ls-files", ":/" }))
      end
    end)
    it("_make_git_files_provider current folder", function()
      local f = conf._make_git_files_provider({ current_folder = true })
      local actual = f()
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(vim.deep_equal(actual, { "git", "ls-files" }))
      end
    end)
  end)
  describe("git_live_grep", function()
    it("_git_live_grep_provider", function()
      local actual = conf._git_live_grep_provider("", {})
      print(string.format("git live grep:%s\n", vim.inspect(actual)))
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_eq(actual[1], "git")
        assert_eq(actual[2], "grep")
      end
    end)
    it("_git_live_grep_provider with -- flag", function()
      local actual = conf._git_live_grep_provider("fzfx -- -v", {})
      print(string.format("git live grep:%s\n", vim.inspect(actual)))
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_eq(actual[1], "git")
        assert_eq(actual[2], "grep")
      end
    end)
  end)
  describe("git_branches", function()
    it("_make_git_branches_provider local", function()
      local f = conf._make_git_branches_provider()
      local actual = f()
      assert_true(actual == nil or type(actual) == "table")
    end)
    it("_make_git_branches_provider remotes", function()
      local f = conf._make_git_branches_provider({ remote_branch = true })
      local actual = f()
      assert_true(actual == nil or type(actual) == "table")
    end)
    it("_git_branches_previewer", function()
      local lines = {
        "main",
        "my-plugin-dev",
        "remotes/origin/HEAD -> origin/main",
        "remotes/origin/main",
        "remotes/origin/my-plugin-dev",
        "remotes/origin/ci-fix-create-tags",
        "remotes/origin/ci-verbose",
      }
      for i, line in ipairs(lines) do
        local actual = conf._git_branches_previewer(line)
        assert_true(utils.string_find(actual, "git log --pretty") == 1)
      end
    end)
  end)
  describe("[git_commits]", function()
    it("_make_git_commits_previewer", function()
      local lines = {
        "44ee80e",
        "706e1d6",
      }
      for _, line in ipairs(lines) do
        local actual = conf._make_git_commits_previewer(line)
        if actual ~= nil then
          assert_eq(type(actual), "string")
          assert_true(utils.string_find(actual, "git show") > 0)
          if vim.fn.executable("delta") > 0 then
            assert_true(utils.string_find(actual, "delta") > 0)
          else
            assert_true(utils.string_find(actual, "delta") == nil)
          end
        end
      end
    end)
    it("_git_commits_previewer", function()
      local lines = {
        "44ee80e 2023-10-11 linrongbin16 (HEAD -> origin/feat_git_status) docs: wording",
        "706e1d6 2023-10-10 linrongbin16 chore",
        "                                | 1:2| fzfx.nvim",
      }
      for _, line in ipairs(lines) do
        local actual = conf._git_commits_previewer(line)
        if actual ~= nil then
          assert_eq(type(actual), "string")
          assert_true(utils.string_find(actual, "git show") > 0)
          if vim.fn.executable("delta") > 0 then
            assert_true(utils.string_find(actual, "delta") > 0)
          else
            assert_true(utils.string_find(actual, "delta") == nil)
          end
        end
      end
    end)
    it("_make_git_commits_provider repo", function()
      local f = conf._make_git_commits_provider()
      local actual = f("", {})
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_eq(actual[1], "git")
        assert_eq(actual[2], "log")
        assert_true(utils.string_startswith(actual[3], "--pretty="))
        assert_eq(actual[4], "--date=short")
        assert_eq(actual[5], "--color=always")
      end
    end)
    it("_make_git_commits_provider buffer", function()
      local f = conf._make_git_commits_provider({ buffer = true })
      local actual = f("", make_default_context())
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_eq(actual[1], "git")
        assert_eq(actual[2], "log")
        assert_true(utils.string_startswith(actual[3], "--pretty="))
        assert_eq(actual[4], "--date=short")
        assert_eq(actual[5], "--color=always")
        assert_eq(actual[6], "--")
        assert_true(utils.string_endswith(actual[7], "README.md"))
      end
    end)
  end)
  describe("git_blame", function()
    it("_git_blame_provider", function()
      local actual = conf._git_blame_provider("", make_default_context())
      if actual ~= nil then
        assert_eq(type(actual), "string")
        assert_true(utils.string_find(actual, "git blame") == 1)
        if constants.has_delta then
          assert_true(
            utils.string_find(actual, "delta -n --tabs 4 --blame-format")
              > string.len("git blame")
          )
        else
          assert_true(
            utils.string_find(actual, "git blame --date=short --color-lines")
              == 1
          )
        end
      end
    end)
  end)
  describe("[git_status]", function()
    it("_get_delta_width", function()
      local actual = conf._get_delta_width()
      assert_eq(type(actual), "number")
      assert_true(actual >= 3)
    end)
    it("_git_status_previewer", function()
      local lines = {
        " M fzfx/config.lua",
        " D fzfx/constants.lua",
        " M fzfx/line_helpers.lua",
        " M ../test/line_helpers_spec.lua",
        "?? ../hello",
      }
      for _, line in ipairs(lines) do
        local actual = conf._git_status_previewer(line)
        assert_eq(type(actual), "string")
        assert_true(utils.string_find(actual, "git diff") > 0)
        if vim.fn.executable("delta") > 0 then
          assert_true(utils.string_find(actual, "delta") > 0)
        else
          assert_true(utils.string_find(actual, "delta") == nil)
        end
      end
    end)
    it("_make_git_status_provider", function()
      local actual1 = conf._make_git_status_provider({})()
      local actual2 =
        conf._make_git_status_provider({ current_folder = true })()
      -- print(
      --     string.format("git status provider1:%s\n", vim.inspect(actual1))
      -- )
      -- print(
      --     string.format("git status provider2:%s\n", vim.inspect(actual2))
      -- )
      assert_true(actual1 == nil or vim.deep_equal(actual1, {
        "git",
        "-c",
        "color.status=always",
        "status",
        "--short",
      }))
      assert_true(actual2 == nil or vim.deep_equal(actual2, {
        "git",
        "-c",
        "color.status=always",
        "status",
        "--short",
        ".",
      }))
    end)
  end)
  describe("[commands]", function()
    it("_parse_vim_ex_command_name", function()
      local lines = {
        "|:|",
        "|:next|",
        "|:FzfxGBranches|",
      }
      for _, line in ipairs(lines) do
        local actual = conf._parse_vim_ex_command_name(line)
        local expect = vim.trim(line:sub(3, #line - 1))
        assert_eq(actual, expect)
      end
    end)
    it("_get_vim_ex_commands", function()
      local actual = conf._get_vim_ex_commands()
      assert_eq(type(actual["next"]), "table")
      -- print(
      --     string.format(
      --         "ex command 'next':%s\n",
      --         vim.inspect(actual["next"])
      --     )
      -- )
      assert_eq(actual["next"].name, "next")
      assert_true(
        vim.fn.filereadable(vim.fn.expand(actual["next"].loc.filename)) > 0
      )
      assert_true(tonumber(actual["next"].loc.lineno) > 0)
      assert_eq(type(actual["bnext"]), "table")
      -- print(
      --     string.format(
      --         "ex command 'bnext':%s\n",
      --         vim.inspect(actual["bnext"])
      --     )
      -- )
      assert_eq(actual["bnext"].name, "bnext")
      assert_true(
        vim.fn.filereadable(vim.fn.expand(actual["bnext"].loc.filename)) > 0
      )
      assert_true(tonumber(actual["bnext"].loc.lineno) > 0)
    end)
    it(
      "_is_ex_command_output_header/_parse_ex_command_output_header",
      function()
        local line = "Name              Args Address Complete    Definition"
        local actual1 = conf._is_ex_command_output_header("asdf")
        local actual2 = conf._is_ex_command_output_header(line)
        assert_false(actual1)
        assert_true(actual2)
        local actual3 = conf._parse_ex_command_output_header(line)
        assert_eq(type(actual3), "table")
        assert_eq(actual3.name_pos, 1)
        assert_eq(actual3.args_pos, utils.string_find(line, "Args"))
        assert_eq(actual3.address_pos, utils.string_find(line, "Address"))
        assert_eq(actual3.complete_pos, utils.string_find(line, "Complete"))
        assert_eq(actual3.definition_pos, utils.string_find(line, "Definition"))
      end
    )
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
      local def_pos = utils.string_find(header, "Definition")
      for _, line in ipairs(success_lines) do
        local actual =
          conf._parse_ex_command_output_lua_function_definition(line, def_pos)
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
          conf._parse_ex_command_output_lua_function_definition(line, def_pos)
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
      local actual = conf._parse_ex_command_output()
      for k, v in pairs(actual) do
        assert_true(vim.fn.exists(":" .. k) > 0)
        assert_eq(type(v.filename), "string")
        assert_true(string.len(v.filename) > 0)
        assert_eq(type(v.lineno), "number")
        assert_true(v.lineno > 0)
      end
    end)
    it("_get_vim_user_commands", function()
      local user_commands = vim.api.nvim_get_commands({ builtin = false })
      -- print(
      --     string.format("user commands:%s\n", vim.inspect(user_commands))
      -- )
      local actual = conf._get_vim_user_commands()
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
      local actual1 = conf._render_vim_commands_column_opts({
        opts = { bang = true, bar = true },
      })
      -- print(
      --     string.format(
      --         "render vim command opts1:%s\n",
      --         vim.inspect(actual1)
      --     )
      -- )
      assert_eq(actual1, "Y   |Y  |N/A  |N/A  |N/A")
      local actual2 = conf._render_vim_commands_column_opts({
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
    it("_render_vim_commands_columns_status", function()
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
      local actual1, actual2 =
        conf._render_vim_commands_columns_status(commands)
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
        conf._render_vim_commands_columns_status(commands)
      local actual = conf._render_vim_commands(commands, name_width, opts_width)
      -- print(
      --     string.format("render vim commands:%s\n", vim.inspect(actual))
      -- )
      assert_eq(type(actual), "table")
      assert_eq(#actual, 3)
      assert_true(utils.string_startswith(actual[1], "Name"))
      assert_true(utils.string_endswith(actual[1], "Definition/Location"))
      assert_true(utils.string_startswith(actual[2], "FzfxGBranches"))
      local expect = string.format(
        "%s:%d",
        path.reduce(commands[1].loc.filename),
        commands[1].loc.lineno
      )
      assert_true(utils.string_endswith(actual[2], expect))
      assert_true(utils.string_startswith(actual[3], "bnext"))
      assert_true(utils.string_endswith(actual[3], '"next buffer"'))
    end)
    it("_vim_commands_lua_function_previewer", function()
      local actual =
        conf._vim_commands_lua_function_previewer("lua/fzfx/config.lua", 13)
      assert_eq(type(actual), "table")
      if actual[1] == "bat" then
        assert_eq(actual[1], "bat")
        assert_eq(actual[2], "--style=numbers,changes")
        assert_eq(actual[3], "--theme=base16")
        assert_eq(actual[4], "--color=always")
        assert_eq(actual[5], "--pager=never")
        assert_eq(actual[6], "--highlight-line=13")
        assert_eq(actual[7], "--line-range")
        assert_true(utils.string_endswith(actual[8], ":"))
        assert_eq(actual[9], "--")
        assert_eq(actual[10], "lua/fzfx/config.lua")
      else
        assert_eq(actual[1], "cat")
        assert_eq(actual[2], "lua/fzfx/config.lua")
      end
    end)
    it("_vim_commands_context_maker", function()
      local ctx = conf._vim_commands_context_maker()
      -- print(string.format("vim commands context:%s\n", vim.inspect(ctx)))
      assert_true(ctx.bufnr > 0)
      assert_true(ctx.winnr > 0)
      assert_true(ctx.tabnr > 0)
      assert_true(ctx.name_width > 0)
      assert_true(ctx.opts_width >= string.len("Bang|Bar|Nargs|Range|Complete"))
    end)
    it("_get_vim_commands", function()
      local actual = conf._get_vim_commands()
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
        if utils.string_isalpha(act.name:sub(1, 1)) and act.name ~= "range" then
          assert_true(vim.fn.exists(":" .. act.name) > 0)
        end
      end
    end)
  end)
  describe("lsp_diagnostics", function()
    it("_make_lsp_diagnostic_signs", function()
      local actual = conf._make_lsp_diagnostic_signs()
      assert_eq(type(actual), "table")
      assert_eq(#actual, 4)
      for i, sign_item in ipairs(actual) do
        assert_eq(type(sign_item), "table")
        assert_true(sign_item.severity >= 1 and sign_item.severity <= 4)
        assert_true(
          string.len(sign_item.name) > 0
            and utils.string_startswith(sign_item.name, "DiagnosticSign")
        )
        assert_true(
          utils.string_endswith(sign_item.name, "Error")
            or utils.string_endswith(sign_item.name, "Warn")
            or utils.string_endswith(sign_item.name, "Info")
            or utils.string_endswith(sign_item.name, "Hint")
        )
      end
    end)
    it("_process_lsp_diagnostic_item", function()
      local diags = {
        { bufnr = 0, lnum = 1, col = 1, message = "a", severity = 1 },
        { bufnr = 1, lnum = 1, col = 1, message = "b", severity = 2 },
        { bufnr = 2, lnum = 1, col = 1, message = "c", severity = 3 },
        { bufnr = 3, lnum = 1, col = 1, message = "d", severity = 4 },
        { bufnr = 5, lnum = 1, col = 1, message = "e" },
      }
      for _, diag in ipairs(diags) do
        local actual = conf._process_lsp_diagnostic_item(diag)
        if actual ~= nil then
          assert_eq(actual.bufnr, diag.bufnr)
          assert_eq(actual.lnum, diag.lnum + 1)
          assert_eq(actual.col, diag.col + 1)
          assert_eq(actual.severity, diag.severity or 1)
        end
      end
    end)
    it("_make_lsp_diagnostics_provider", function()
      local f = conf._make_lsp_diagnostics_provider()
      local actual = f("", {})
      if actual ~= nil then
        assert_eq(type(actual), "table")
        assert_true(#actual >= 0)
        for _, act in ipairs(actual) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) >= 0)
        end
      end
    end)
  end)
  describe("lsp_locations", function()
    local RANGE = {
      start = { line = 1, character = 10 },
      ["end"] = { line = 10, character = 31 },
    }
    local LOCATION = {
      uri = "file:///usr/home/github/linrongbin16/fzfx.nvim",
      range = RANGE,
    }
    local LOCATIONLINK = {
      targetUri = "file:///usr/home/github/linrongbin16/fzfx.nvim",
      targetRange = RANGE,
    }
    it("_is_lsp_range", function()
      assert_false(conf._is_lsp_range(nil))
      assert_false(conf._is_lsp_range({}))
      assert_true(conf._is_lsp_range(RANGE))
    end)
    it("_is_lsp_location", function()
      assert_false(conf._is_lsp_location("asdf"))
      assert_false(conf._is_lsp_location({}))
      assert_true(conf._is_lsp_location(LOCATION))
    end)
    it("_is_lsp_locationlink", function()
      assert_false(conf._is_lsp_locationlink("hello"))
      assert_false(conf._is_lsp_locationlink({}))
      assert_true(conf._is_lsp_locationlink(LOCATIONLINK))
    end)
    it("_lsp_location_render_line", function()
      local r = {
        start = { line = 1, character = 20 },
        ["end"] = { line = 1, character = 26 },
      }
      local loc = conf._lsp_location_render_line(
        'describe("_lsp_location_render_line", function()',
        r,
        require("fzfx.color").red
      )
      -- print(string.format("lsp render line:%s\n", vim.inspect(loc)))
      assert_eq(type(loc), "string")
      assert_true(utils.string_startswith(loc, "describe"))
      assert_true(utils.string_endswith(loc, "function()"))
    end)
    it("renders location", function()
      local actual = conf._render_lsp_location_line(LOCATION)
      -- print(
      --     string.format("render lsp location:%s\n", vim.inspect(actual))
      -- )
      assert_true(actual == nil or type(actual) == "string")
    end)
    it("renders locationlink", function()
      local actual = conf._render_lsp_location_line(LOCATIONLINK)
      -- print(
      --     string.format(
      --         "render lsp locationlink:%s\n",
      --         vim.inspect(actual)
      --     )
      -- )
      assert_true(actual == nil or type(actual) == "string")
    end)
    it("_lsp_position_context_maker", function()
      local ctx = conf._lsp_position_context_maker()
      -- print(string.format("lsp position context:%s\n", vim.inspect(ctx)))
      assert_true(ctx.bufnr > 0)
      assert_true(ctx.winnr > 0)
      assert_true(ctx.tabnr > 0)
      assert_eq(type(ctx.position_params), "table")
      assert_eq(type(ctx.position_params.context), "table")
      assert_eq(type(ctx.position_params.position), "table")
      assert_true(ctx.position_params.position.character >= 0)
      assert_true(ctx.position_params.position.line >= 0)
      assert_eq(type(ctx.position_params.textDocument), "table")
      assert_eq(type(ctx.position_params.textDocument.uri), "string")
      assert_true(
        utils.string_endswith(ctx.position_params.textDocument.uri, "README.md")
      )
    end)
    it("_make_lsp_locations_provider", function()
      local ctx = conf._lsp_position_context_maker()
      local f = conf._make_lsp_locations_provider({
        method = "textDocument/definition",
        capability = "definitionProvider",
      })
      assert_eq(type(f), "function")
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
  end)
  describe("[_parse_map_command_output_line]", function()
    it("parse", function()
      local lines = {
        "n  K           *@<Cmd>lua vim.lsp.buf.hover()<CR>",
        "                Show hover",
        "                Last set from Lua",
        "n  [w          *@<Lua 1213: ~/.config/nvim/lua/builtin/lsp.lua:60>",
        "                Previous diagnostic warning",
        "                Last set from Lua",
        "n  [e          *@<Lua 1211: ~/.config/nvim/lua/builtin/lsp.lua:60>",
        "                 Previous diagnostic error",
        "                 Last set from Lua",
        "n  [d          *@<Lua 1209: ~/.config/nvim/lua/builtin/lsp.lua:60>",
        "                 Previous diagnostic item",
        "                 Last set from Lua",
        "x  ca         *@<Cmd>lua vim.lsp.buf.range_code_action()<CR>",
        "                 Code actions",
        "n  <CR>        *@<Lua 961: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>",
        "                 Last set from Lua",
        "n  <Esc>       *@<Lua 998: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>",
        "                 Last set from Lua",
        "n  .           *@<Lua 977: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>",
        "                 Last set from Lua",
        "n  <           *@<Lua 987: ~/.config/nvim/lazy/neo-tree.nvim/lua/neo-tree/ui/renderer.lua:843>",
        "                 Last set from Lua",
        "v  <BS>        * d",
        "                 Last set from /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/mswin.vim line 24",
        "x  <Plug>NetrwBrowseXVis * :<C-U>call netrw#BrowseXVis()<CR>",
        "                 Last set from /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/plugin/netrwPlugin.vim line 90",
        "n  <Plug>NetrwBrowseX * :call netrw#BrowseX(netrw#GX(),netrw#CheckIfRemote(netrw#GX()))<CR>",
        "                 Last set from /opt/homebrew/Cellar/neovim/0.9.4/share/nvim/runtime/plugin/netrwPlugin.vim line 84",
        "n  <C-L>       * :nohlsearch<C-R>=has('diff')?'|diffupdate':''<CR><CR><C-L>",
        "                 Last set from ~/.config/nvim/lua/builtin/options.vim line 50",
      }
      for i, line in ipairs(lines) do
        local actual = conf._parse_map_command_output_line(line)
        -- print(
        --     string.format(
        --         "parse map command[%d]:%s\n",
        --         i,
        --         vim.inspect(actual)
        --     )
        -- )
        if not utils.string_isspace(line:sub(1, 1)) then
          assert_true(string.len(actual.lhs) > 0)
          assert_true(utils.string_find(line, actual.lhs) > 2)
          if utils.string_find(line, "<Lua ") ~= nil then
            assert_true(string.len(actual.filename) > 0)
            assert_eq(type(actual.lineno), "number")
          end
        end
      end
    end)
  end)
  describe("[keymaps]", function()
    it("_make_vim_keymaps_provider all", function()
      local ctx = conf._vim_keymaps_context_maker()
      local f = conf._make_vim_keymaps_provider("all")
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
    it("_make_vim_keymaps_provider n", function()
      local ctx = conf._vim_keymaps_context_maker()
      local f = conf._make_vim_keymaps_provider("n")
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
    it("_make_vim_keymaps_provider i", function()
      local ctx = conf._vim_keymaps_context_maker()
      local f = conf._make_vim_keymaps_provider("i")
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
    it("_make_vim_keymaps_provider v", function()
      local ctx = conf._vim_keymaps_context_maker()
      local f = conf._make_vim_keymaps_provider("v")
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
      local actual = conf._get_vim_keymaps()
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
    it("_render_vim_keymaps_column_opts", function()
      local actual1 = conf._render_vim_keymaps_column_opts({
        lhs = "#",
        mode = "n",
        noremap = true,
        nowait = false,
        silent = false,
      })
      -- print(
      --     string.format(
      --         "render vim keymap opts1:%s\n",
      --         vim.inspect(actual1)
      --     )
      -- )
      assert_eq(actual1, "n   |Y      |N     |N     ")
    end)
    it("_render_vim_keymaps_columns_status", function()
      local keymaps = {
        {
          lhs = "#",
          mode = "n",
          noremap = true,
          nowait = false,
          silent = false,
        },
      }
      local actual1, actual2 = conf._render_vim_keymaps_columns_status(keymaps)
      assert_eq(
        actual1,
        math.max(string.len(keymaps[1].lhs), string.len("Lhs"))
      )
      assert_eq(actual2, string.len("Mode|Noremap|Nowait|Silent"))
    end)
    it("_render_vim_keymaps", function()
      local keymaps = conf._get_vim_keymaps()
      local lhs_width, opts_width =
        conf._render_vim_keymaps_columns_status(keymaps)
      local actual = conf._render_vim_keymaps(keymaps, lhs_width, opts_width)
      -- print(string.format("render vim keymaps:%s\n", vim.inspect(actual)))
      assert_eq(type(actual), "table")
      assert_true(#actual >= 1)
      assert_true(utils.string_startswith(actual[1], "Key"))
      assert_true(utils.string_endswith(actual[1], "Definition/Location"))
      for i = 2, #actual do
        assert_true(string.len(actual[i]) > 0)
      end
    end)
    it("_vim_keymaps_context_maker", function()
      local ctx = conf._vim_keymaps_context_maker()
      -- print(string.format("vim keymaps context:%s\n", vim.inspect(ctx)))
      assert_eq(type(ctx), "table")
      assert_true(ctx.bufnr > 0)
      assert_true(ctx.winnr > 0)
      assert_true(ctx.tabnr > 0)
      assert_true(ctx.key_width > 0)
      assert_true(ctx.opts_width > 0)
    end)
    it("_vim_keymaps_lua_function_previewer", function()
      local actual =
        conf._vim_keymaps_lua_function_previewer("lua/fzfx/config.lua", 13)
      assert_eq(type(actual), "table")
      if actual[1] == "bat" then
        assert_eq(actual[1], "bat")
        assert_eq(actual[2], "--style=numbers,changes")
        assert_eq(actual[3], "--theme=base16")
        assert_eq(actual[4], "--color=always")
        assert_eq(actual[5], "--pager=never")
        assert_eq(actual[6], "--highlight-line=13")
        assert_eq(actual[7], "--line-range")
        assert_true(utils.string_endswith(actual[8], ":"))
        assert_eq(actual[9], "--")
        assert_eq(actual[10], "lua/fzfx/config.lua")
      else
        assert_eq(actual[1], "cat")
        assert_eq(actual[2], "lua/fzfx/config.lua")
      end
    end)
    it("_vim_keymaps_previewer", function()
      local lines = {
        '<C-Tab>                                      o   |Y      |N     |N      "<C-C><C-W>w"',
        "<Plug>(YankyCycleBackward)                   n   |Y      |N     |Y      ~/.config/nvim/lazy/yanky.nvim/lua/yanky.lua:290",
      }
      local ctx = conf._vim_keymaps_context_maker()
      for _, line in ipairs(lines) do
        local actual = conf._vim_keymaps_previewer(line, ctx)
        assert_eq(type(actual), "table")
        assert_true(
          actual[1] == "bat" or actual[1] == "cat" or actual[1] == "echo"
        )
      end
    end)
  end)
  describe("[file explorer]", function()
    local LS_LINES = {
      "-rw-r--r--   1 rlin  staff   1.0K Aug 28 12:39 LICENSE",
      "-rw-r--r--   1 rlin  staff    27K Oct  8 11:37 README.md",
      "drwxr-xr-x   4 rlin  staff   128B Sep 22 10:11 bin",
      "-rw-r--r--   1 rlin  staff   120B Sep  5 14:14 codecov.yml",
    }
    local LSD_LINES = {
      "drwxr-xr-x  rlin staff 160 B  Wed Oct 25 16:59:44 2023 bin",
      ".rw-r--r--  rlin staff  54 KB Tue Oct 31 22:29:35 2023 CHANGELOG.md",
      ".rw-r--r--  rlin staff 120 B  Tue Oct 10 14:47:43 2023 codecov.yml",
      ".rw-r--r--  rlin staff 1.0 KB Mon Aug 28 12:39:24 2023 LICENSE",
      "drwxr-xr-x  rlin staff 128 B  Tue Oct 31 21:55:28 2023 lua",
      ".rw-r--r--  rlin staff  38 KB Wed Nov  1 10:29:19 2023 README.md",
      "drwxr-xr-x  rlin staff 992 B  Wed Nov  1 11:16:13 2023 test",
    }
    local EZA_LINES = {
      "drwxr-xr-x     - linrongbin 22 Sep 10:11  bin",
      ".rw-r--r--   120 linrongbin  5 Sep 14:14  codecov.yml",
      ".rw-r--r--  1.1k linrongbin 28 Aug 12:39  LICENSE",
      "drwxr-xr-x     - linrongbin  8 Oct 09:14  lua",
      ".rw-r--r--   28k linrongbin  8 Oct 11:37  README.md",
      "drwxr-xr-x     - linrongbin  8 Oct 11:44  test",
    }
    it("_file_explorer_context_maker", function()
      local ctx = conf._file_explorer_context_maker()
      -- print(string.format("file explorer context:%s\n", vim.inspect(ctx)))
      assert_eq(type(ctx), "table")
      assert_true(ctx.bufnr > 0)
      assert_true(ctx.winnr > 0)
      assert_true(ctx.tabnr > 0)
      assert_true(vim.fn.filereadable(ctx.cwd) > 0)
    end)
    it("_make_file_explorer_provider", function()
      local ctx = conf._file_explorer_context_maker()
      local f1 = conf._make_file_explorer_provider("-lh")
      assert_eq(type(f1), "function")
      local actual1 = f1("", ctx)
      -- print(
      --     string.format(
      --         "file explorer provider1:%s\n",
      --         vim.inspect(actual1)
      --     )
      -- )
      assert_eq(type(actual1), "string")
      assert_true(utils.string_find(actual1, "echo") > 0)
      assert_true(
        type(utils.string_find(actual1, "eza")) == "number"
          or type(utils.string_find(actual1, "ls")) == "number"
      )
      assert_true(
        utils.string_find(
          actual1,
          path.normalize(vim.fn.getcwd(), { expand = true })
        ) > 0
      )
      local f2 = conf._make_file_explorer_provider("-lha")
      assert_eq(type(f2), "function")
      local actual2 = f2("", ctx)
      -- print(
      --     string.format(
      --         "file explorer provider2:%s\n",
      --         vim.inspect(actual2)
      --     )
      -- )
      assert_eq(type(actual2), "string")
      assert_true(utils.string_find(actual2, "echo") > 0)
      assert_true(
        type(utils.string_find(actual2, "eza")) == "number"
          or type(utils.string_find(actual2, "ls")) == "number"
      )
      assert_true(
        utils.string_find(
          actual2,
          path.normalize(vim.fn.getcwd(), { expand = true })
        ) > 0
      )
    end)
    it("_directory_previewer", function()
      local actual = conf._directory_previewer("lua/fzfx/config.lua")
      assert_eq(type(actual), "table")
      if actual[1] == "lsd" then
        assert_eq(actual[1], "lsd")
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-lha")
        assert_eq(actual[4], "--header")
        assert_eq(actual[5], "--")
        assert_eq(actual[6], "lua/fzfx/config.lua")
      else
        assert_true(actual[1] == "eza" or actual[1] == "ls")
        assert_eq(actual[2], "--color=always")
        assert_eq(actual[3], "-lha")
        assert_eq(actual[4], "--")
        assert_eq(actual[5], "lua/fzfx/config.lua")
      end
    end)
    it("_make_filename_by_file_explorer_context", function()
      local ctx = conf._file_explorer_context_maker()
      if constants.has_lsd then
        for _, line in ipairs(LSD_LINES) do
          local actual = conf._make_filename_by_file_explorer_context(line, ctx)
          -- print(
          --     string.format("make filename:%s\n", vim.inspect(actual))
          -- )
          assert_eq(type(actual), "string")
          assert_true(
            vim.fn.filereadable(actual) > 0 or vim.fn.isdirectory(actual) > 0
          )
        end
      elseif constants.has_eza then
        for _, line in ipairs(EZA_LINES) do
          local actual = conf._make_filename_by_file_explorer_context(line, ctx)
          assert_eq(type(actual), "string")
          assert_true(
            vim.fn.filereadable(actual) > 0 or vim.fn.isdirectory(actual) > 0
          )
        end
      else
        for _, line in ipairs(LS_LINES) do
          local actual = conf._make_filename_by_file_explorer_context(line, ctx)
          print(
            string.format(
              "make filename from explorer context:%s\n",
              vim.inspect(actual)
            )
          )
          assert_eq(type(actual), "string")
          assert_true(
            vim.fn.filereadable(actual) > 0 or vim.fn.isdirectory(actual) > 0
          )
        end
      end
    end)
    it("_file_explorer_previewer", function()
      local ctx = conf._file_explorer_context_maker()
      if constants.has_lsd then
        for _, line in ipairs(LSD_LINES) do
          local actual = conf._file_explorer_previewer(line, ctx)
          if actual ~= nil then
            assert_eq(type(actual), "table")
            assert_true(
              actual[1] == "bat" or actual[1] == "cat" or actual[1] == "lsd"
            )
          end
        end
      elseif constants.has_eza then
        for _, line in ipairs(EZA_LINES) do
          local actual = conf._file_explorer_previewer(line, ctx)
          if actual ~= nil then
            assert_eq(type(actual), "table")
            assert_true(
              actual[1] == "bat"
                or actual[1] == "cat"
                or actual[1] == "eza"
                or actual[1] == "exa"
            )
          end
        end
      else
        for _, line in ipairs(LS_LINES) do
          local actual = conf._file_explorer_previewer(line, ctx)
          if actual ~= nil then
            assert_eq(type(actual), "table")
            assert_true(
              actual[1] == "bat" or actual[1] == "cat" or actual[1] == "ls"
            )
          end
        end
      end
    end)
    it("_edit_file_explorer", function()
      local ctx = conf._file_explorer_context_maker()
      if constants.has_lsd then
        local actual = conf._edit_file_explorer(LSD_LINES, ctx)
      elseif constants.has_eza then
        local actual = conf._edit_file_explorer(EZA_LINES, ctx)
      else
        local actual = conf._edit_file_explorer(LS_LINES, ctx)
      end
      assert_true(true)
    end)
    it("_cd_file_explorer", function()
      local ctx = conf._file_explorer_context_maker()
      if constants.has_lsd then
        for _, line in ipairs(LSD_LINES) do
          local actual = conf._cd_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      elseif constants.has_eza then
        for _, line in ipairs(EZA_LINES) do
          local actual = conf._cd_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      else
        for _, line in ipairs(LS_LINES) do
          local actual = conf._cd_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      end
    end)
    it("_upper_file_explorer", function()
      local ctx = conf._file_explorer_context_maker()
      if constants.has_lsd then
        for _, line in ipairs(LSD_LINES) do
          local actual = conf._upper_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      elseif constants.has_eza then
        for _, line in ipairs(EZA_LINES) do
          local actual = conf._upper_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      else
        for _, line in ipairs(LS_LINES) do
          local actual = conf._upper_file_explorer(line, ctx)
          assert_true(actual == nil)
        end
      end
    end)
  end)
  describe("[lsp_call_hierarchy]", function()
    local RANGE = {
      start = {
        character = 1,
        line = 299,
      },
      ["end"] = {
        character = 0,
        line = 289,
      },
    }
    local CALL_HIERARCHY_ITEM = {
      name = "name",
      kind = 2,
      detail = "detail",
      uri = "file:///usr/home/github/linrongbin16/fzfx.nvim/lua/fzfx/config.lua",
      range = RANGE,
      selectionRange = RANGE,
    }
    local INCOMING_CALLS = {
      from = CALL_HIERARCHY_ITEM,
      fromRanges = { RANGE },
    }
    local OUTGOING_CALLS = {
      to = CALL_HIERARCHY_ITEM,
      fromRanges = { RANGE },
    }
    it("_is_lsp_call_hierarchy_item", function()
      local actual1 = conf._is_lsp_call_hierarchy_item(nil)
      assert_false(actual1)
      local actual2 = conf._is_lsp_call_hierarchy_item({})
      assert_false(actual2)
      local actual3 = conf._is_lsp_call_hierarchy_item({
        name = "name",
        kind = 2,
        detail = "detail",
        uri = "uri",
        range = {
          start = 1,
          ["end"] = 2,
        },
        selectRange = {
          start = 1,
          ["end"] = 2,
        },
      })
      assert_false(actual3)
      local actual4 = conf._is_lsp_call_hierarchy_item(CALL_HIERARCHY_ITEM)
      assert_true(actual4)
    end)
    it("_is_lsp_call_hierarchy_incoming_call", function()
      local actual1 = conf._is_lsp_call_hierarchy_incoming_call(INCOMING_CALLS)
      assert_true(actual1)
    end)
    it("_is_lsp_call_hierarchy_outgoing_call", function()
      local actual1 = conf._is_lsp_call_hierarchy_outgoing_call(OUTGOING_CALLS)
      assert_true(actual1)
    end)
    it("_render_lsp_call_hierarchy_line", function()
      local actual1 = conf._render_lsp_call_hierarchy_line(
        INCOMING_CALLS.from,
        INCOMING_CALLS.fromRanges
      )
      print(string.format("incoming render lines:%s\n", vim.inspect(actual1)))
      assert_true(#actual1 >= 0)
      local actual2 = conf._render_lsp_call_hierarchy_line(
        OUTGOING_CALLS.to,
        OUTGOING_CALLS.fromRanges
      )
      print(string.format("outgoing render lines:%s\n", vim.inspect(actual2)))
      assert_true(#actual1 >= 0)
    end)
    it("_retrieve_lsp_call_hierarchy_item_and_from_ranges", function()
      local actual11, actual12 =
        conf._retrieve_lsp_call_hierarchy_item_and_from_ranges(
          "callHierarchy/incomingCalls",
          INCOMING_CALLS
        )
      assert_true(vim.deep_equal(actual11, INCOMING_CALLS.from))
      assert_true(vim.deep_equal(actual12, INCOMING_CALLS.fromRanges))
      local actual21, actual22 =
        conf._retrieve_lsp_call_hierarchy_item_and_from_ranges(
          "callHierarchy/incomingCalls",
          OUTGOING_CALLS
        )
      assert_eq(actual21, nil)
      assert_eq(actual22, nil)
      local actual31, actual32 =
        conf._retrieve_lsp_call_hierarchy_item_and_from_ranges(
          "callHierarchy/outgoingCalls",
          INCOMING_CALLS
        )
      assert_eq(actual31, nil)
      assert_eq(actual32, nil)
      local actual41, actual42 =
        conf._retrieve_lsp_call_hierarchy_item_and_from_ranges(
          "callHierarchy/outgoingCalls",
          OUTGOING_CALLS
        )
      assert_true(vim.deep_equal(actual41, OUTGOING_CALLS.to))
      assert_true(vim.deep_equal(actual42, OUTGOING_CALLS.fromRanges))
    end)
    it("_make_lsp_call_hierarchy_provider", function()
      local ctx = conf._lsp_position_context_maker()
      local f1 = conf._make_lsp_call_hierarchy_provider({
        method = "callHierarchy/incomingCalls",
        capability = "callHierarchyProvider",
      })
      assert_eq(type(f1), "function")
      local actual1 = f1("", ctx)
      if actual1 ~= nil then
        assert_eq(type(actual1), "table")
        assert_true(#actual1 >= 0)
        for _, act in ipairs(actual1) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) > 0)
        end
      end
      local f2 = conf._make_lsp_call_hierarchy_provider({
        method = "callHierarchy/outgoingCalls",
        capability = "callHierarchyProvider",
      })
      assert_eq(type(f2), "function")
      local actual2 = f2("", ctx)
      if actual2 ~= nil then
        assert_eq(type(actual2), "table")
        assert_true(#actual2 >= 0)
        for _, act in ipairs(actual2) do
          assert_eq(type(act), "string")
          assert_true(string.len(act) > 0)
        end
      end
    end)
  end)
end)
