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
end)
