local cwd = vim.fn.getcwd()

describe("config", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
        require("fzfx.config").setup()
    end)

    local conf = require("fzfx.config")
    local fzf_helpers = require("fzfx.fzf_helpers")
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
        it("file previewer", function()
            local f = conf._make_file_previewer("lua/fzfx/config.lua", 135)
            assert_eq(type(f), "function")
            local actual = f()
            print(string.format("file previewer:%s\n", vim.inspect(actual)))
            assert_true(actual[1] == "bat" or actual[1] == "cat")
        end)
    end)
end)
