local cwd = vim.fn.getcwd()

describe("utils", function()
    local assert_eq = assert.are.equal
    local assert_neq = assert.are_not.equal
    local assert_true = assert.is_true
    local assert_false = assert.is_false
    local assert_truthy = assert.is.truthy
    local assert_falsy = assert.is.falsy

    before_each(function()
        vim.api.nvim_command("cd " .. cwd)
    end)

    local utils = require("fzfx.utils")
    describe("[tbl_empty]", function()
        it("is true", function()
            assert_true(utils.tbl_empty())
            assert_true(utils.tbl_empty(nil))
            assert_true(utils.tbl_empty({}))
        end)
        it("is false", function()
            assert_false(utils.tbl_empty({ abc = 1, def = 2, ghi = 3 }))
            assert_false(utils.tbl_empty({ 1, 2, 3 }))
        end)
    end)
    describe("[tbl_filter]", function()
        it("filtered by positive number", function()
            local t = { a = 1, b = 2, c = 3, d = 4, e = -1, f = -2, g = 0 }
            local actual = utils.tbl_filter(t, function(k, v)
                return v > 0
            end)
            assert_eq(type(actual), "table")
            for k, v in pairs(actual) do
                assert_true(v > 0)
            end
        end)
        it("filtered by negative number", function()
            local t = { a = 1, b = 2, c = 3, d = 4, e = -1, f = -2, g = 0 }
            local actual = utils.tbl_filter(t, function(k, v)
                return v < 0
            end)
            assert_eq(type(actual), "table")
            for k, v in pairs(actual) do
                assert_true(v < 0)
            end
        end)
        it("filtered by key is a/b/c", function()
            local t = { a = 1, b = 2, c = 3, d = 4, e = -1, f = -2, g = 0 }
            local actual = utils.tbl_filter(t, function(k, v)
                return k == "a" or k == "b" or k == "c"
            end)
            assert_eq(type(actual), "table")
            for k, v in pairs(actual) do
                assert_true(k == "a" or k == "b" or k == "c")
            end
        end)
        it("filtered on list", function()
            local t = { -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6 }
            local actual = utils.tbl_filter(t, function(k, v)
                return v > 0
            end)
            assert_eq(type(actual), "table")
            for _, v in ipairs(actual) do
                assert_true(v > 0)
            end
        end)
    end)
    describe("[list_empty]", function()
        it("is true", function()
            assert_true(utils.list_empty())
            assert_true(utils.list_empty(nil))
            assert_true(utils.list_empty({}))
            assert_true(utils.list_empty({ a = 1, b = 2 }))
        end)
        it("is false", function()
            assert_false(utils.tbl_empty({ 1, 2, 3 }))
        end)
    end)
    describe("[list_filter]", function()
        it("filtered by positive number", function()
            local t = { 1, 2, 3, 4, -1, -2, 0 }
            local actual = utils.list_filter(t, function(i, v)
                return v > 0
            end)
            assert_eq(type(actual), "table")
            for k, v in pairs(actual) do
                assert_true(v > 0)
            end
        end)
        it("filtered by negative number", function()
            local t = { 1, 2, 3, 4, -1, -2, 0 }
            local actual = utils.list_filter(t, function(i, v)
                return v < 0
            end)
            assert_eq(type(actual), "table")
            for k, v in pairs(actual) do
                assert_true(v < 0)
            end
        end)
        it("filtered by index is 1/2/3", function()
            local t = { 1, 2, 3, 4, -1, -2, 0 }
            local actual = utils.list_filter(t, function(i, v)
                return i == "a" or i == "b" or i == "c"
            end)
            assert_eq(type(actual), "table")
            for k, v in pairs(actual) do
                assert_true(k == "a" or k == "b" or k == "c")
            end
        end)
        it("filter on table", function()
            local t = {
                a = -5,
                b = -4,
                c = -3,
                d = -2,
                e = -1,
                f = 0,
                g = 1,
                h = 2,
                i = 3,
                j = 4,
                k = 5,
                l = 6,
            }
            local actual = utils.list_filter(t, function(i, v)
                return v > 0
            end)
            print(string.format("filtered list:%s\n", vim.inspect(actual)))
            assert_eq(type(actual), "table")
            assert_true(utils.list_empty(actual))
        end)
    end)
end)
