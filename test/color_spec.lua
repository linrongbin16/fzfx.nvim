local cwd = vim.fn.getcwd()

describe("color_spec", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    local hlgroups = {
        "Special",
        "Normal",
        "LineNr",
        "TabLine",
        "Exception",
        "Comment",
        "Label",
        "String",
    }

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    describe("color", function()
        it("retrieve fg colors", function()
            local color = require("fzfx.color")
            for _, group in ipairs(hlgroups) do
                local actual = color.retrieve_vim_color("fg", group)
                print(
                    string.format(
                        "retrieve vim fg color from hlgroup (%s): %s",
                        group,
                        vim.inspect(actual)
                    )
                )
                assert_true(type(actual) == "string" or actual == nil)
                if type(actual) == "string" then
                    assert_true(tonumber(actual) >= 0)
                end
            end
        end)
        it("retrieve bg colors", function()
            local color = require("fzfx.color")
            for _, group in ipairs(hlgroups) do
                local actual = color.retrieve_vim_color("bg", group)
                print(
                    string.format(
                        "retrieve vim bg color from hlgroup (%s): %s",
                        group,
                        vim.inspect(actual)
                    )
                )
                assert_true(type(actual) == "string" or actual == nil)
                if type(actual) == "string" then
                    assert_true(tonumber(actual) >= 0)
                end
            end
        end)
    end)
end)
