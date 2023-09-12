local cwd = vim.fn.getcwd()

describe("helpers", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local CommandFeedEnum = require("fzfx.schema").CommandFeedEnum
    local helpers = require("fzfx.helpers")

    require("fzfx.config").setup()
    require("fzfx.log").setup({
        level = "INFO",
        console_log = false,
        file_log = false,
    })
    describe("[get_command_feed]", function()
        it("get normal args feed", function()
            local expect = "expect"
            local actual = helpers.get_command_feed(
                { args = expect },
                CommandFeedEnum.ARGS
            )
            assert_eq(expect, actual)
        end)
        it("get visual select feed", function()
            local expect = ""
            local actual = helpers.get_command_feed({}, CommandFeedEnum.VISUAL)
            assert_eq(expect, actual)
        end)
        it("get cword feed", function()
            local expect = ""
            local actual = helpers.get_command_feed({}, CommandFeedEnum.CWORD)
            assert_eq(expect, actual)
        end)
    end)
    describe("[nvim_exec]", function()
        it("get nvim path", function()
            local actual = helpers.nvim_exec()
            print(string.format("nvim_exec: %s\n", vim.inspect(actual)))
            assert_true(type(actual) == "string")
            assert_true(string.len(actual --[[@as string]]) > 0)
            assert_true(vim.fn.executable(actual) > 0)
        end)
    end)
    describe("[preprocess_fzf_opts]", function()
        it("preprocess nil opts", function()
            local actual = helpers.preprocess_fzf_opts({
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
            local actual = helpers.preprocess_fzf_opts({
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
end)
