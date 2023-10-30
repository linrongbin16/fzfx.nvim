local cwd = vim.fn.getcwd()

describe("config", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

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
            assert_false(vim.tbl_isempty(conf.get_config()))
            assert_eq(type(conf.get_config().live_grep), "table")
            assert_eq(type(conf.get_config().debug), "table")
            assert_eq(type(conf.get_config().debug.enable), "boolean")
            assert_false(conf.get_config().debug.enable)
            assert_eq(type(conf.get_config().popup), "table")
            assert_eq(type(conf.get_config().icons), "table")
            assert_eq(type(conf.get_config().fzf_opts), "table")
            local actual = fzf_helpers.make_fzf_opts(conf.get_config().fzf_opts)
            print(
                string.format(
                    "make fzf opts with default configs:%s\n",
                    vim.inspect(actual)
                )
            )
            assert_eq(type(actual), "string")
            assert_true(string.len(actual --[[@as string]]) > 0)
        end)
    end)
    describe("[get_defaults]", function()
        it("get defaults", function()
            assert_eq(type(conf.get_defaults()), "table")
            assert_false(vim.tbl_isempty(conf.get_defaults()))
            assert_eq(type(conf.get_defaults().live_grep), "table")
            assert_eq(type(conf.get_defaults().debug), "table")
            assert_eq(type(conf.get_defaults().debug.enable), "boolean")
            assert_false(conf.get_defaults().debug.enable)
            assert_eq(type(conf.get_defaults().popup), "table")
            assert_eq(type(conf.get_defaults().icons), "table")
            assert_eq(type(conf.get_defaults().fzf_opts), "table")
            local actual =
                fzf_helpers.make_fzf_opts(conf.get_defaults().fzf_opts)
            print(
                string.format(
                    "make fzf opts with default configs:%s\n",
                    vim.inspect(actual)
                )
            )
            assert_eq(type(actual), "string")
            assert_true(string.len(actual --[[@as string]]) > 0)
        end)
    end)
    describe("[_default_bat_style_theme]", function()
        it("defaults", function()
            vim.env.BAT_STYLE = nil
            vim.env.BAT_THEME = nil
            local style, theme = conf._default_bat_style_theme()
            assert_eq(style, "numbers,changes")
            assert_eq(theme, "base16")
        end)
        it("overwrites", function()
            vim.env.BAT_STYLE = "numbers,changes,headers"
            vim.env.BAT_THEME = "zenburn"
            local style, theme = conf._default_bat_style_theme()
            assert_eq(style, vim.env.BAT_STYLE)
            assert_eq(theme, vim.env.BAT_THEME)
            vim.env.BAT_STYLE = nil
            vim.env.BAT_THEME = nil
        end)
    end)
    describe("[_make_file_previewer]", function()
        it("preview", function()
            local f = conf._make_file_previewer("lua/fzfx/config.lua", 135)
            assert_eq(type(f), "function")
            local actual = f()
            print(string.format("file previewer:%s\n", vim.inspect(actual)))
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
    end)
    describe("[_live_grep_provider]", function()
        it("restricted", function()
            local actual = conf._live_grep_provider("hello", {}, nil)
            print(string.format("live grep provider:%s\n", vim.inspect(actual)))
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
                    "--exclude-dir="
                        .. (constants.has_gnu_grep and [[.*]] or [[./.*]])
                )
                assert_eq(
                    actual[7],
                    "--exclude="
                        .. (constants.has_gnu_grep and [[.*]] or [[./.*]])
                )
                assert_eq(actual[8], "hello")
            end
        end)
        it("unrestricted", function()
            local actual = conf._live_grep_provider(
                "hello",
                {},
                { unrestricted = true }
            )
            print(string.format("live grep provider:%s\n", vim.inspect(actual)))
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
        it("buffer", function()
            vim.cmd([[edit README.md]])
            local actual = conf._live_grep_provider("hello", {
                bufnr = vim.api.nvim_get_current_buf(),
                winnr = vim.api.nvim_get_current_win(),
                tabnr = vim.api.nvim_get_current_tabpage(),
            }, { buffer = true })
            print(string.format("live grep provider:%s\n", vim.inspect(actual)))
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
    describe("[_parse_vim_ex_command_name]", function()
        it("parse", function()
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
    end)
    describe("[_get_vim_ex_commands]", function()
        it("get ex commands", function()
            local actual = conf._get_vim_ex_commands()
            assert_eq(type(actual["next"]), "table")
            print(
                string.format(
                    "ex command 'next':%s\n",
                    vim.inspect(actual["next"])
                )
            )
            assert_eq(actual["next"].name, "next")
            assert_true(
                vim.fn.filereadable(vim.fn.expand(actual["next"].loc.filename))
                    > 0
            )
            assert_true(tonumber(actual["next"].loc.lineno) > 0)
            assert_eq(type(actual["bnext"]), "table")
            print(
                string.format(
                    "ex command 'bnext':%s\n",
                    vim.inspect(actual["bnext"])
                )
            )
            assert_eq(actual["bnext"].name, "bnext")
            assert_true(
                vim.fn.filereadable(vim.fn.expand(actual["bnext"].loc.filename))
                    > 0
            )
            assert_true(tonumber(actual["bnext"].loc.lineno) > 0)
        end)
        it("is ex command output header", function()
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
            assert_eq(
                actual3.definition_pos,
                utils.string_find(line, "Definition")
            )
        end)
        it("_parse_ex_command_output_lua_function_definition", function()
            local header =
                "Name              Args Address Complete    Definition"
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
                    conf._parse_ex_command_output_lua_function_definition(
                        line,
                        def_pos
                    )
                print(
                    string.format(
                        "parse ex command lua function:%s\n",
                        vim.inspect(actual)
                    )
                )
                assert_eq(type(actual), "table")
                assert_true(string.len(actual.filename) > 0)
                assert_true(string.len(vim.fn.expand(actual.filename)) > 0)
                assert_true(tonumber(actual.lineno) > 0)
            end
            for _, line in ipairs(failed_lines) do
                local actual =
                    conf._parse_ex_command_output_lua_function_definition(
                        line,
                        def_pos
                    )
                print(
                    string.format(
                        "failed to parse ex command lua function:%s\n",
                        vim.inspect(actual)
                    )
                )
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
    end)
    describe("[_get_vim_user_commands]", function()
        it("get user commands", function()
            local user_commands = vim.api.nvim_get_commands({ builtin = false })
            print(
                string.format("user commands:%s\n", vim.inspect(user_commands))
            )
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
            print(
                string.format(
                    "render vim command opts1:%s\n",
                    vim.inspect(actual1)
                )
            )
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
            print(
                string.format(
                    "render vim command opts2:%s\n",
                    vim.inspect(actual2)
                )
            )
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
            print(
                string.format(
                    "render vim command status:%s, %s\n",
                    vim.inspect(actual1),
                    vim.inspect(actual2)
                )
            )
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
            local actual =
                conf._render_vim_commands(commands, name_width, opts_width)
            print(
                string.format("render vim commands:%s\n", vim.inspect(actual))
            )
            assert_eq(type(actual), "table")
            assert_eq(#actual, 3)
            assert_true(utils.string_startswith(actual[1], "Name"))
            assert_true(utils.string_endswith(actual[1], "Desc/Location"))
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
            vim.cmd([[edit README.md]])
            local actual = conf._vim_commands_lua_function_previewer(
                "lua/fzfx/config.lua",
                13
            )
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
            print(string.format("vim commands context:%s\n", vim.inspect(ctx)))
            assert_true(ctx.bufnr > 0)
            assert_true(ctx.winnr > 0)
            assert_true(ctx.tabnr > 0)
            assert_true(ctx.name_width > 0)
            assert_true(
                ctx.opts_width >= string.len("Bang|Bar|Nargs|Range|Complete")
            )
        end)
        it("_get_vim_commands", function()
            local actual = conf._get_vim_commands()
            print(string.format("vim commands:%s\n", vim.inspect(actual)))
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
                if
                    utils.string_isalpha(act.name:sub(1, 1))
                    and act.name ~= "range"
                then
                    assert_true(vim.fn.exists(":" .. act.name) > 0)
                end
            end
        end)
    end)
    describe("[_is_lsp_xxx]", function()
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
    end)
    describe("[_lsp_location_render_line]", function()
        local RANGE = {
            start = { line = 1, character = 20 },
            ["end"] = { line = 1, character = 26 },
        }
        it("render", function()
            local loc = conf._lsp_location_render_line(
                'describe("_lsp_location_render_line", function()',
                RANGE,
                require("fzfx.color").red
            )
            print(string.format("lsp render line:%s\n", vim.inspect(loc)))
            assert_eq(type(loc), "string")
            assert_true(utils.string_startswith(loc, "describe"))
            assert_true(utils.string_endswith(loc, "function()"))
        end)
    end)
    describe("_render_lsp_location_line", function()
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
        it("renders location", function()
            local actual = conf._render_lsp_location_line(LOCATION)
            print(
                string.format("render lsp location:%s\n", vim.inspect(actual))
            )
            assert_true(actual == nil or type(actual) == "string")
        end)
        it("renders locationlink", function()
            local actual = conf._render_lsp_location_line(LOCATIONLINK)
            print(
                string.format(
                    "render lsp locationlink:%s\n",
                    vim.inspect(actual)
                )
            )
            assert_true(actual == nil or type(actual) == "string")
        end)
    end)
    describe("[_lsp_position_context_maker]", function()
        it("lsp position context", function()
            vim.cmd([[edit README.md]])
            local ctx = conf._lsp_position_context_maker()
            print(string.format("lsp position context:%s\n", vim.inspect(ctx)))
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
                utils.string_endswith(
                    ctx.position_params.textDocument.uri,
                    "README.md"
                )
            )
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
                print(
                    string.format(
                        "parse map command[%d]:%s\n",
                        i,
                        vim.inspect(actual)
                    )
                )
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
    describe("[_get_vim_keymaps]", function()
        it("get keymaps", function()
            local actual = conf._get_vim_keymaps()
            print(string.format("vim keymaps:%s\n", vim.inspect(actual)))
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
            print(
                string.format(
                    "render vim keymap opts1:%s\n",
                    vim.inspect(actual1)
                )
            )
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
            local actual1, actual2 =
                conf._render_vim_keymaps_columns_status(keymaps)
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
            local actual =
                conf._render_vim_keymaps(keymaps, lhs_width, opts_width)
            print(string.format("render vim keymaps:%s\n", vim.inspect(actual)))
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
            print(string.format("vim keymaps context:%s\n", vim.inspect(ctx)))
            assert_eq(type(ctx), "table")
            assert_true(ctx.bufnr > 0)
            assert_true(ctx.winnr > 0)
            assert_true(ctx.tabnr > 0)
            assert_true(ctx.key_width > 0)
            assert_true(ctx.opts_width > 0)
        end)
        it("_vim_keymaps_lua_function_previewer", function()
            local actual = conf._vim_keymaps_lua_function_previewer(
                "lua/fzfx/config.lua",
                13
            )
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
    end)
end)
