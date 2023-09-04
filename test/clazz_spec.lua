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

            local clz = Clazz:implement()
            assert_true(type(clz) == "table")
            assert_true(clz.__classname == "object")
            local obj = vim.tbl_deep_extend("force", vim.deepcopy(clz), {})
            assert_true(type(obj) == "table")
            assert_true(Clazz:instanceof(obj, clz))
            assert_true(obj.__classname == "object")
        end)
    end)
end)
