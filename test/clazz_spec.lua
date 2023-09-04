local cwd = vim.fn.getcwd()

describe("clazz_spec", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    describe("Clazz", function()
        it("doesnt escape if not needed", function()
            local Clazz = require("fzfx.clazz").Clazz

            local cls = Clazz:implement()
            assert_true(type(cls) == "table")
        end)
    end)
end)
