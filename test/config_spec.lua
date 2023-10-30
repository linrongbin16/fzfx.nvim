local cwd = vim.fn.getcwd()

describe("config", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
        vim.fn["executable"] = function(v)
            return 1
        end
    end)

    vim.cmd([[!touch bat]])
    vim.cmd([[!chmod +x bat]])
    assert_true(vim.fn.executable("bat") > 0)
    vim.cmd([[!touch rg]])
    vim.cmd([[!chmod +x rg]])
    assert_true(vim.fn.executable("rg") > 0)
    vim.cmd([[!touch fd]])
    vim.cmd([[!chmod +x fd]])
    assert_true(vim.fn.executable("fd") > 0)
    local conf = require("fzfx.config")
    conf.setup()
    local fzf_helpers = require("fzfx.fzf_helpers")
    local utils = require("fzfx.utils")
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
        it("use bat", function()
            local f = conf._make_file_previewer("lua/fzfx/config.lua", 135)
            assert_eq(type(f), "function")
            local actual = f()
            print(string.format("file previewer:%s\n", vim.inspect(actual)))
            assert_eq(actual[1], "bat")
            assert_eq(actual[2], "--style=numbers,changes")
            assert_eq(actual[3], "--theme=base16")
            assert_eq(actual[4], "--color=always")
        end)
    end)
    describe("[_live_grep_provider]", function()
        it("restricted", function()
            local actual = conf._live_grep_provider("hello", {}, nil)
            print(string.format("live grep provider:%s\n", vim.inspect(actual)))
            assert_eq(type(actual), "table")
            assert_eq(actual[1], "rg")
            assert_eq(actual[2], "--column")
            assert_eq(actual[3], "-n")
            assert_eq(actual[4], "--no-heading")
            assert_eq(actual[5], "--color=always")
            assert_eq(actual[6], "-H")
            assert_eq(actual[7], "-S")
            assert_eq(actual[8], "hello")
        end)
        it("unrestricted", function()
            local actual = conf._live_grep_provider(
                "hello",
                {},
                { unrestricted = true }
            )
            print(string.format("live grep provider:%s\n", vim.inspect(actual)))
            assert_eq(type(actual), "table")
            assert_eq(actual[1], "rg")
            assert_eq(actual[2], "--column")
            assert_eq(actual[3], "-n")
            assert_eq(actual[4], "--no-heading")
            assert_eq(actual[5], "--color=always")
            assert_eq(actual[6], "-H")
            assert_eq(actual[7], "-S")
            assert_eq(actual[8], "-uu")
            assert_eq(actual[9], "hello")
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
    end)
end)
