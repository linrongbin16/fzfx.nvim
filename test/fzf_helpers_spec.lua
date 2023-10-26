local cwd = vim.fn.getcwd()

describe("helpers", function()
    local assert_eq = assert.is_equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
        vim.opt.swapfile = false
    end)

    local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum
    local fzf_helpers = require("fzfx.fzf_helpers")

    require("fzfx.config").setup()
    require("fzfx.log").setup({
        level = "INFO",
        console_log = false,
        file_log = false,
    })
    describe("[get_command_feed]", function()
        it("get normal args feed", function()
            local expect = "expect"
            local actual = fzf_helpers.get_command_feed(
                { args = expect },
                CommandFeedEnum.ARGS
            )
            assert_eq(expect, actual)
        end)
        it("get visual select feed", function()
            local expect = ""
            local actual =
                fzf_helpers.get_command_feed({}, CommandFeedEnum.VISUAL)
            assert_eq(expect, actual)
        end)
        it("get cword feed", function()
            local actual =
                fzf_helpers.get_command_feed({}, CommandFeedEnum.CWORD)
            assert_eq(type(actual), "string")
        end)
    end)
    describe("[_get_visual_lines]", function()
        it("is v mode", function()
            vim.cmd([[
            edit README.md
            call feedkeys('V', 'n')
            ]])
            -- vim.fn.feedkeys("V", "n")
            local actual = fzf_helpers._get_visual_lines("V")
            print(
                string.format("get visual lines(V):%s\n", vim.inspect(actual))
            )
            assert_eq(type(actual), "string")
        end)
        it("is V mode", function()
            vim.cmd([[
            edit README.md
            call feedkeys('v', 'n')
            call feedkeys('l', 'x')
            call feedkeys('l', 'x')
            ]])
            -- vim.fn.feedkeys("vll", "n")
            local actual = fzf_helpers._get_visual_lines("v")
            print(
                string.format("get visual lines(v):%s\n", vim.inspect(actual))
            )
            assert_eq(type(actual), "string")
        end)
    end)
    describe("[nvim_exec]", function()
        it("get nvim path", function()
            local actual = fzf_helpers.nvim_exec()
            print(string.format("nvim_exec: %s\n", vim.inspect(actual)))
            assert_true(type(actual) == "string")
            assert_true(string.len(actual --[[@as string]]) > 0)
            assert_true(vim.fn.executable(actual) > 0)
        end)
    end)
    describe("[fzf_exec]", function()
        it("get fzf path", function()
            local ok, err = pcall(fzf_helpers.fzf_exec)
            print(
                string.format(
                    "fzf_exec: %s, %s\n",
                    vim.inspect(ok),
                    vim.inspect(err)
                )
            )
            assert_true(ok ~= nil)
        end)
    end)
    describe("[preprocess_fzf_opts]", function()
        it("preprocess nil opts", function()
            local actual = fzf_helpers.preprocess_fzf_opts({
                "--bind=enter:accept",
                function()
                    return nil
                end,
            })
            print(
                string.format("preprocess nil opts: %s\n", vim.inspect(actual))
            )
            assert_true(type(actual) == "table")
            assert_false(vim.tbl_isempty(actual))
            assert_eq(#actual, 1)
        end)
        it("preprocess string opts", function()
            local actual = fzf_helpers.preprocess_fzf_opts({
                "--bind=enter:accept",
                function()
                    return "--no-multi"
                end,
            })
            print(
                string.format(
                    "preprocess string opts: %s\n",
                    vim.inspect(actual)
                )
            )
            assert_true(type(actual) == "table")
            assert_false(vim.tbl_isempty(actual))
            assert_eq(#actual, 2)
        end)
    end)
    describe("[make_fzf_opts]", function()
        it("make opts", function()
            local expect = "--bind=enter:accept"
            local actual = fzf_helpers.make_fzf_opts({ expect })
            print(string.format("make opts: %s\n", vim.inspect(actual)))
            assert_eq(type(actual), "string")
            assert_true(string.len(actual --[[@as string]]) > 0)
            assert_eq(actual, expect)
        end)
    end)
    describe("[make_fzf_default_opts]", function()
        it("make default opts", function()
            local actual = fzf_helpers.make_fzf_default_opts()
            print(string.format("make default opts: %s\n", vim.inspect(actual)))
            assert_eq(type(actual), "string")
            assert_true(string.len(actual --[[@as string]]) > 0)
        end)
    end)
    describe("[make_lua_command]", function()
        it("make lua command", function()
            local actual =
                fzf_helpers.make_lua_command("general", "provider.lua")
            print(string.format("make lua command: %s\n", vim.inspect(actual)))
            assert_eq(type(actual), "string")
            assert_true(string.len(actual --[[@as string]]) > 0)
            assert_true(actual:gmatch("general") ~= nil)
            assert_true(actual:gmatch("provider") ~= nil)
        end)
    end)
end)
